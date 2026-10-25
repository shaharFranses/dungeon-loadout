# Procedural brand assets for dungeon-loadout (self-generated, CC0). Inputs: Kenney Tiny Dungeon (CC0), Tiny Creatures (CC0), Kenney Pixel font (CC0). Output: art/brand/.
# Re-run: unzip kenney_tiny-dungeon.zip and tiny-creatures.zip, then point KT / TC / OUT at them (paths below are DL Art's box).
# Kenney tiles used: 89 chest (icon), 40 stone brick, 98 hero, 104 sword (splash). Tiny Creatures: red dragon (art/creatures/red_dragon.png).
from PIL import Image, ImageDraw, ImageFont
import os
KT='/workspace/dl-art/kenney-tiny-dungeon/Tiles/tile_%04d.png'
TC='/workspace/dl-art/repo/art/creatures/%s.png'
OUT=os.environ.get('OUT','/workspace/dl-art/repo/art/brand/')
BG=(0x2B,0x23,0x29,255); BG_DEEP=(0x1B,0x1A,0x24,255); OUTL=(0x3F,0x26,0x31,255); BONE=(0xE8,0xE2,0xD0,255); GOLD=(0xE3,0xB3,0x41,255)
NAVY=(0x26,0x2B,0x44,255); SPARK=(0xFE,0xE7,0x61,255)
def tile(p): return Image.open(p).convert('RGBA')
def up(im,k): return im.resize((im.width*k,im.height*k),Image.NEAREST)

# ---- icon 16x16: Kenney chest (tile 89) with its 2px pack outline replaced by a 1px #3F2631
# outline, centred on the Kenney navy, 1px navy margin.
chest=tile(KT%89)
from collections import deque
W0=16; outside=set(); q=deque((x,y) for x in range(16) for y in range(16) if chest.getpixel((x,y))[3]==0)
outside=set(q)
while q:
    x,y=q.popleft()
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
        nx,ny=x+dx,y+dy
        if 0<=nx<16 and 0<=ny<16 and (nx,ny) not in outside and chest.getpixel((nx,ny))[:3]==OUTL[:3]:
            outside.add((nx,ny)); q.append((nx,ny))
body=chest.copy()
for (x,y) in outside: body.putpixel((x,y),(0,0,0,0))
# bottom rows touching the tile edge: treat edge OUTL runs as outer too (none expected)
body=body.crop(body.getbbox())
bw,bh=body.size
ic=Image.new('RGBA',(16,16),NAVY)
ox,oy=(16-bw)//2,(16-bh)//2
lay=Image.new('RGBA',(16,16),(0,0,0,0)); lay.alpha_composite(body,(ox,oy))
a=lay.split()[3]
for y in range(16):
    for x in range(16):
        if a.getpixel((x,y))==0 and any(0<=x+dx<16 and 0<=y+dy<16 and a.getpixel((x+dx,y+dy)) for dx in (-1,0,1) for dy in (-1,0,1)):
            ic.putpixel((x,y),OUTL)
ic.alpha_composite(lay)
print('chest body',bw,bh,'at',ox,oy)
ic.save(OUT+'icon_16.png')
for k in (2,3,8,9,12,16,32): up(ic,k).save(OUT+f'icon_{16*k}.png')
# apple-touch 180 = x11 (176) centred on navy 2px pad (integer scale preserved)
at=Image.new('RGBA',(180,180),NAVY); at.alpha_composite(up(ic,11),(2,2)); at.save(OUT+'apple-touch-icon_180.png')
up(ic,3).save(OUT+'favicon.ico',format='ICO',sizes=[(16,16),(32,32),(48,48)],append_images=[ic,up(ic,2)])
# SVG from pixel rects
rects=[]
for y in range(16):
    for x in range(16):
        r,g,b,a=ic.getpixel((x,y))
        if a: rects.append(f'<rect x="{x}" y="{y}" width="1" height="1" fill="#{r:02X}{g:02X}{b:02X}"/>')
open(OUT+'icon.svg','w').write('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 16 16" shape-rendering="crispEdges">'+''.join(rects)+'</svg>\n')

# ---- splash 800x600 (matches docs/index.png)
W,H=800,600; sp=Image.new('RGBA',(W,H),BG)
font=ImageFont.truetype('/workspace/dl-art/repo/art/fonts/kenney_pixel.ttf',16)
def text1x(s,col):
    words=s.split(' '); ims=[]
    for w in words:
        im=Image.new('RGBA',(8*len(w)+4,20),(0,0,0,0)); dd=ImageDraw.Draw(im); dd.fontmode='1'; dd.text((1,0),w,font=font,fill=col)
        ims.append(im.crop(im.getbbox()))
    gap=6; h=max(i.height for i in ims); top=min(0,0)
    # align on baseline: use font bbox per word top offset
    outim=Image.new('RGBA',(sum(i.width for i in ims)+gap*(len(ims)-1)+2,h+2),(0,0,0,0)); x=1
    for w,i in zip(words,ims):
        oy=font.getbbox(w)[1]-font.getbbox('D')[1]
        outim.alpha_composite(i,(x,1+oy)); x+=i.width+gap
    # 1px outline in OUTL (8-neighbour), drawn under the glyphs
    a=outim.split()[3]; ol=Image.new('RGBA',outim.size,(0,0,0,0))
    for dx in (-1,0,1):
        for dy in (-1,0,1):
            m=Image.new('L',outim.size,0); m.paste(a,(dx,dy)); ol.paste(Image.new('RGBA',outim.size,OUTL),(0,0),m)
    ol.alpha_composite(outim); return ol
title=up(text1x('Dungeon Loadout',BONE),6)
sp.alpha_composite(title,((W-title.width)//2//6*6,72))
# ground: stone brick wall tile 40 at x4, two rows
for row in range(2):
    for cx in range(0,W,64): sp.alpha_composite(up(tile(KT%40),4),(cx,472+row*64))
hero=up(tile(KT%98),8); sp.alpha_composite(hero,(176,472-hero.height+8))
drag=up(tile(TC%'red_dragon').transpose(Image.FLIP_LEFT_RIGHT),12); sp.alpha_composite(drag,(800-176-drag.width,472-drag.height+12))
sword=up(tile(KT%104),4); sp.alpha_composite(sword,(320,472-sword.height+8))
sp.save(OUT+'boot_splash_800x600.png')
print('done')
