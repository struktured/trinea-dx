import sys; sys.path.insert(0,'/workspace/trinea/tools/py'); from lr import Emu
rom,tag=sys.argv[1],sys.argv[2]
e=Emu(rom,core='/tmp/core/bsnes_mercury_accuracy_libretro.so'); e.run(2)
for st in ('w_echigoya_end','fb_10000','h1_end'):
  for h in (1,2,3):
    for b7 in (0,1):
      e.load(open(f'/workspace/trinea/work/ex/{st}.st','rb').read()); e.run(1)
      e.poke(0x1430,[h])
      if b7: e.poke(0x300,bytes([0x54,0x44,0xA0,0xA0^0xA5]),0); e.poke(0xCF10,[0])
      ok=False
      for f in range(40):
        e.run(1,['SELECT'] if f<4 else [])
        if e.mem()[0x831]==0x40: ok=True; break
      e.run(20)
      if st=='w_echigoya_end' and not b7: e.shot(f'ov_{tag}_h{h}.png')
      e.run(4,['SELECT']); e.run(30); closed=e.mem()[0x831]!=0x40
      print(st,'hero',h,'bit7',b7,'open',ok,'closed',closed)
