#!/usr/bin/env python3
"""Trinea JP script dumper -> build/jp/*.json + summary.
Blocks: bank $C2 event scripts (table $C2:0000), bank $DB scripts ($DB:0000, $DB:8000), opening/ending block ($CA:2000),
character profiles ($C3:5400, ptr table $C0:5FCE), system strings (LE words in bank $C0)."""
import sys,struct,json,re,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from paths import ROOT,JP
from walk import walk,R
OUT=JP; os.makedirs(OUT,exist_ok=True)
def load_tbl(path,width):
    t={}; c={}
    for l in open(path,encoding='utf-8'):
        l=l.rstrip('\n')
        m=re.match(r'^([0-9A-Fa-f]+)=(.*)$',l)
        if m:
            (t if len(m.group(1))==2*width else c)[int(m.group(1),16)]=m.group(2).replace('\\n','\n')
    return t,c
BIG,BIGC=load_tbl(ROOT+'/tables/trinea_big.tbl',2)
SMALL,_=load_tbl(ROOT+'/tables/trinea_small.tbl',1)
CTRL={0x80,0x82,0x83,0x88,0x8A,0xFE,0xFF}
def snes(p): return 0xC00000|p
def dec_big(b):
    s=''; p=0; n=0
    while p<len(b):
        c=b[p]
        if c in (0,1): w=c<<8|b[p+1]; s+=BIG.get(w,'{%04X}'%w); p+=2; n+=1
        else: s+=BIGC.get(c,'[%02X]'%c); p+=1
    return s,n
def dec_small(b):
    s=''; n=0
    for c in b:
        s+=SMALL.get(c,'{%02X}'%c)
        if c not in (0xFA,0xFB,0xFE): n+=1
    return s,n
def dec_le(b):
    s=''; n=0
    for i in range(0,len(b),2):
        w=b[i]|b[i+1]<<8
        if w<0x200: s+=BIG.get(w,'{%04X}'%w); n+=1
        else: s+='{%04X}'%w
    return s,n
blocks=[]
tab=[struct.unpack('<H',R[0x20000+2*i:0x20002+2*i])[0] for i in range(11)]
for i in (1,3,4,5,6,7,8,9,10):
    blocks.append(dict(name='C2_s%02d'%i,start=0x20000+tab[i],ptr_loc=0x20000+2*i,ptr_fmt='16-bit LE offset within bank $C2 (table $C2:0000, index=script id)'))
blocks.append(dict(name='DB_0000',start=0x1B0000,ptr_loc=None,ptr_fmt='fixed start $DB:0000 (bank chosen by $0405 in $C0:0CAC)'))
blocks.append(dict(name='DB_8000',start=0x1B8000,ptr_loc=None,ptr_fmt='fixed start $DB:8000'))
summary=[]; allmsgs=[]
NAMES={'Sara':['サラ'],'Hornisse':['ホルニッセ'],'Tetsuya':['哲也','椋','テツヤ']}
for bl in blocks:
    it,end=walk(bl['start'])
    msgs=[]; label=None; k=0
    for x in it:
        if x[0]=='label': label=x[2]; continue
        parts=[]
        if x[0]=='msg': parts=[(x[1]+1,x[2],None)]
        elif x[0] in('op05','op46'):
            q=x[1]+len(x[2])
            for m in x[3]:
                raw=m[:-1] if x[0]=='op05' else m
                parts.append((q,raw,m[-1] if x[0]=='op05' else None)); q+=len(m)
        for off,raw,jl in parts:
            text,n=dec_big(raw)
            e=dict(id='%s_%04d'%(bl['name'],k),block=bl['name'],kind={'msg':'dialogue','op05':'choice','op46':'choice3'}[x[0]],
                   label=label,opcode_offset='0x%06X'%x[1],rom_offset='0x%06X'%off,snes='$%06X'%snes(off),length=len(raw),
                   chars=n,raw=raw.hex(' '),text=text)
            if jl is not None: e['choice_jump_label']=jl
            msgs.append(e); k+=1
    blob=R[bl['start']:end]
    cnt={nm:sum(dec_big(bytes.fromhex(m['raw']))[0].count(a) for m in msgs for a in al) for nm,al in NAMES.items()}
    info=dict(block=bl['name'],start='0x%06X'%bl['start'],end='0x%06X'%end,size=end-bl['start'],ptr_loc=('0x%06X'%bl['ptr_loc']) if bl['ptr_loc'] else None,
              ptr_fmt=bl['ptr_fmt'],labels=sum(1 for x in it if x[0]=='label'),messages=len(msgs),jp_chars=sum(m['chars'] for m in msgs),
              text_bytes=sum(m['length'] for m in msgs),name_mentions=cnt)
    summary.append(info)
    json.dump(dict(info=info,messages=msgs),open(f'{OUT}/{bl["name"]}.json','w',encoding='utf-8'),ensure_ascii=False,indent=1)
    allmsgs+=msgs
# opening / ending block
p=0xA2000; msgs=[]
while R[p]==0:
    eid=R[p+1]; par=R[p+2]; e=R.index(b'\xff',p+3); raw=R[p+3:e+1]
    text,n=dec_big(raw)
    msgs.append(dict(id='OPEN_%02d'%eid,block='OPEN',kind='cutscene',entry_id=eid,param=par,rom_offset='0x%06X'%(p+3),snes='$%06X'%snes(p+3),
                     length=len(raw),chars=n,raw=raw.hex(' '),text=text,note='entry = 00 id param text... FF (83=newline). Located by linear scan ($CE:49A7), no pointers.'))
    p=e+1
info=dict(block='OPEN',start='0xA2000',end='0x%06X'%p,size=p-0xA2000,messages=len(msgs),jp_chars=sum(m['chars'] for m in msgs),
          text_bytes=sum(m['length'] for m in msgs),ptr_fmt='none (scan by entry id, $CE:49A7)')
summary.append(info); json.dump(dict(info=info,messages=msgs),open(f'{OUT}/OPEN.json','w',encoding='utf-8'),ensure_ascii=False,indent=1); allmsgs+=msgs
# profiles
ptrs=struct.unpack('<3H',R[0x5FCE:0x5FD4]); msgs=[]
for i,(nm,pp) in enumerate(zip(['Hornisse','Sara','Tetsuya'],ptrs)):
    a=0x30000|pp; e=R.index(b'\xfe',a); raw=R[a:e+1]; text,n=dec_small(raw)
    msgs.append(dict(id='PROFILE_%s'%nm,block='PROFILE',kind='profile',ptr_loc='0x%06X'%(0x5FCE+2*i),rom_offset='0x%06X'%a,snes='$%06X'%snes(a),
                     length=len(raw),chars=n,raw=raw.hex(' '),text=text,note='small 8x8 font, 1 byte/char, dakuten/handakuten as separate glyph preceding the kana; FA=br FB=page FE=end'))
info=dict(block='PROFILE',start='0x35400',end='0x%06X'%(0x30000|ptrs[2])+'+',messages=3,jp_chars=sum(m['chars'] for m in msgs),text_bytes=sum(m['length'] for m in msgs),ptr_fmt='3x16-bit LE at $C0:5FCE (bank $C3)')
summary.append(info); json.dump(dict(info=info,messages=msgs),open(f'{OUT}/PROFILE.json','w',encoding='utf-8'),ensure_ascii=False,indent=1); allmsgs+=msgs
# system strings (LE glyph words, fixed-length, referenced directly by code)
SYS=[(0x56C6,0x56C6+2*17,'charselect: 名前 キャラクターを選択して下さい'),(0x56E8,0x5712+2,'charselect names'),(0x75FC,0x75FC+4,'ptrs?'),(0x7600,0x76A6+2,'shop messages'),(0x76A8,0x76C2,'shop messages 2')]
msgs=[]
# segment shop region by FFFF and known phrase boundaries is left to insertion phase; dump raw regions
for a,b,nt in [(0x56C4,0x5714,'char select screen strings (LE words, FFFF-terminated list)'),(0x7600,0x76C4,'shop strings (LE words); boundaries fixed in code')]:
    raw=R[a:b]; text,n=dec_le(raw)
    msgs.append(dict(id='SYS_%04X'%a,block='SYSTEM',kind='system',rom_offset='0x%06X'%a,snes='$%06X'%snes(a),length=len(raw),chars=n,raw=raw.hex(' '),text=text,note=nt))
info=dict(block='SYSTEM',messages=len(msgs),jp_chars=sum(m['chars'] for m in msgs),ptr_fmt='hard-coded addresses/lengths in bank $C0 code (TBD)')
summary.append(info); json.dump(dict(info=info,messages=msgs),open(f'{OUT}/SYSTEM.json','w',encoding='utf-8'),ensure_ascii=False,indent=1); allmsgs+=msgs
json.dump(summary,open(f'{OUT}/_summary.json','w',encoding='utf-8'),ensure_ascii=False,indent=1)
# plain text view
with open(f'{OUT}/_all.txt','w',encoding='utf-8') as f:
    for m in allmsgs: f.write('### %s  %s  len=%d%s\n%s\n\n'%(m['id'],m['rom_offset'],m['length'],('  label=%s'%m['label']) if m.get('label') is not None else '',m['text']))
for s in summary: print({k:s.get(k) for k in ('block','start','end','size','messages','jp_chars','text_bytes','name_mentions')})
print('TOTAL messages',sum(s['messages'] for s in summary),'jp_chars',sum(s['jp_chars'] for s in summary))
