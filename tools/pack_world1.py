#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import json,re,hashlib

ROOT=Path(__file__).resolve().parents[1]
CAN=ROOT/'res'/'canonical'; REF=ROOT/'reference'; GEN=ROOT/'generated'; GEN.mkdir(exist_ok=True)
GLOBAL=[
(0,0,0),(0,0,8),(0,170,0),(112,221,119),(0,0,187),(100,100,232),(152,14,14),(68,204,255),
(204,51,0),(207,112,112),(204,204,0),(238,238,102),(32,128,32),(191,64,128),(170,170,170),(255,255,255)
]

def nearest_global(rgb):
    if rgb in GLOBAL:return GLOBAL.index(rgb)
    return min(range(16),key=lambda i:sum((rgb[k]-GLOBAL[i][k])**2 for k in range(3)))

def best_two(row):
    u=list(dict.fromkeys(row))
    if len(u)<=2:return u
    best=None
    for i,a in enumerate(u):
        for b in u[i+1:]:
            cost=0
            for p in row:
                da=sum((GLOBAL[p][k]-GLOBAL[a][k])**2 for k in range(3))
                db=sum((GLOBAL[p][k]-GLOBAL[b][k])**2 for k in range(3))
                cost+=min(da,db)
            cand=(cost,a,b)
            if best is None or cand<best:best=cand
    return [best[1],best[2]]

def encode_tile(tile,allow_quant=True):
    tile=tile.convert('RGB');pix=tile.load();pat=bytearray();col=bytearray();changes=0
    for y in range(8):
        row=[nearest_global(pix[x,y]) for x in range(8)]
        u=list(dict.fromkeys(row))
        if len(u)>2:
            if not allow_quant: raise ValueError((y,u))
            pair=best_two(row)
            nr=[min(pair,key=lambda c:sum((GLOBAL[p][k]-GLOBAL[c][k])**2 for k in range(3))) for p in row]
            changes += sum(a!=b for a,b in zip(row,nr)); row=nr;u=list(dict.fromkeys(row))
        if len(u)==1:
            bg=fg=u[0];bits=0
        else:
            if 0 in u: bg=0;fg=u[1] if u[0]==0 else u[0]
            else: bg,fg=u[0],u[1]
            bits=0
            for x,p in enumerate(row):
                if p==fg: bits|=1<<(7-x)
        pat.append(bits);col.append(((fg&15)<<4)|(bg&15))
    return bytes(pat),bytes(col),changes

def paste_text(im,text,tx,ty):
    font=Image.open(CAN/'original_font.png').convert('P');fp=font.load();pal=font.getpalette();dst=im.load()
    for ci,ch in enumerate(text):
        if not (32<=ord(ch)<128):continue
        gx=(ord(ch)-32)*8
        for y in range(8):
            for x in range(8):
                idx=fp[gx+x,y]
                if idx:
                    dst[(tx+ci)*8+x,ty*8+y]=tuple(pal[idx*3:idx*3+3])

def pack_static(name,img,exact=True):
    img=img.convert('RGB'); assert img.size==(256,192)
    maps=[{}, {}, {}]; pp=[[],[],[]];cc=[[],[],[]];names=bytearray(768);changes=0
    for ty in range(24):
        z=ty//8
        for tx in range(32):
            p,c,ch=encode_tile(img.crop((tx*8,ty*8,tx*8+8,ty*8+8)),allow_quant=not exact);changes+=ch
            key=(p,c)
            if key not in maps[z]:
                if len(maps[z])>=256:raise SystemExit(f'{name} zone overflow')
                maps[z][key]=len(maps[z]);pp[z].append(p);cc[z].append(c)
            names[ty*32+tx]=maps[z][key]
    for z in range(3):
        (GEN/f'{name}_z{z}_patterns.bin').write_bytes(b''.join(pp[z]));(GEN/f'{name}_z{z}_colors.bin').write_bytes(b''.join(cc[z]))
    (GEN/f'{name}_names.bin').write_bytes(names)
    return [len(x) for x in pp],changes

def lzss_compress(data:bytes):
    out=bytearray();i=0;lit=bytearray()
    def flush():
        nonlocal lit
        while lit:
            n=min(128,len(lit));out.append(n-1);out.extend(lit[:n]);lit=lit[n:]
    while i<len(data):
        best_len=0;best_off=0;start=max(0,i-2048)
        for j in range(i-1,start-1,-1):
            if data[j]!=data[i]:continue
            ml=min(18,len(data)-i);l=1
            while l<ml and data[j+l]==data[i+l]:l+=1
            if l>=3 and l>best_len:
                best_len=l;best_off=i-j
                if l==18:break
        if best_len>=3:
            flush();off=best_off-1;out.append(0x80|(((off>>8)&7)<<4)|((best_len-3)&15));out.append(off&255);i+=best_len
        else:
            lit.append(data[i]);i+=1
            if len(lit)==128:flush()
    flush();return bytes(out)

def lzss_decompress(data:bytes):
    out=bytearray();i=0
    while i<len(data):
        t=data[i];i+=1
        if t<128:
            n=t+1;out.extend(data[i:i+n]);i+=n
        else:
            n=(t&15)+3;off=((((t>>4)&7)<<8)|data[i])+1;i+=1
            for _ in range(n):out.append(out[-off])
    return bytes(out)

# title and area card (BASE03 composition)
title=Image.open(CAN/'title_original_clean.png').convert('RGB');paste_text(title,'PUSH START',13,18);title.save(GEN/'title_composed.png')
title_counts,title_changes=pack_static('title',title,True)
area=Image.open(CAN/'area1_original.png').convert('RGB');area_counts,area_changes=pack_static('area1',area,True)

# Prologue mother-ship frames. Shared SCREEN4 tiles, compressed name tables.
intro_variants=['mother_closed.png','mother_open.png']+[f'mother_depart_{i}.png' for i in range(8)]
intro_maps=[{}, {}, {}]; intro_pp=[[],[],[]]; intro_cc=[[],[],[]]; intro_name_lz=[]; intro_changes=0
star_sx=[472,152,328,224,544,188,176,400,288,128,504,240,352,176,480,64,288,416]
star_cols=[10,10,8,7,10,7,8,10,7,7,8,10,10,7,10,10,8,7]
for fn in intro_variants:
    fr=Image.new('RGB',(256,192),(0,0,0)); fp=fr.load()
    for sy,(sx,sc) in enumerate(zip(star_sx,star_cols)):
        px=(sx-64)//2; py=16+sy*8+3
        if 0<=px<256 and 0<=py<192: fp[px,py]=GLOBAL[sc]
    fr.paste(Image.open(CAN/fn).convert('RGB'),(32,32))
    nbuf=bytearray(768)
    for ty in range(24):
        z=ty//8
        for tx in range(32):
            pt,co,ch=encode_tile(fr.crop((tx*8,ty*8,tx*8+8,ty*8+8)),True); intro_changes+=ch; key=(pt,co)
            if key not in intro_maps[z]:
                if len(intro_maps[z])>=256: raise SystemExit(f'intro zone {z} overflow')
                intro_maps[z][key]=len(intro_maps[z]); intro_pp[z].append(pt); intro_cc[z].append(co)
            nbuf[ty*32+tx]=intro_maps[z][key]
    packed=lzss_compress(bytes(nbuf)); assert lzss_decompress(packed)==bytes(nbuf); intro_name_lz.append(packed)
for z in range(3):
    (GEN/f'intro_z{z}_patterns.bin').write_bytes(b''.join(intro_pp[z])); (GEN/f'intro_z{z}_colors.bin').write_bytes(b''.join(intro_cc[z]))
for i,b in enumerate(intro_name_lz): (GEN/f'intro_names_{i}.lz').write_bytes(b)

# full world 1 stage, 504 x 22 tiles. Canonical bitmap has 16 px top padding;
# the actual 22-row playfield is y=16..191. BASE04 incorrectly used y=0..175.
stage_src=Image.open(CAN/'stage1_map.png').convert('RGB');assert stage_src.size==(4032,224)
stage=stage_src.crop((0,16,4032,192)); assert stage.size==(4032,176)
# Native starfield is an independent moving background in original HSP (stars082).
# FIX03 draws its initial position into the black playfield background so the
# previously starless first gameplay screen doesn't pop at the mothership cut.
# This is a *static* stopgap: do NOT mistake it for source-faithful parallax.
stage_px=stage.load()
for cycle in range(0,4032,256):
    for sy,(sx,sc) in enumerate(zip(star_sx,star_cols)):
        x=(sx-64)//2 + cycle
        y=(16+sy*8+3)-8  # game playfield begins at screen Y=8
        if 0<=x<4032 and 0<=y<140 and stage_px[x,y]==(0,0,0):
            stage_px[x,y]=GLOBAL[sc]
COLS=504;ROWS=22;PF_ROW=1
maps=[{}, {}, {}];pp=[[],[],[]];cc=[[],[],[]];names=bytearray(COLS*ROWS);pix_changes=0
# reserve black tile index 0 in each zone
black=Image.new('RGB',(8,8),(0,0,0));bp,bc,_=encode_tile(black)
for z in range(3):maps[z][(bp,bc)]=0;pp[z].append(bp);cc[z].append(bc)
for r in range(ROWS):
    z=(PF_ROW+r)//8
    for c in range(COLS):
        p,co,ch=encode_tile(stage.crop((c*8,r*8,c*8+8,r*8+8)),True);pix_changes+=ch;key=(p,co)
        if key not in maps[z]:
            if len(maps[z])>=256:raise SystemExit(f'stage zone {z} >256 tiles')
            maps[z][key]=len(maps[z]);pp[z].append(p);cc[z].append(co)
        names[r*COLS+c]=maps[z][key]

# add HUD/pause/clear row tiles into zone 0
val=Image.open(REF/'stage1_validation.png').convert('RGB');hud=val.crop((32,24,288,32));hud.save(GEN/'hud_row.png')
font=Image.open(CAN/'original_font.png').convert('RGB')
def textrow(text):
    im=Image.new('RGB',(256,8),(0,0,0));start=max(0,(32-len(text))//2)
    pfont=Image.open(CAN/'original_font.png').convert('P');fp=pfont.load();pal=pfont.getpalette();dp=im.load()
    for ci,ch in enumerate(text):
        gx=(ord(ch)-32)*8
        for y in range(8):
            for x in range(8):
                idx=fp[gx+x,y]
                if idx:dp[(start+ci)*8+x,y]=tuple(pal[idx*3:idx*3+3])
    return im
pause=textrow('PAUSE');clear=textrow('AREA 1 CLEAR')
def add_zone0_row(im):
    out=bytearray(32)
    for tx in range(32):
        p,c,_=encode_tile(im.crop((tx*8,0,tx*8+8,8)),True);key=(p,c)
        if key not in maps[0]:
            if len(maps[0])>=256:raise SystemExit('zone0 overflow after HUD')
            maps[0][key]=len(maps[0]);pp[0].append(p);cc[0].append(c)
        out[tx]=maps[0][key]
    return bytes(out)
hud_names=add_zone0_row(hud);pause_names=add_zone0_row(pause);clear_names=add_zone0_row(clear)
# Original Volca-Stone HUD: 30 icons along the bottom row.  In the 192-line
# MSX2 layout row 0 is HUD, rows 1..22 are the full 176px playfield and row 23
# is reserved for the stone strip.
stones=Image.open(CAN/'hud_stones_native.png').convert('RGB')
stone_tiles=[]
for sx in (0,8,16):
    p,c,_=encode_tile(stones.crop((sx,0,sx+8,8)),True);key=(p,c)
    if key not in maps[2]:
        if len(maps[2])>=256: raise SystemExit('zone2 overflow after stones')
        maps[2][key]=len(maps[2]);pp[2].append(p);cc[2].append(c)
    stone_tiles.append(maps[2][key])
stone_row=bytearray(32); stone_row[1:31]=bytes([stone_tiles[0]])*30
(GEN/'stones_empty_row.bin').write_bytes(stone_row)
for z in range(3):
    (GEN/f'stage_z{z}_patterns.bin').write_bytes(b''.join(pp[z]));(GEN/f'stage_z{z}_colors.bin').write_bytes(b''.join(cc[z]))
(GEN/'hud_names.bin').write_bytes(hud_names);(GEN/'pause_names.bin').write_bytes(pause_names);(GEN/'clear_names.bin').write_bytes(clear_names);(GEN/'blank_row.bin').write_bytes(bytes(32))

stage_lz=lzss_compress(bytes(names));assert lzss_decompress(stage_lz)==bytes(names)
(GEN/'stage_names_lz.bin').write_bytes(stage_lz)

# collision rows from canonical attr/map. RLE [count,value] + 0 terminator per row
txt=(REF/'gen_stage1.c').read_text()
def parse_array(name):
    m=re.search(rf'const\s+u(?:8|16|32)\s+{re.escape(name)}\s*\[[^\]]+\]\s*=\s*\{{(.*?)\}};',txt,re.S)
    if not m:raise SystemExit(name)
    return [int(x,0) for x in re.findall(r'0x[0-9A-Fa-f]+|-?\d+',m.group(1))]
attr=parse_array('stage1_attr');mp=parse_array('stage1_map_rom');assert len(mp)==COLS*ROWS
coll_rle=bytearray();coll_off=[];coll_raw=bytearray(COLS*ROWS)
for r in range(ROWS):
    coll_off.append(len(coll_rle));row=[]
    for c in range(COLS):
        tid=mp[c*ROWS+r];v=1 if (0<=tid<len(attr) and attr[tid] in (1,2,4,5)) else 0;row.append(v);coll_raw[r*COLS+c]=v
    i=0
    while i<COLS:
        v=row[i];j=i+1
        while j<COLS and row[j]==v and j-i<255:j+=1
        coll_rle.extend([j-i,v]);i=j
    coll_rle.append(0)
(GEN/'collision_rle.bin').write_bytes(coll_rle)
ptr=bytearray()
for o in coll_off:ptr+=bytes([o&255,(o>>8)&255])
(GEN/'collision_offsets.bin').write_bytes(ptr)

# canonical spawn schedule -> all 184 World-1 script entries.
# Behaviour families are compacted for MSX2, but no scripted entry is dropped.
stxt=(REF/'stage1_script.h').read_text();body=re.search(r'\{(.*)\};',stxt,re.S).group(1);vals=[int(x) for x in re.findall(r'-?\d+',body)]
i=0;tick=0;sp=[]
def spawn_kind(typ):
    if typ in (5,6,7,8,105): return 3       # wasp/oruga moving family
    if typ in (103,101,102,106,107,125): return 4  # anchored/turret family
    if typ in (99,): return 5               # Volca-Stone trigger/item marker
    if typ == 250: return 10                # ocular mid-boss #1 (priority event)
    if typ == 251: return 11                # ocular mid-boss #2 (priority event)
    if typ == 300: return 20              # actual CAUTION banner
    if typ == 301: return 21              # original directional arrow
    if typ == 303: return 22              # original persistent warning
    if typ in (200,): return 8              # heavy walker
    if typ in (10,11): return 9             # directional projectile
    if typ in (12,): return 2               # totem/popcorn visual family
    return 1                                # generic canonical hostile
while i<len(vals):
    v=vals[i]
    if v==-1: tick+=4;i+=1;continue
    if v==-2: break
    typ,x,y,score,hp,param=vals[i:i+6];i+=6
    col=min(470,tick//8)
    kind=spawn_kind(typ)
    # script coordinates are px640; natural screen y is half scale with viewport clamp
    yn=max(20,min(176,y//2))
    speed=3 if kind in (3,9) else (1 if kind in (4,5,7,8,10,11) else 2)
    sp.append((col,kind,yn,speed,typ,param,hp))
# record: col lo, col hi, compact behaviour kind, y, speed, canonical param
# Param is required for Volca-Stone identity (0..29) and is preserved for all entries.
sb=bytearray()
for col,kind,y,speed,typ,param,hp in sp: sb+=bytes([col&255,(col>>8)&255,kind,y,speed,param&255])
sb+=b'\xff\xff\x00\x00\x00\x00';(GEN/'spawn_table.bin').write_bytes(sb)

# 16x16 sprite masks
WHITE=(255,255,255);GREEN=(32,128,32);ORANGE=(204,51,0)
def pad16(im):
    im=im.convert('RGB');out=Image.new('RGB',(16,16),(0,0,0));out.paste(im.crop((0,0,min(16,im.width),min(16,im.height))),(0,0));return out
def mask16(im,pred):
    im=pad16(im);o=bytearray()
    for half in (0,8):
        for y in range(16):
            bits=0
            for x in range(8):
                if pred(im.getpixel((half+x,y))):bits|=1<<(7-x)
            o.append(bits)
    return bytes(o)
spr=[];sm={}
def add(name,im,pred):
    # Sprite table is exactly 64 native 16x16 masks. Alias byte-identical masks
    # instead of wasting four slots: reserve room for the original warning art.
    mask=mask16(im,pred)
    for i,prev in enumerate(spr):
        if prev==mask:
            sm[name]=i*4
            return
    sm[name]=len(spr)*4
    spr.append(mask)
player=Image.open(CAN/'player_exact.png').convert('RGB')
for f in range(3):
    fr=player.crop((f*16,0,f*16+16,16));add(f'player{f}_white',fr,lambda c:c==WHITE);add(f'player{f}_green',fr,lambda c:c==GREEN)
for n in (20,21,22):
    fr=Image.open(CAN/f'player_explosion{n}.png').convert('RGB');add(f'explosion{n}_white',fr,lambda c:c==WHITE);add(f'explosion{n}_orange',fr,lambda c:c==ORANGE)
shots={'front0':'shot_v_front.png','front1':'shot_slash_front.png','front2':'shot_h_front.png','front3':'shot_backslash_front.png','rear0':'shot_v_rear.png','rear1':'shot_slash_rear.png','rear2':'shot_h_rear.png','rear3':'shot_backslash_rear.png'}
for k,fn in shots.items():add('shot_'+k,Image.open(CAN/fn).convert('RGB').crop((0,0,16,16)),lambda c:c!=(0,0,0))
eb=Image.open(CAN/'enemy_basic.png').convert('RGB');add('enemy_basic0',eb.crop((0,0,16,16)),lambda c:c!=(0,0,0))
add('enemy_wasp',Image.open(CAN/'wasp105.png'),lambda c:c!=(0,0,0));add('enemy_pop0',Image.open(CAN/'popcorn102.png'),lambda c:c!=(0,0,0))
add('flame_down',Image.open(CAN/'flame_down_exact.png'),lambda c:c!=(0,0,0))
add('flame_rear',Image.open(CAN/'flame_rear_exact.png'),lambda c:c!=(0,0,0))
escort=Image.open(CAN/'escort.png').convert('RGB')
add('intro_escort_white',escort,lambda c:c==WHITE)
add('intro_escort_orange',escort,lambda c:c==ORANGE)
add('stone',Image.open(CAN/'volca_stone_item.png'),lambda c:c!=(0,0,0))
# Ocular Sentinel #1: preserve the complete 40x64 silhouette as twelve 16x16
# sprite blocks.  Each sprite slot receives a per-scanline MSX2 colour chosen
# from the dominant canonical colour on that block line, so the mid-boss is no
# longer reduced to the 16x16 placeholder used by BASE05.
sen=Image.open(CAN/'sentinel180.png').convert('RGB')
sentinel_slot_colors=[]
for br in range(4):
    for bc0 in range(3):
        block=Image.new('RGB',(16,16),(0,0,0));block.paste(sen.crop((bc0*16,br*16,min(40,bc0*16+16),min(64,br*16+16))),(0,0))
        add(f'sentinel_b{br}_{bc0}',block,lambda c:c!=(0,0,0))
        linecols=[]
        for yy in range(16):
            vals=[block.getpixel((xx,yy)) for xx in range(16) if block.getpixel((xx,yy))!=(0,0,0)]
            if not vals: linecols.append(0)
            else:
                from collections import Counter
                linecols.append(nearest_global(Counter(vals).most_common(1)[0][0]))
        sentinel_slot_colors.append(linecols)
# warning signs reduced to 16x16 tiles for the compact sprite renderer
# FIX03: two separate 16x16 sprite masks reconstruct the whole 32x8 CAUTION.
# Arrow650/651 is 32x24: use the central sixteen rows to preserve the arrow
# shape within the sprite budget; the full-sized original remains in /res.
caution=Image.open(CAN/'caution650.png').convert('RGB')
add('caution_left',caution.crop((0,0,16,8)),lambda c:c!=(0,0,0))
add('caution_right',caution.crop((16,0,32,8)),lambda c:c!=(0,0,0))
arrow=Image.open(CAN/'arrow651.png').convert('RGB')
add('arrow_left',arrow.crop((0,3,16,19)),lambda c:c!=(0,0,0))
add('arrow_right',arrow.crop((16,3,32,19)),lambda c:c!=(0,0,0))
# boss eye/core canonical chr 700/701/702 (closed/open animation)
g=Image.open(REF/'g_chara0.bmp').convert('P'); ctab=json.load(open(REF/'chr_table.json'))['pats']
for cid,label in [(700,'boss_eye0'),(702,'boss_eye_open')]:
    ct=ctab[str(cid)]; crop=g.crop((ct['x'],ct['y'],ct['x']+ct['w'],ct['y']+ct['h'])).convert('RGB')
    native=Image.new('RGB',(max(1,ct['w']//2),max(1,ct['h']//2))); np=native.load(); rp=crop.load()
    for yy in range(native.height):
        for xx in range(native.width): np[xx,yy]=rp[min(ct['w']-1,xx*2),min(ct['h']-1,yy*2)]
    add(label,native,lambda c:c!=(0,0,0))
# Closed eye alternate shares the same MSX2 pattern in this pass; open state remains distinct.
sm['boss_eye1']=sm['boss_eye0']

# BASE09 World-1 source-parity pass: use the original FIX23 chr shapes for the
# main Stage-1 families instead of the generic placeholders from BASE08.  The
# V9938 sprite pattern table has room for 64 native 16x16 patterns; these extra
# 19 patterns keep the pack at <= 2048 bytes.  Multi-colour originals are
# represented by their exact silhouette; runtime colour remains family-driven.
ctab_all=json.load(open(REF/'chr_table.json'))['pats']
gsrc=Image.open(REF/'g_chara0.bmp').convert('RGB')
def add_chr16(cid,label):
    ct=ctab_all[str(cid)]
    crop=gsrc.crop((ct['x'],ct['y'],ct['x']+ct['w'],ct['y']+ct['h']))
    nw=max(1,ct['w']//2); nh=max(1,ct['h']//2)
    native=crop.resize((nw,nh),Image.Resampling.NEAREST)
    add(label,native,lambda c:c!=(0,0,0))
for cid,label in [
    (104,'chr104'),
    (121,'chr121'),(123,'chr123'),
    (133,'chr133'),
    (113,'chr113'),(115,'chr115'),(117,'chr117'),(119,'chr119'),
    (130,'chr130'),
    (106,'chr106'),(108,'chr108'),
    (135,'chr135'),(136,'chr136'),(137,'chr137'),(138,'chr138'),
    # BASE10 source-parity projectiles/hazards from FIX23.
    (131,'chr131'),(132,'chr132'),          # ID105 double horizontal shot
    (159,'chr159'),                         # Kraken type108 ray/debris
    (163,'chr163'),                         # Kraken type14 armed debris
    (185,'chr185'),(196,'chr196'),         # Kraken type109/110 structures
    (143,'chr143')                           # Sentinel #2 mine body
]: add_chr16(cid,label)
if len(spr)>64: raise SystemExit(f'BASE10 sprite pattern overflow: {len(spr)} > 64')
(GEN/'sprite_patterns.bin').write_bytes(b''.join(spr))
# Sprite-mode-2 colours are indexed by SAT slot, not by pattern.  Keep separate
# tables for the launch sequence and gameplay.  Intro escorts are exact two-layer
# white/orange sprites; gameplay slots 8..19 are reserved for the full Sentinel.
def flat_slot(c): return bytes([c]*16)
# Prologue only uses player white/green + flame in slots 0..2.
intro_sc=bytearray()
for c in [15,12,8]: intro_sc += flat_slot(c)
(GEN/'intro_sprite_colors.bin').write_bytes(intro_sc)
# Gameplay launch uses slots 0..17: 8 normal slots + five two-layer escorts.
game_prefix=bytearray()
for c in [15,12,8,8,8,8,8,8]: game_prefix += flat_slot(c)
game_escort_sc=bytearray(game_prefix)
for c in [15,8,15,8,15,8,15,8,15,8]: game_escort_sc += flat_slot(c)
# Sentinel load is an overlay for slots 8..19 only, preserving slots 0..7.
game_sentinel_sc=bytearray()
for linecols in sentinel_slot_colors: game_sentinel_sc += bytes(linecols)
(GEN/'game_escort_sprite_colors.bin').write_bytes(game_escort_sc)
(GEN/'game_sentinel_sprite_colors.bin').write_bytes(game_sentinel_sc)

# palette bytes
pb=bytearray()
for r,g,b in GLOBAL:
    rr=round(r*7/255);gg=round(g*7/255);bb=round(b*7/255);pb+=bytes([((rr&7)<<4)|(bb&7),gg&7])
(GEN/'palette.bin').write_bytes(pb)

# constants
lines=[]
for n,counts in [('TITLE',title_counts),('AREA1',area_counts)]:
    for z,cnt in enumerate(counts):lines.append(f'{n}_Z{z}_BYTES equ {cnt*8}')
for z,cnt in enumerate([len(x) for x in intro_pp]): lines.append(f'INTRO_Z{z}_BYTES equ {cnt*8}')
for i,b in enumerate(intro_name_lz): lines.append(f'INTRO_NAME{i}_LZ_BYTES equ {len(b)}')
for z in range(3):lines.append(f'STAGE_Z{z}_BYTES equ {len(pp[z])*8}')
lines += [f'STAGE_COLS equ {COLS}',f'STAGE_ROWS equ {ROWS}','PF_ROW equ 1',f'STAGE_RAW_BYTES equ {len(names)}',f'STAGE_LZ_BYTES equ {len(stage_lz)}',f'COLL_RLE_BYTES equ {len(coll_rle)}',f'SPAWN_COUNT equ {len(sp)}',f'SPRITE_PAT_BYTES equ {len(spr)*32}',f'INTRO_SPRITE_COLOR_BYTES equ {len(intro_sc)}',f'GAME_ESCORT_COLOR_BYTES equ {len(game_escort_sc)}',f'GAME_SENTINEL_COLOR_BYTES equ {len(game_sentinel_sc)}',f'HUD_STONE_EMPTY_TILE equ {stone_tiles[0]}',f'HUD_STONE_GOT_TILE equ {stone_tiles[1]}',f'HUD_STONE_GLOW_TILE equ {stone_tiles[2]}','STAGE_SCROLL_MAX equ 471']
for k,v in sorted(sm.items()):lines.append(f'SPR_{k.upper()} equ {v}')
(GEN/'constants.inc').write_text('\n'.join(lines)+'\n')

# preview scroll 0 with black backdrop and player
preview=Image.new('RGB',(256,192),(0,0,0));preview.paste(hud,(0,0));preview.paste(stage.crop((0,0,256,176)),(0,8));stone_src=Image.open(CAN/'hud_stones_native.png').convert('RGB').crop((0,0,8,8));
for i0 in range(30): preview.paste(stone_src,(8+i0*8,184))
pl=player.crop((0,0,16,16));dp=preview.load();spx=pl.load()
for y in range(16):
    for x in range(16):
        if spx[x,y]!=(0,0,0):dp[64+x,80+y]=spx[x,y]
preview.save(GEN/'world1_scroll0_preview.png')

meta={
 'authority_fix23_source_sha256':'34c3b072fb4cba933fe12e1f0f60f14a76e73b86626847d193fe1ec1c50b6aab',
 'stage_pixels':[4032,176],'stage_cols':COLS,'stage_rows':ROWS,'stage_unique_tiles_by_zone':[len(x) for x in pp],
 'stage_screen4_pixel_changes':pix_changes,'stage_raw_names_bytes':len(names),'stage_lz_bytes':len(stage_lz),'collision_rle_bytes':len(coll_rle),
 'canonical_spawns':len(sp),'intro_shared_tile_counts':[len(x) for x in intro_pp],'intro_name_lz_bytes':[len(x) for x in intro_name_lz],'sprite_pattern_bytes':len(spr)*32,'sprite_patterns':sm,'background':'black / VDP backdrop color 0','stone_hud_tiles':stone_tiles,'sentinel_sprite_blocks':12,
 'enemy_colour_policy':'runtime by enemy family, never by SAT slot; compact kind 3/chr105 = MSX2 colour 10 yellow',
 'limitations':['all 184 canonical World-1 script entries are scheduled, but some enemy AI families remain compacted for MSX2 BASE07','PSG/music and MegaQR are not integrated in this World-1 BASE07']
}
(GEN/'base07_resources.json').write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta,indent=2))
