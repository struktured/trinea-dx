"""Select help overlay (DX): renders one 32x28-tile BG3 (2bpp) page per character from the profile 8x8 font
(caps/digits from your ROM at $C3:7000, lower case/punctuation from build/font/small_add.bin) plus a drawn SNES pad.
Output: build/gen/help_chr.bin (2bpp tiles, tile 0 blank), help_map.bin (3 x 896 tilemap words, order = $1430-1:
Hornisse, Sara, Ryo; $1430 = character select cursor + 1, see C0:5D94), help.asm (sizes). Text follows docs/MOVES.md. Colours (BG3 palette 0/1): 1 text, 2 shadow, 3 pad body."""
import os,sys,json
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from paths import ROOT,GEN,FONT
import numpy as np
from PIL import Image
R=open(os.environ['TRINEA_ROM'],'rb').read()
SM=json.load(open(FONT+'/small_map.json'))['map']; ADD=open(FONT+'/small_add.bin','rb').read(); FIRST=0x9E
def _g(rows): return np.array([[{'.':0,'#':1,'+':2}[ch] for ch in r] for r in rows],np.uint8)
# The 8x8 font's p/g/q/y have no room for descenders, so they sit on the baseline and read like capitals
# ("SPecial", "helP"). Overlay-only versions: the top lines up with the x-height of o/n/a (row 3), the bowl is
# 4 rows like the font's o, and the stem/tail drops one row below the baseline into row 0 of the tile below
# (every glyph leaves row 0 blank, so it can never collide; text() still checks).
DESC={'p':_g(['........','........','........','#####+..','##+.##+.','##+.##+.','#####+..','##+.....','##+.....']),
      'q':_g(['........','........','........','.#####+.','##+.##+.','##+.##+.','.#####+.','....##+.','....##+.']),
      'g':_g(['........','........','........','.#####+.','##+.##+.','##+.##+.','.#####+.','....##+.','.####+..']),
      'y':_g(['........','........','........','##+.##+.','##+.##+.','##+.##+.','.#####+.','....##+.','.####+..'])}
# '%' is not in the font: overlay-only, digit height (rows 1-7) with the font's 1-px right/bottom shadow style
# Overlay-only capitals (picked by struktured from docs/screenshots/sara_YA_grid.png): the ROM's A leans (only its
# left side steps out) and its Y reads like a lowercase y. A1: pointed apex, middle crossbar; Y4: blocky symmetric.
CAPS={'A':_g(['........','..###+..','.##+##+.','##+..##+','##+..##+','#######+','##+..##+','##+..##+']),
      'Y':_g(['........','##+.##+.','##+.##+.','.####+..','..##+...','..##+...','..##+...','..##+...'])}
EXTRA={'%':_g(['........','##+..##+','##+.##+.','...##+..','..##+...','.##+.##+','##+..##+','........'])}
def dec(b):
    t=np.zeros((8,8),np.uint8)
    for y in range(8):
        p0,p1=b[2*y],b[2*y+1]
        for x in range(8): t[y,x]=((p0>>(7-x))&1)|(((p1>>(7-x))&1)<<1)
    return t
def glyph(c):
    if c==' ': return np.zeros((8,8),np.uint8)
    if c in CAPS: return CAPS[c]
    if c.isdigit(): t=0x6F+int(c)
    elif 'A'<=c<='Z': t=0x79+ord(c)-65
    elif c=='?': t=0x96
    elif c=='!': t=0x97
    elif c in DESC: return DESC[c][:8]
    elif c in EXTRA: return EXTRA[c]
    elif c in SM: return dec(ADD[(SM[c]-FIRST)*16:(SM[c]-FIRST)*16+16])
    else: raise SystemExit('helpgfx: no glyph for %r'%c)
    return dec(R[0x37000+t*16:0x37000+t*16+16])
W,H=256,224
SELX,STAX=56,72   # pad-local centres of SELECT / START
def page(name,moves,btn,lr=False):
    img=np.zeros((H,W),np.uint8); pal=np.zeros((H//8,W//8),np.uint8)   # per-tile palette
    def text(col,row,s,p=0):
        for i,c in enumerate(s):
            img[row*8:row*8+8,(col+i)*8:(col+i)*8+8]=glyph(c); pal[row,col+i]=p
            if c in DESC: tails.append((row,col+i,c))
    tails=[]
    def put_tails():   # after all text: descenders go into the top rows of the tile below, onto blank pixels only
        for row,col,c in tails:
            t=DESC[c][8:]; y,x=row*8+8,col*8; cur=img[y:y+1,x:x+8]
            if (cur[t>0]).any(): raise SystemExit('helpgfx: descender of %r at %d,%d hits ink'%(c,col,row))
            if not img[y:y+8,x:x+8].any(): pal[row+1,col]=pal[row,col]
            elif pal[row+1,col]!=pal[row,col]: raise SystemExit('helpgfx: descender of %r at %d,%d changes palette'%(c,col,row))
            img[y:y+1,x:x+8]=np.where(t>0,t,cur)
    def ctext(row,s,p=0): text((32-len(s))//2,row,s,p)
    def rich(col,row,s,p=0):   # {...} = a button name, drawn gold (palette 1); everything else palette p (white)
        gold=False
        for c in s:
            if c=='{': gold=True; continue
            if c=='}': gold=False; continue
            text(col,row,c,1 if gold else p); col+=1
    ctext(1,'CONTROLS - '+name,1)
    # --- SNES pad, tiles x 2..17, y 3..10 (128 x 64 px)
    ox,oy=8,24          # pad at x 8..135, y 24..87: a full tile (8 px+) of space before the labels at column 18
    pad=Image.new('P',(128,64),0); from PIL import ImageDraw; d=ImageDraw.Draw(pad)
    d.rounded_rectangle((10,0,42,10),radius=4,fill=2); d.rounded_rectangle((85,0,117,10),radius=4,fill=2)   # L, R
    d.rounded_rectangle((0,6,127,63),radius=26,fill=2); d.rounded_rectangle((2,8,125,61),radius=24,fill=3)   # body
    d.rectangle((24,22,33,49),fill=2); d.rectangle((15,31,42,40),fill=2)                                     # D-pad
    for cx in (SELX,STAX):   # SELECT, START: small capsules slanted up to the right, as on the real pad
        d.line([(cx-4,44),(cx+4,38)],fill=2,width=5); d.ellipse((cx-7,41,cx-2,46),fill=2); d.ellipse((cx+2,35,cx+7,40),fill=2)
    for cx,cy in ((104,22),(91,34),(117,34),(104,46)): d.ellipse((cx-7,cy-7,cx+7,cy+7),fill=2)            # X Y A B
    a=np.array(pad,np.uint8)
    def letter(ch,cx,cy):   # stroke only (white) centred on a button
        g=glyph(ch); y0,x0=cy-4,cx-3
        for y in range(8):
            for x in range(8):
                if g[y,x]==1 and 0<=y0+y<64 and 0<=x0+x<128: a[y0+y,x0+x]=1
    for ch,cx,cy in (('X',104,22),('Y',91,34),('A',117,34),('B',104,46),('L',26,4),('R',101,4)): letter(ch,cx,cy)
    img[oy:oy+64,ox:ox+128]=a
    # labels right of the pad (x tiles 18..31) at the button heights
    # Rows 4/6/8/10 (row 3 left blank): the row-2 hint/header used to sit directly on top of the X label at row 3.
    for r,b in ((4,'X'),(6,'A'),(8,'Y'),(10,'B')): rich(18,r,'{%s} %s'%(b,btn[b]),2 if lr else 0)
    # row 2 above the labels: the L+R hint
    rich(18,2,'{L+R}: DX opts')   # both views (the L+R view swaps rows 3..10 only; the cyan labels are the options)
    # SELECT and START: one row, labels mirrored about the pad centre (x 72); a white leader runs from each button
    # straight down out of the pad, then out to the first letter of its label (Select left, Start right).
    rich(1,12,'{SELECT}: help'); rich(16,12,'{START}: pause')   # drops at x 12 / 132: 60 px either side of x 72
    for bx,lx in ((ox+SELX,1*8+4),(ox+STAX,16*8+4)):
        img[oy+47:92+1,bx]=1                           # down from the button to y 92 (row 11)
        img[92,min(bx,lx):max(bx,lx)+1]=1              # across
        img[92:95,lx]=1                                # down to just above the label (row 12)
    rich(1,14,'{D-pad}: move'); rich(1,15,'{L+R+button}: DX options')
    ctext(17,name+"'S MOVES",1)
    # Moves: packed one per tile row in the map (rows 18..23), then spaced out on screen at pixel level by an
    # HDMA table on BG3 vertical scroll (see help.asm), so no extra tiles are needed: 3 px under the heading,
    # 2 blank lines between entries (+ the blank top row of the next line = 3 px), continuation lines stay
    # 8 px apart. Each entry is shown from map line 1 of its row, so the tail of the line above (drawn into
    # line 0) is not repeated. Gaps show the blank map rows 24-25.
    r=17; ents=[]
    for k,v in moves:
        r+=1; text(1,r,k,1 if k else 0); rich(12,r,v)
        if k: ents.append([r,1])
        else: ents[-1][1]+=1
    assert r<=23,(name,r)
    ctext(26,'SELECT or START: back',1)
    put_tails()
    assert not img[192:208].any(),(name,'blank rows 24-25 must stay blank')
    BL=192; seg=[]          # (lines, vofs)
    seg.append((144,0)); y=144
    seg.append((3,BL-y)); y+=3
    for i,(m,n) in enumerate(ents):
        seg.append((8*n,8*m-y)); y+=8*n   # screen line y shows map line y+VOFS+1 (BG quirk), so this is map line 8m+1
        g=2 if i<len(ents)-1 else 208-y
        assert 0<g<=16,(name,g); seg.append((g,BL-y)); y+=g
    # Last 16 lines: VOFS -1 so screen line y shows map line y. With VOFS 0 the BG quirk (+1) made line 223 show
    # map row 28, outside the 28 rows the overlay uploads/restores (it holds stale game tiles: dotted line).
    assert y==208; seg.append((16,-1))
    hd=bytearray()
    for n,v in seg:
        while n>0:
            c=min(n,127); hd+=bytes([c,0,0,v&0xff,(v>>8)&3]); n-=c   # mode 3: BG3HOFS lo,hi = 0, BG3VOFS lo,hi
    hd+=b'\0'; assert len(hd)<=128; hd+=bytes(128-len(hd))
    return img,pal,hd

# Button styles per character: the pad tables at C0:894B (Hornisse) / C0:88FE (Sara) / C0:8998 (Ryo) map each
# button/combo to an action, names from watching each one in Mesen. B+Y exists only for Sara (star fall) and
# Ryo (wall of fire); Hornisse's table has no B+Y entry, so B+Y is just his B stab.
P={0:('HORNISSE',[('A+B','Morning star'),('Mash B','Sword frenzy'),('Spin D-pad','then {A}: Lightning'),('','(costs 10% of gold)'),('X','Shock wave (uses 1)')],
      {'X':'Shock wave','B':'Stab','A':'Overhead','Y':'Low sweep'}),
   1:('SARA',[('A+B','Homing flame'),('B+Y','Star fall'),('Spin D-pad','then {B}: Dragon Fire'),('','(costs 10% of gold)'),('X','Giant star (uses 1)')],
      {'X':'Giant star','B':'Fire shot','A':'Spark shot','Y':'Wing spin'}),
   2:('RYO',[('A+B','Bombs'),('B+Y','Wall of fire'),('Spin D-pad','(slow) then {Y}:'),('','Shadow clones'),('','(costs 10% of gold)'),('X','Petal storm (uses 1)')],
      {'X':'Petal storm','B':'Sickle','A':'Chain sickle','Y':'Throw blade'})}
# Held L+R while the overlay is open: the X/A/Y/B labels (map rows 3..10 incl. the hint/header row, columns 18..31, incl. descender rows)
# are swapped for the DX option each L+R+button toggles (asm/options.asm combo, docs/MOVES.md). Same for everyone.
LR={'X':'Turbo','A':'Fast foes','Y':'Hero speed','B':'Rumble off'}
LRR,LRC,LRH,LRW=3,18,8,14
tiles={bytes(16):0}; chr_=bytearray(16); maps=bytearray(); prev=[]; hdma=bytearray()
def enc(img,pal,ty,tx):
    t=img[ty*8:ty*8+8,tx*8:tx*8+8]; b=bytearray(16)
    for y in range(8):
        for x in range(8):
            v=int(t[y,x]); b[2*y]|=(v&1)<<(7-x); b[2*y+1]|=((v>>1)&1)<<(7-x)
    b=bytes(b)
    if b not in tiles: tiles[b]=len(tiles); chr_.extend(b)
    w=tiles[b]|(int(pal[ty,tx])<<10)|0x2000
    return bytes([w&0xff,w>>8])
for k in (0,1,2):
    img,pal,hd=page(*P[k]); hdma+=hd
    Image.fromarray((img*80).astype(np.uint8)).save(GEN+'/help_preview_%d.png'%k)
    if k==0:
        aimg,apal,_=page(P[0][0],P[0][1],LR,True); lrmap=bytearray()
        Image.fromarray((aimg*80).astype(np.uint8)).save(GEN+'/help_preview_lr.png')
        for ty in range(LRR,LRR+LRH):
            lrmap+=bytes(2*LRC)   # 64-byte rows like help_map, so help.asm uses one stride for both
            for tx in range(LRC,LRC+LRW): lrmap+=enc(aimg,apal,ty,tx)
        assert not aimg[(LRR+LRH)*8:(LRR+LRH)*8+8,LRC*8:].any() and all(len(LR[b])<=LRW-2 for b in LR)
    for ty in range(28):
        for tx in range(32):
            maps+=enc(img,pal,ty,tx)
NT=len(tiles)
assert NT<=144,'help overlay: %d tiles (max 144 = 2304 bytes of the 4 KB save buffer)'%NT
open(GEN+'/help_hdma.bin','wb').write(hdma); open(GEN+'/help_chr.bin','wb').write(chr_); open(GEN+'/help_map.bin','wb').write(maps); open(GEN+'/help_lr.bin','wb').write(lrmap)
open(GEN+'/help.asm','w').write(';; generated by tools/py/helpgfx.py\n!HELP_NT = %d\n'%NT)
print('helpgfx: %d tiles (%d bytes), maps %d bytes'%(NT,len(chr_),len(maps)))
