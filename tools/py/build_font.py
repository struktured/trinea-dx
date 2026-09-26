"""Build EN VWF font: font/en/glyphs_v2.txt -> build/font/font.bin (96 glyphs x 16 rows x [plane0,plane1]), widths.bin (advance px), font.png preview."""
import numpy as np
from PIL import Image
import os,sys
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from paths import ROOT,FONT
SRC=os.environ.get('TRINEA_FONT',ROOT+'/font/en/glyphs_v2.txt'); OUT=FONT+'/'
TOP=3  # first cap row inside the 16px cell
g={}; cur=None
for l in open(SRC):
    l=l.rstrip('\n')
    if l.startswith('#') and cur is None: continue
    if l.startswith('== '):
        n=l[3:]; cur={'space':' ','DEL':'\x7f'}.get(n,n); g[cur]=[]; continue
    if cur is not None and l and set(l)<=set('.#'): g[cur].append(l)
font=bytearray(); widths=bytearray(); sheet=np.zeros((16*6,16*16),np.uint8)
for code in range(0x20,0x80):
    ch=chr(code); rows=g.get(ch)
    assert rows is not None and len(rows) in (10,11), (ch, rows and len(rows))
    TOP=3 if len(rows)==10 else 2
    w=max(len(r) for r in rows)
    cell=np.zeros((16,8),np.uint8)
    for y,r in enumerate(rows):
        for x,c in enumerate(r):
            if c=='#': cell[TOP+y,x]=1
    sh=np.zeros_like(cell); sh[1:,1:]=cell[:-1,:-1]
    out=np.where(cell==1,1,np.where(sh==1,2,0)).astype(np.uint8)
    for y in range(16):
        p0=p1=0
        for x in range(8):
            v=out[y,x]; p0|=(v&1)<<(7-x); p1|=((v>>1)&1)<<(7-x)
        font+=bytes([p0,p1])
    adv=w+1 if ch!=' ' else 4
    widths.append(adv)
    i=code-0x20; sheet[(i//16)*16:(i//16)*16+16,(i%16)*16:(i%16)*16+8]=out
open(OUT+'font.bin','wb').write(font); open(OUT+'widths.bin','wb').write(widths)
pal=np.array([[40,40,90],[255,255,255],[60,60,160],[255,80,80]],np.uint8)
Image.fromarray(pal[sheet]).resize((256*3,96*3),0).save(OUT+'font.png')
open(OUT+'widths.txt','w').write('\n'.join('%02X %r %d'%(0x20+i,chr(0x20+i),w) for i,w in enumerate(widths)))
print(len(font),len(widths))
