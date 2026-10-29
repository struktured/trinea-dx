import sys; sys.path.insert(0,'/workspace/trinea/tools/py'); from lr import Emu
e=Emu(sys.argv[1],core='/tmp/core/bsnes_mercury_accuracy_libretro.so'); e.run(2)
e.load(open('/workspace/trinea/work/ex/w_echigoya_end.st','rb').read()); e.run(1)
o=e.mem(0)[0x300:0x304].hex(); e.run(1,['L','R']); e.run(5,['L','R','START']); e.run(5,['L','R']); e.run(40)
e.shot(f'lrs_{sys.argv[2]}.png'); print(sys.argv[2],'sram',o,'->',e.mem(0)[0x300:0x304].hex())
