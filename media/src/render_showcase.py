#!/usr/bin/env python3
"""Render KwikTip's README graphics from its existing public product images.

Retail uses an existing public screenshot. Forever uses an offline simulator
render of the actual addon with synthetic state; neither GIF is gameplay footage.
"""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "showcase"
OUT.mkdir(parents=True, exist_ok=True)
FONT = "/usr/share/fonts/TTF/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"

def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)

def background(w, h):
    im = Image.new("RGB", (w, h))
    pix = im.load()
    assert pix is not None
    for y in range(h):
        for x in range(w):
            glow = max(0, 1 - math.hypot((x-w*.80)/(w*.78), (y-h*.12)/(h*1.3)))
            pix[x,y] = (int(18+26*glow), int(17+5*glow), int(24+8*glow))
    return im.convert("RGBA")

def fit(im, size):
    im = im.copy()
    im.thumbnail(size, Image.Resampling.LANCZOS)
    return im

def logo():
    im = Image.open(ROOT / "assets/ktlogo.png").convert("RGBA")
    return im.crop(im.getchannel("A").getbbox())

def pill(draw, xy, text):
    x,y=xy
    draw.rounded_rectangle((x,y,x+157,y+34),radius=17,fill=(105,28,35,255),outline=(186,75,76,255),width=1)
    draw.text((x+17,y+7),text,font=font(15,True),fill=(255,221,211,255))

def panel(im, image, xy, width):
    src=fit(image,(width,1000)); x,y=xy
    shadow=Image.new("RGBA", im.size); d=ImageDraw.Draw(shadow)
    d.rounded_rectangle((x-9,y-9,x+src.width+9,y+src.height+9),radius=15,fill=(0,0,0,200))
    shadow=shadow.filter(ImageFilter.GaussianBlur(18)); im.alpha_composite(shadow)
    ImageDraw.Draw(im).rounded_rectangle((x-5,y-5,x+src.width+5,y+src.height+5),radius=9,fill=(18,18,27,255),outline=(186,145,74,255),width=2)
    im.alpha_composite(src,(x,y))
    return src.size

hud=Image.open(ROOT/'assets/tipwindow.png').convert('RGBA')
brand=fit(logo(),(355,150))
hero=background(1600,520); d=ImageDraw.Draw(hero)
hero.alpha_composite(brand,(78,53)); d.text((79,218),'THE RIGHT TIP,',font=font(56,True),fill='#faf4ed')
d.text((79,284),'RIGHT WHEN IT MATTERS.',font=font(47,True),fill='#faf4ed')
d.text((80,378),'A compact dungeon HUD for World of Warcraft',font=font(22),fill='#c5b9b0')
pill(d,(81,425),'RETAIL + FOREVER')
d.text((856, 146), 'RETAIL EXAMPLE', font=font(15, True), fill='#ddada6')
panel(hero,hud,(855,177),660)
hero.convert('RGB').save(OUT/'kwiktip-hero.png', optimize=True)

# A short, silent motion graphic from the actual Retail screenshot, not gameplay.
w,h=1000,562
base=background(w,h); frames=[]
for frame in range(48):
    t=frame/47
    canvas=base.copy(); draw=ImageDraw.Draw(canvas)
    draw.text((58,45),'KWIKTIP  /  RETAIL',font=font(18,True),fill='#df8b81')
    draw.text((58,88),'A tip at a glance',font=font(39,True),fill='#faf4ed')
    draw.text((59,145),'Real addon screenshot  ·  animated presentation',font=font(16),fill='#bdada4')
    scale=1+0.025*math.sin(t*math.pi)
    width=int(800*scale); img=fit(hud,(width,1000)); x=(w-img.width)//2; y=227-int(5*math.sin(t*math.pi))
    panel(canvas,img,(x,y),width)
    draw=ImageDraw.Draw(canvas)
    draw.line((58,494,942,494), fill=(111,56,57,255),width=2)
    draw.text((58,510),'Position it where you need it.',font=font(18),fill='#f1e5db')
    frames.append(canvas.convert('RGB').quantize(colors=96,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE))
frames[0].save(OUT/'retail-tip-tour.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True,disposal=2)

# The Forever frame comes from the actual addon in an offline simulator with
# a synthetic instance. The crop retains the whole HUD; it is not gameplay.
forever=Image.open(ROOT/'media/src/forever-sim.png').convert('RGBA').crop((550,335,1035,565))
base=background(w,h); frames=[]
for frame in range(48):
    t=frame/47
    canvas=base.copy(); draw=ImageDraw.Draw(canvas)
    draw.text((58,45),'KWIKTIP  /  FOREVER ALPHA',font=font(18,True),fill='#df8b81')
    draw.text((58,88),'Ready before the pull',font=font(39,True),fill='#faf4ed')
    draw.text((59,145),'Simulated addon UI  ·  synthetic dungeon state',font=font(16),fill='#bdada4')
    width=int(730*(1+0.02*math.sin(t*math.pi)))
    image=fit(forever,(width,1000)); x=(w-image.width)//2
    panel(canvas,image,(x,196-int(4*math.sin(t*math.pi))),width)
    draw=ImageDraw.Draw(canvas)
    draw.line((58,494,942,494),fill=(111,56,57,255),width=2)
    draw.text((58,510),'Choose a boss. Preview the tip.',font=font(18),fill='#f1e5db')
    frames.append(canvas.convert('RGB').quantize(colors=96,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE))
frames[0].save(OUT/'forever-tip-tour.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True,disposal=2)
print('Rendered', OUT/'kwiktip-hero.png', OUT/'retail-tip-tour.gif', OUT/'forever-tip-tour.gif')
