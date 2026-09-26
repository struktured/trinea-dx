"""8x8 small-font additions: font/en_small/glyphs8.txt -> build/font/small_add.bin (tiles $9E..), small_map.json, preview png.
Shadow colour 2 is generated right of every stroke pixel (as in the original caps)."""
import json
from PIL import Image
import numpy as np
import os,sys
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from paths import ROOT,FONT
D=ROOT+'/font/en_small/'; O=FONT+'/'
g=[]; cur=None
for l in open(D+'glyphs8.txt'):
    l=l.rstrip('\n')
    if l.startswith('#') or not l: continue
    if l.startswith('== '):
        t,ch=l[3:].split(' ',1); cur=[int(t,16),ch,[]]; g.append(cur); continue
    cur[2].append(l)
tiles=bytearray(); cmap={}
first=g[0][0]; img=np.zeros((8,8*len(g)),np.uint8)
for i,(t,ch,rows) in enumerate(g):
    assert t==first+i and len(rows)==8,(hex(t),ch,len(rows))
    px=np.zeros((8,8),np.uint8)
    for y,r in enumerate(rows):
        for x,c in enumerate(r[:8]):
            if c=='1': px[y,x]=1
    for y in range(8):
        for x in range(7):
            if px[y,x]==1 and px[y,x+1]==0: px[y,x+1]=2
    for y in range(8):
        p0=p1=0
        for x in range(8):
            p0|=(px[y,x]&1)<<(7-x); p1|=(px[y,x]>>1)<<(7-x)
        tiles+=bytes([p0,p1])
    cmap[ch]=t; img[:,i*8:i*8+8]=px
open(O+'small_add.bin','wb').write(tiles)
json.dump(dict(first=first,map=cmap),open(O+'small_map.json','w'),indent=0)
pal=np.array([[30,30,60],[255,255,255],[60,60,160],[255,0,0]],np.uint8)
Image.fromarray(pal[img]).resize((img.shape[1]*4,32),0).save(O+'small_add.png')
print(len(g),'tiles from',hex(first))
