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
def dec(b):
    t=np.zeros((8,8),np.uint8)
    for y in range(8):
        p0,p1=b[2*y],b[2*y+1]
        for x in range(8): t[y,x]=((p0>>(7-x))&1)|(((p1>>(7-x))&1)<<1)
    return t
def glyph(c):
    if c==' ': return np.zeros((8,8),np.uint8)
    if c.isdigit(): t=0x6F+int(c)
    elif 'A'<=c<='Z': t=0x79+ord(c)-65
    elif c=='?': t=0x96
    elif c=='!': t=0x97
    elif c in DESC: return DESC[c][:8]
    elif c in SM: return dec(ADD[(SM[c]-FIRST)*16:(SM[c]-FIRST)*16+16])
    else: raise SystemExit('helpgfx: no glyph for %r'%c)
    return dec(R[0x37000+t*16:0x37000+t*16+16])
W,H=256,224
def page(name,moves,btn):
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
    ctext(1,'CONTROLS - '+name,1)
    # --- SNES pad, tiles x 2..17, y 3..10 (128 x 64 px)
    ox,oy=8,24          # pad at x 8..135: a full tile (8 px+) of space before the labels at column 18
    pad=Image.new('P',(128,64),0); from PIL import ImageDraw; d=ImageDraw.Draw(pad)
    d.rounded_rectangle((10,0,42,10),radius=4,fill=2); d.rounded_rectangle((85,0,117,10),radius=4,fill=2)   # L, R
    d.rounded_rectangle((0,6,127,63),radius=26,fill=2); d.rounded_rectangle((2,8,125,61),radius=24,fill=3)   # body
    d.rectangle((24,22,33,49),fill=2); d.rectangle((15,31,42,40),fill=2)                                     # D-pad
    d.rounded_rectangle((50,38,61,43),radius=2,fill=2); d.rounded_rectangle((66,38,77,43),radius=2,fill=2)   # SELECT START
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
    text(18,3,'X Special',0); text(18,5,'A '+btn['A'],0); text(18,7,'Y '+btn['Y'],0); text(18,9,'B '+btn['B'],0)
    # SELECT and START share one row, mirrored about the screen centre (same order as on the pad: Select left, Start right)
    text(3,12,'SELECT: help',0); text(17,12,'START: pause',0)
    text(3,14,'D-pad: move',0); text(3,15,'L+R+button: DX options',0)
    ctext(17,name+"'S MOVES",1)
    for i,(k,v) in enumerate(moves):
        text(1,18+i,k,1 if k else 0); text(12,18+i,v,0) if len(k)<=10 else None
    ctext(26,'SELECT or START: back',1)
    put_tails()
    return img,pal
# Button styles per character: the pad tables at C0:894B (Hornisse) / C0:88FE (Sara) / C0:8998 (Ryo) map each
# button/combo to an action, names from watching each one in Mesen. B+Y exists only for Sara (star fall) and
# Ryo (wall of fire); Hornisse's table has no B+Y entry, so B+Y is just his B stab.
P={0:('HORNISSE',[('A+B','Morning star'),('Mash B','Sword frenzy'),('Spin D-pad','then A: Lightning'),('','(costs 1/10 of gold)'),('X','X special (uses 1)')],
      {'B':'Stab','A':'Slash','Y':'Slash'}),
   1:('SARA',[('A+B','Homing flame'),('B+Y','Star fall'),('Spin D-pad','then B: Dragon Fire'),('','(costs 1/10 of gold)'),('X','X special (uses 1)')],
      {'B':'Fire shot','A':'Spark shot','Y':'Wing spin'}),
   2:('RYO',[('A+B','Bombs'),('B+Y','Wall of fire'),('Spin D-pad','(slow) then Y:'),('','Shadow clones'),('','(costs 1/10 of gold)'),('X','X special (uses 1)')],
      {'B':'Sickle','A':'Chain sickle','Y':'Throw blade'})}
tiles={bytes(16):0}; chr_=bytearray(16); maps=bytearray(); prev=[]
for k in (0,1,2):
    img,pal=page(*P[k])
    Image.fromarray((img*80).astype(np.uint8)).save(GEN+'/help_preview_%d.png'%k)
    for ty in range(28):
        for tx in range(32):
            t=img[ty*8:ty*8+8,tx*8:tx*8+8]; b=bytearray(16)
            for y in range(8):
                for x in range(8):
                    v=int(t[y,x]); b[2*y]|=(v&1)<<(7-x); b[2*y+1]|=((v>>1)&1)<<(7-x)
            b=bytes(b)
            if b not in tiles: tiles[b]=len(tiles); chr_+=b
            w=tiles[b]|(int(pal[ty,tx])<<10)|0x2000   # priority bit
            maps+=bytes([w&0xff,w>>8])
NT=len(tiles)
assert NT<=144,'help overlay: %d tiles (max 144 = 2304 bytes of the 4 KB save buffer)'%NT
open(GEN+'/help_chr.bin','wb').write(chr_); open(GEN+'/help_map.bin','wb').write(maps)
open(GEN+'/help.asm','w').write(';; generated by tools/py/helpgfx.py\n!HELP_NT = %d\n'%NT)
print('helpgfx: %d tiles (%d bytes), maps %d bytes'%(NT,len(chr_),len(maps)))
