"""v24: значки — факел (gear_torch)."""
from PIL import Image
import os
ART = os.path.join(os.path.dirname(__file__), '..', 'art')
def hx(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))+(255,)
OUT=hx('1c120c')
def torch():
    im=Image.new('RGBA',(24,24),(0,0,0,0)); px=im.load()
    # рукоять по диагонали снизу-слева вверх-вправо
    for i in range(12):
        x=5+i; y=21-i
        for dx,c in ((-1,OUT),(0,hx('6a4428')),(1,hx('9a6a3e')),(2,OUT)):
            px[x+dx,y]=c
        if i%3==0: px[x,y]=hx('4e3220')
    # обмотка (ткань в смоле)
    for (x,y) in [(15,9),(16,9),(17,9),(16,8),(17,8),(18,8),(15,10),(16,10),(14,10),(17,7),(18,7)]:
        px[x,y]=hx('3a2a22')
    for (x,y) in [(16,9),(17,8)]: px[x,y]=hx('5a4434')
    # пламя
    flame={(17,6):'f8a030',(18,6):'f8a030',(16,6):'e86a20',(19,6):'e86a20',(17,5):'fcd060',(18,5):'f8a030',(16,5):'e86a20',
           (17,4):'fcd060',(18,4):'fff0a0',(19,5):'e86a20',(18,3):'fcd060',(17,3):'f8a030',(19,3):'e86a20',(18,2):'f8a030',(19,2):'e86a20',(19,1):'e86a20',(16,4):'e86a20',(19,4):'f8a030',(20,4):'c84a18',(15,5):'c84a18'}
    for (x,y),c in flame.items(): px[x,y]=hx(c)
    # контур пламени
    for (x,y),c in list(flame.items()):
        for dx,dy in ((1,0),(-1,0),(0,-1)):
            q=(x+dx,y+dy)
            if 0<=q[0]<24 and 0<=q[1]<24 and px[q][3]==0: px[q]=hx('6a1e0c')
    im.save(os.path.join(ART,'gear_torch.png'))
torch()
print('ok')
