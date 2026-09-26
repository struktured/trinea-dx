import sys,struct,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from paths import ROM
R=open(ROM,'rb').read()
LEN=R[0xCE4:0xCE4+0x47]
def msg(p):
    s=p
    while True:
        b=R[p]
        if b in (0,1): p+=2
        elif b in (0xFE,0xFF): return p+1, R[s:p+1]
        else: p+=1
def walk(p, verbose=False, maxlabels=10**6):
    """walk script from p; returns list of items (type, offset, bytes)"""
    items=[]; start=p
    while True:
        op=R[p]
        if op==0:
            lid=R[p+1]; items.append(('label',p,lid)); p+=2
            if lid==0xFF: break
            continue
        if op>0x46: items.append(('BAD',p,op)); break
        L=LEN[op]
        if L==0xFF:
            q,m=msg(p+1); items.append(('msg',p,m)); p=q
        elif L==0xFE:
            ms=[]; q=p+1
            for k in range(6): q,m=msg(q); ms.append(m+bytes([R[q]])); q+=1
            items.append(('op05',p,R[p:p+1],ms)); p=q
        elif L==0xFD:
            ms=[]; q=p+4
            for k in range(3): q,m=msg(q); ms.append(m)
            items.append(('op46',p,R[p:p+4],ms)); p=q
        elif L==0:
            q=p+2
            while R[q]!=0xFF: q+=1
            items.append(('list',p,R[p:q+1])); p=q+1
        else:
            items.append(('op',p,R[p:p+L])); p+=L
    return items,p
if __name__=='__main__':
    p=int(sys.argv[1],16)
    it,end=walk(p)
    from collections import Counter
    print('end',hex(end),Counter(i[0] for i in it))
    for i in it[:int(sys.argv[2]) if len(sys.argv)>2 else 40]:
        print(i[0],hex(i[1]),i[2].hex(' ') if isinstance(i[2],bytes) else i[2])
