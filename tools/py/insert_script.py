#!/usr/bin/env python3
"""Trinea English script inserter.
Reads script/en/*.json (message IDs + English "en" field; untranslated messages keep the original bytes read from your ROM),
encodes English as 1-byte ASCII (0x20-0x7F) + original control bytes, word-wraps to the text-box pixel width using
font/en/widths.bin, rebuilds every script block and writes build/gen/*.bin + build/gen/scripts.asm (asar include).
New layout (32 Mbit HiROM):  $E1:0000 = old $DB:8000 block ($0405==0), $E2:0000 = old $DB:0000 block ($0405==2),
$E3:0000 = 11-entry start table (was $C2:0000) followed by the C2 event scripts ($0405==other).
Usage: insert_script.py [--placeholder] [--jp-only]"""
import sys,os,re,json,struct,glob
sys.path.insert(0,os.path.dirname(__file__))
from walk import walk,R
from paths import ROOT,GEN,FONT
ARGS=set(sys.argv[1:])
W=open(FONT+'/widths.bin','rb').read()
BOX_W=192; BOX_LINES=3
CTRL={'wait':0x80,'81':0x81,'page':0x82,'br':0x83,'88':0x88,'hl':0x8A,'8E':0x8E,'END':0xFE,'ENDK':0xFF}
SUBST={'\u3000':' ','\u2026':'\x7f','…':'\x7f','“':'"','”':'"','‘':"'",'’':"'",'—':'-','–':'-','《':'"','》':'"','é':'e','×':'x','・':'.','！':'!','？':'?'}
stats=dict(en=0,jp=0,overflow=[],unknown_chars={})
def width(s): return sum(W[ord(c)-0x20] for c in s)
def tokenize(en):
    out=[]
    for t in re.split(r'(\[[^\]]*\])',en):
        if not t: continue
        m=re.fullmatch(r'\[([^\]]*)\]',t)
        if m and (m.group(1) in CTRL or re.fullmatch(r'[0-9A-Fa-f]{2}',m.group(1))):
            k=m.group(1); out.append(('c',CTRL[k] if k in CTRL else int(k,16)))
        else:
            for c in t:
                c=SUBST.get(c,c)
                if not (0x20<=ord(c)<=0x7f): stats['unknown_chars'][c]=stats['unknown_chars'].get(c,0)+1; c='?'
                out.append(('t',c))
    return out
def encode(en, mid='', box_w=BOX_W, lines=BOX_LINES, paging=True, start=None, want_state=False):
    """greedy word wrap. [br] = hard newline; [page] resets page; auto page break = 80 82 when > lines."""
    toks=tokenize(en)
    out=bytearray(); line=0; x=0
    if start: line,x=start          # box kept open by a preceding FF message: continue where it left off
    # group into words: runs of text chars w/o space, with embedded non-layout controls (hl/88)
    i=0; pending_space=bool(start and start[1]>0)
    def newline():
        nonlocal line,x
        line+=1; x=0
        if paging and line>=lines:
            out.extend(b'\x80\x82'); line=0
        else: out.append(0x83)
    while i<len(toks):
        k,v=toks[i]
        if k=='c':
            if v==0x83: newline(); pending_space=False
            elif v==0x82: out.append(v); line=0; x=0; pending_space=False
            else: out.append(v)
            i+=1; continue
        if v==' ':
            pending_space=True; i+=1; continue
        j=i; word=[]
        while j<len(toks) and not (toks[j][0]=='t' and toks[j][1]==' ') and not (toks[j][0]=='c' and toks[j][1] in (0x80,0x82,0x83,0xFE,0xFF)):
            word.append(toks[j]); j+=1
        wtxt=''.join(v for k,v in word if k=='t'); ww=width(wtxt)
        sp=W[0] if (pending_space and x>0) else 0
        if x>0 and x+sp+ww>box_w:
            newline(); sp=0
        if sp: out.append(0x20); x+=sp
        if ww>box_w: stats['overflow'].append(mid)
        for k,v in word: out.append(ord(v) if k=='t' else v)
        x+=ww; pending_space=False; i=j
    if not out or out[-1] not in (0xFE,0xFF): stats['overflow'].append(mid+':noterm'); out.append(0xFE)
    return (bytes(out),(line,x)) if want_state else bytes(out)
def placeholder(m):
    raw=bytes.fromhex(m['raw']); n=m.get('chars',0)
    body='Test line for %s. The quick brown fox jumps over the lazy dog.'%m['id'] if n>12 else 'Test %s'%m['id'][-4:]
    tail='[ENDK]' if raw.endswith(b'\xff') else '[END]'
    pre='[page]' if raw.startswith(b'\x82') else ''
    return pre+body+('[wait]' if b'\x80' in raw else '')+tail
def load(name):
    en={}
    p=f'{ROOT}/script/en/{name}.json'
    if os.path.exists(p) and '--jp-only' not in ARGS:
        try:
            for m in json.load(open(p,encoding='utf-8'))['messages']: en[m['id']]=m.get('en')
        except Exception as e: print('WARN cannot read',p,e)
    ov=os.environ.get('TRINEA_OVERRIDE')   # debug/showcase builds only: {id: en} json
    if ov:
        for k,v in json.load(open(ov)).items():
            if k in en or k.startswith(name): en[k]=v
    return en
CARRY=[None]
# ops seen between an FF-terminated message and the next message that do not touch the text box
# (handler = table $C0:0DF4[op-1]): 1b sound, 27 item effect, 43 counter, 2c/07 flags, 0f sfx.
# Everything else (labels/jumps 06, map change 10 -> $C0:468E -> $0700 screen init, fades 1d...) resets.
BENIGN={0x1b,0x27,0x43,0x2c,0x07,0x0f}
def text_bytes(mid,raw,kind,en):
    e=en.get(mid)
    if not e and '--placeholder' in ARGS and kind=='dialogue':
        e=placeholder(dict(id=mid,raw=raw.hex(),chars=len(raw)//2))
    if e:
        stats['en']+=1
        if kind!='dialogue': CARRY[0]=None; return encode(e,mid)
        b,st=encode(e,mid,start=CARRY[0],want_state=True)
        if CARRY[0] and CARRY[0]!=(0,0): stats['carried']=stats.get('carried',0)+1; stats.setdefault('carried_ids',[]).append((mid,CARRY[0]))
        CARRY[0]=st if b.endswith(b'\xff') else None
        return b
    CARRY[0]=None
    stats['jp']+=1; return raw
def rebuild(start,name,en):
    it,end=walk(start)
    out=bytearray(); k=0
    for x in it:
        typ=x[0]
        if typ=='label': out+=bytes([0,x[2]]); CARRY[0]=None; continue
        if typ in('op','list'):
            out+=x[2]
            if typ=='list' or x[2][0] not in BENIGN: CARRY[0]=None   # screen/map/flow ops reset the text box
            continue
        if typ=='msg':
            out+=R[x[1]:x[1]+1]; out+=text_bytes('%s_%04d'%(name,k),x[2],'dialogue',en); k+=1; continue
        if typ=='op05':
            out+=x[2]; CARRY[0]=None
            for m in x[3]: out+=text_bytes('%s_%04d'%(name,k),m[:-1],'choice',en)+m[-1:]; k+=1
            continue
        if typ=='op46':
            out+=x[2]; CARRY[0]=None
            for m in x[3]: out+=text_bytes('%s_%04d'%(name,k),m,'choice3',en); k+=1
            continue
        raise Exception((name,typ))
    return bytes(out),R[start:end]
# ---- C2 event scripts -> $E3
tab=[struct.unpack('<H',R[0x20000+2*i:0x20002+2*i])[0] for i in range(11)]
e3=bytearray(22); newtab=[0]*11; rep=[]
for i in (1,3,4,5,6,7,8,9,10):
    nm='C2_s%02d'%i; b,old=rebuild(0x20000+tab[i],nm,load(nm))
    newtab[i]=len(e3); e3+=b; rep.append((nm,len(old),len(b)))
newtab[0]=newtab[1]; newtab[2]=0   # entry 0 pointed mid-script (unused); entry 2 = table itself (as original)
e3[0:22]=struct.pack('<11H',*newtab)
assert len(e3)<=0x10000,'bank E3 overflow %d'%len(e3)
open(GEN+'/e3_c2scripts.bin','wb').write(e3)
b1,o1=rebuild(0x1B8000,'DB_8000',load('DB_8000')); rep.append(('DB_8000',len(o1),len(b1)))
b2,o2=rebuild(0x1B0000,'DB_0000',load('DB_0000')); rep.append(('DB_0000',len(o2),len(b2)))
assert len(b1)<=0x10000 and len(b2)<=0x10000
open(GEN+'/e1_db8000.bin','wb').write(b1); open(GEN+'/e2_db0000.bin','wb').write(b2)
# sanity: re-walk rebuilt blocks with the game's own length table rules
import walk as WK
for nm,blob,base in (('E3',e3,None),('E1',b1,0),('E2',b2,0)):
    WK.R=blob
    starts=[newtab[i] for i in (1,3,4,5,6,7,8,9,10)] if nm=='E3' else [0]
    for s in starts:
        it,end=WK.walk(s); assert not any(x[0]=='BAD' for x in it),(nm,s)
WK.R=R
OPEN_W=240
def center_lines(b,w):
    out=[]
    for ln in b.split(b'\x83'):
        lw=sum(W[c-0x20] for c in ln if 0x20<=c<0x80)
        out.append(b' '*max(0,(w-lw)//2//W[0])+ln)
    return b'\x83'.join(out)
# ---- opening block ($CA:2000 format 00 id param text FF) -> build/gen/open.bin (placed at $E4:0000, scanner patched)
en=load('OPEN'); p=0xA2000; ob=bytearray()
while R[p]==0:
    eid=R[p+1]; par=R[p+2]; e=R.index(b'\xff',p+3); raw=R[p+3:e+1]
    t=en.get('OPEN_%02d'%eid) if '--open-jp' not in ARGS else None
    if t:
        b=encode(t,'OPEN_%02d'%eid,box_w=OPEN_W,lines=9,paging=False)
        b=center_lines(b[:-1],256)+b'\xff'
        if b.count(0x83)>3: stats['overflow'].append('OPEN_%02d:>4 lines'%eid)
        stats['en']+=1
    else: b=raw; stats['jp']+=1
    ob+=bytes([0,eid,par])+b; p=e+1
ob+=R[p:p+1]  # terminator byte after last entry
open(GEN+'/open.bin','wb').write(ob)
rep.append(('OPEN',p-0xA2000,len(ob)))
# ---- character profiles (8x8 small font, 1 byte/char, 24 cols x 4 lines, FA=br FB=page FE=end) -> $E5:0000
SM=json.load(open(FONT+'/small_map.json'))['map']
def small_code(c):
    if c==' ': return 0x00
    if c.isdigit(): return 0x6F+int(c)
    if 'A'<=c<='Z': return 0x79+ord(c)-65
    if c=='?': return 0x96
    if c=='!': return 0x97
    if c in SM: return SM[c]
    stats['unknown_chars'][c]=stats['unknown_chars'].get(c,0)+1; return 0x96
def encode_profile(en,cols=24,lines=4):
    en=en.replace('\u3000',' ').replace('\u2026','...').replace('“','"').replace('”','"').replace('’',"'")
    out=bytearray(); line=0; col=0
    def nl(auto=False):
        nonlocal line,col
        line+=1
        if line>=lines: out.append(0xFB); line=0
        elif not auto: out.append(0xFA)
        col=0
    for part in re.split(r'(\[[^\]]*\])',en):
        if part in ('[br]',): nl(); continue
        if part=='[page]':
            if not (line==0 and col==0 and out and out[-1]==0xFB): out.append(0xFB)
            line=0; col=0; continue
        if part in ('[END]','[ENDK]'): continue
        if part.startswith('['): continue
        for i,w in enumerate(part.split(' ')):
            if i>0 and col>0:
                if col+1+len(w)>cols: nl(auto=(col==cols))
                else: out.append(0); col+=1
            elif col+len(w)>cols and col>0: nl(auto=(col==cols))
            while len(w)>cols: out+=bytes(small_code(c) for c in w[:cols]); w=w[cols:]; col=cols; nl(auto=True)
            out+=bytes(small_code(c) for c in w); col+=len(w)
            if col==cols: nl(auto=True)
    out.append(0xFE); return bytes(out)
en=load('PROFILE'); pb=bytearray(); pptr=[]
for i,nm in enumerate(['Hornisse','Sara','Tetsuya']):
    a=0x30000|struct.unpack('<H',R[0x5FCE+2*i:0x5FD0+2*i])[0]; raw=R[a:R.index(b'\xfe',a)+1]
    t=en.get('PROFILE_'+nm)
    pptr.append(len(pb)); pb+=encode_profile(t) if t else raw
open(GEN+'/profiles.bin','wb').write(pb)
rep.append(('PROFILE',0,len(pb)))
with open(GEN+'/scripts.asm','w') as f:
    f.write('org $E50000\nincbin "profiles.bin"\norg $C05FCE\ndw $%04X,$%04X,$%04X\norg $C05E97\nLDA.l $E50000,x\n'%tuple(pptr))
    f.write(';; generated by insert_script.py\norg $E10000\nincbin "e1_db8000.bin"\norg $E20000\nincbin "e2_db0000.bin"\norg $E30000\nincbin "e3_c2scripts.bin"\norg $E40000\nincbin "open.bin"\n')
for r in rep: print('%-8s old %6d new %6d'%r)
print('E3 total',len(e3),'bytes; strings en=%d jp-fallback=%d, box-state carried into %d messages'%(stats['en'],stats['jp'],stats.get('carried',0)))
if stats['overflow']: print('overflow/warn:',stats['overflow'][:20],len(stats['overflow']))
if stats['unknown_chars']: print('unknown chars:',stats['unknown_chars'])
