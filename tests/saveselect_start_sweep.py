import sys,numpy as np; sys.path.insert(0,'/workspace/trinea/tools/py'); from lr import Emu
from PIL import Image
rom,tag,btn=sys.argv[1],sys.argv[2],sys.argv[3]
e=Emu(rom,core='/tmp/core/bsnes_mercury_accuracy_libretro.so'); e.poke(0,open('sp.sav','rb').read(),0)
for f in range(1500): e.run(1)
e.run(4,['START']); s0=e.save()
def fin():
    e.shot('/tmp/a.png'); return np.array(Image.open('/tmp/a.png'))
def trial(F,dA=True):
    e.load(s0); f=1504
    while f<2300:
        h=[]
        if dA and 2000<=f<2004: h=['A']
        if F<=f<F+4: h=h+[btn]
        e.run(1,h); f+=1
    return fin()
ref=trial(-99); Image.fromarray(ref).save(f'{tag}_ref.png')
bad=[]
for F in list(range(int(sys.argv[4]),int(sys.argv[5]),int(sys.argv[6]))):
    a=trial(F)
    d=(np.abs(a.astype(int)-ref).sum(axis=2)>30).sum()
    if d>200: bad.append((F,d)); Image.fromarray(a).save(f'{tag}_bad_{F}.png')
print(tag,btn,'diff cases',bad)
