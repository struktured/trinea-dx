exec(open('fuzz.py').read().split('res={}')[0])
res={}; bad=[]
for t in range(N):
    R=random.Random(t); e.load(s0); seq=[]
    for k in range(R.randrange(5,60)):
        b=R.choice(C); d=R.randrange(1,12); seq.append((tuple(b),d)); e.run(d,b)
    e.run(30); ok=opened(); tries=0
    while not ok and tries<3:   # paused? Start toggles pause, then Select must open
        e.run(4,['START']); e.run(30); ok=opened(); tries+=1
    res[(ok,tries)]=res.get((ok,tries),0)+1
    if not ok: bad.append((t,seq[-6:]))
print(tag,res,'stuck',bad)
