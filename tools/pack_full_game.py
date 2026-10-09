#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
from collections import Counter
import json,re,struct,hashlib,math

ROOT=Path(__file__).resolve().parents[1]
GEN=ROOT/'generated'; GEN.mkdir(exist_ok=True)
CAN=ROOT/'res'/'canonical'
REF=ROOT/'reference'
FULL=REF/'fullgame'
FGEN=FULL/'gen'; FORIG=FULL/'original_data'; FGFX=FULL/'gfx'

GLOBAL=[
(0,0,0),(0,0,8),(0,170,0),(112,221,119),(0,0,187),(100,100,232),(152,14,14),(68,204,255),
(204,51,0),(207,112,112),(204,204,0),(238,238,102),(32,128,32),(191,64,128),(170,170,170),(255,255,255)
]
BANK_SIZE=0x4000
COMMON_BANK=1
GFX_BANKS={n:2+(n-1)*3 for n in range(1,7)}
DATAA_BANKS={n:3+(n-1)*3 for n in range(1,7)}
DATAB_BANKS={n:4+(n-1)*3 for n in range(1,7)}
SCROLL_MAX={1:471,2:389,3:481,4:491,5:390,6:1}
BOSS_HP={1:70,2:56,3:64,4:48,5:64,6:96}
START_POS={1:(32,96),2:(32,96),3:(32,96),4:(32,96),5:(32,96),6:(48,96)}

# ------------------------------------------------------------------ SCREEN4

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

def encode_tile_rgb(tile):
    tile=tile.convert('RGB'); pix=tile.load(); pat=bytearray(); col=bytearray(); changes=0; idxrows=[]
    for y in range(8):
        row=[nearest_global(pix[x,y]) for x in range(8)]
        u=list(dict.fromkeys(row))
        if len(u)>2:
            pair=best_two(row)
            nr=[min(pair,key=lambda c:sum((GLOBAL[p][k]-GLOBAL[c][k])**2 for k in range(3))) for p in row]
            changes+=sum(a!=b for a,b in zip(row,nr)); row=nr;u=list(dict.fromkeys(row))
        if len(u)==1: bg=fg=u[0];bits=0
        else:
            if 0 in u: bg=0;fg=u[1] if u[0]==0 else u[0]
            else: bg,fg=u[0],u[1]
            bits=0
            for x,p in enumerate(row):
                if p==fg:bits|=1<<(7-x)
        pat.append(bits);col.append(((fg&15)<<4)|(bg&15));idxrows.append(tuple(row))
    return bytes(pat),bytes(col),changes,tuple(idxrows)

def key_distance(k1,k2):
    # RGB squared error over the decoded 8x8 indexed image; only used for rare stage-4 tiles.
    rows1=k1[2];rows2=k2[2];d=0
    for y in range(8):
        for x in range(8):
            a=rows1[y][x];b=rows2[y][x]
            if a!=b:d+=sum((GLOBAL[a][q]-GLOBAL[b][q])**2 for q in range(3))
    return d

def pack_static_image(img):
    img=img.convert('RGB');assert img.size==(256,192)
    out=[];names=bytearray(768);changes=0
    for z in range(3):
        keys=[];idx={}
        for ty in range(z*8,(z+1)*8):
            for tx in range(32):
                p,c,ch,rows=encode_tile_rgb(img.crop((tx*8,ty*8,tx*8+8,ty*8+8)));changes+=ch
                k=(p,c,rows)
                if k not in idx: idx[k]=len(keys);keys.append(k)
                names[ty*32+tx]=idx[k]
        out.append((b''.join(k[0] for k in keys),b''.join(k[1] for k in keys),len(keys)))
    return out,bytes(names),changes

def font_textrow(text):
    im=Image.new('RGB',(256,8),(0,0,0));start=max(0,(32-len(text))//2)
    f=Image.open(CAN/'original_font.png').convert('P');fp=f.load();pal=f.getpalette();dp=im.load()
    for ci,ch in enumerate(text):
        if not 32<=ord(ch)<128:continue
        gx=(ord(ch)-32)*8
        for y in range(8):
            for x in range(8):
                idx=fp[gx+x,y]
                if idx:dp[(start+ci)*8+x,y]=tuple(pal[idx*3:idx*3+3])
    return im

# ------------------------------------------------------------------ source arrays

def parse_c_array(path,name):
    txt=Path(path).read_text(errors='ignore')
    m=re.search(rf'const\s+(?:static\s+)?(?:u8|u16|u32|s16)\s+{re.escape(name)}\s*\[[^\]]+\]\s*=\s*\{{(.*?)\}};',txt,re.S)
    if not m: raise RuntimeError(f'missing {name} in {path}')
    return [int(x,0) for x in re.findall(r'0x[0-9A-Fa-f]+|-?\d+',m.group(1))]

def parse_script(n):
    txt=(FGEN/f'stage{n}_script.h').read_text()
    body=re.search(r'\{(.*)\};',txt,re.S).group(1)
    vals=[int(x) for x in re.findall(r'-?\d+',body)]
    rec=[];sep=0;i=0
    while i<len(vals):
        v=vals[i]
        if v==-1:sep+=1;i+=1;continue
        if v==-2:break
        typ,x,y,score,hp,param=vals[i:i+6];i+=6
        rec.append((sep,typ,x,y,score,hp,param))
    return rec,sep

def spawn_kind(n,typ):
    if n==1 and typ==250:return 10
    if n==1 and typ==251:return 11
    if typ==99:return 5
    if typ in (300,301,303):return 7
    if typ in (10,11):return 9
    if typ in (5,6,7,8,105):return 3
    if typ in (103,101,102,106,107,125):return 4
    if typ in (12,):return 2
    if typ in (200,):return 8
    return 1

def compact_spawn(n,scrollmax):
    rec,total_sep=parse_script(n);out=bytearray();stone=[]
    # BASE09: Stage 1 no longer collapses the source IDs into a few generic
    # behaviours.  Keep the exact script step (1 step = 4 logic ticks), the
    # source-derived native coordinates, HP and the behaviour-significant
    # parameter.  This preserves the authored order and half-column timing.
    if n==1:
        kind_map={
            4:1,12:2,7:3,8:4,5:5,6:6,105:7,103:8,101:9,
            250:10,251:11,102:12,99:13,10:14,11:15,106:16,
            107:17,125:18,200:19,300:20,301:21,303:22,
        }
        for step,typ,x,y,score,hp,param in rec:
            kind=kind_map.get(typ,1)
            # HSP px640 -> native MSX2 256-wide playfield used by this port:
            # x local=(x-64)/2; playfield is y=8..183, so y=8+(y-64)/2.
            xn=max(0,min(255,(x-64)//2))
            yn=max(0,min(183,8+(y-64)//2))
            pp=param
            if typ==105: pp=max(0,min(255,(param-64)//2))  # stopping x
            elif typ==125: pp=0 if param==378 else 1      # upper/lower launcher
            elif typ in (300,301): pp=1 if param==653 else 0
            out+=bytes([step&255,(step>>8)&255,kind,xn,yn,min(255,max(1,hp)),pp&255])
            if typ==99: stone.append(param)
        out+=b'\xff\xff'
        return bytes(out),len(rec),stone,total_sep
    if n<=4:
        def col_for(sep): return min(scrollmax-1,max(0,sep//2))
    elif n==5:
        maxbase=max(1,total_sep//2)
        def col_for(sep): return min(scrollmax-1,round((sep/2)*scrollmax/maxbase))
    else:
        def col_for(sep): return 0
    for sep,typ,x,y,score,hp,param in rec:
        kind=spawn_kind(n,typ);col=col_for(sep);yn=max(20,min(176,y//2))
        speed=3 if kind in (3,9) else (1 if kind in (4,5,7,8,10,11) else 2)
        out+=bytes([col&255,(col>>8)&255,kind,yn,speed,param&255])
        if typ==99:stone.append(param)
    out+=b'\xff\xff\x00\x00\x00\x00'
    return bytes(out),len(rec),stone,total_sep

# ------------------------------------------------------------------ map renderer

def stage_tile_image(sheet,tid):
    if tid<=0:return Image.new('RGB',(8,8),(0,0,0))
    row,col=tid//10,tid%10
    if tid>299:
        row-=30;col+=11
        if tid>599:
            row-=30;col+=11
    return sheet.crop((col*16,row*16,col*16+16,row*16+16)).resize((8,8),Image.Resampling.NEAREST).convert('RGB')

def build_stage(n):
    cfile=FGEN/f'gen_stage{n}.c'; mp=parse_c_array(cfile,f'stage{n}_map_rom');attr=parse_c_array(cfile,f'stage{n}_attr')
    cols=len(mp)//22;rows=22;sheet=Image.open(FORIG/f'g_stg{5 if n==6 else n}.bmp').convert('RGB')
    encoded=[[] for _ in range(3)];freq=[Counter() for _ in range(3)];changes=0
    # collect source tiles and occurrences
    for c in range(cols):
        for r in range(rows):
            im=stage_tile_image(sheet,mp[c*rows+r]);p,co,ch,idxrows=encode_tile_rgb(im);changes+=ch;k=(p,co,idxrows);z=(1+r)//8
            encoded[z].append((c,r,k));freq[z][k]+=1
    # target leaves room for HUD text row (zone0) and 3 stone tiles (zone2)
    targets=[216 if n==4 else 230,255,250];reps=[];mapping=[]
    for z in range(3):
        keys=list(freq[z]);
        if len(keys)<=targets[z]:keep=keys
        else:keep=[k for k,_ in freq[z].most_common(targets[z])]
        idx={k:i for i,k in enumerate(keep)};mpmap={k:i for i,k in enumerate(keep)}
        if len(keys)>len(keep):
            for k in keys:
                if k in mpmap:continue
                best=min(range(len(keep)),key=lambda i:key_distance(k,keep[i]));mpmap[k]=best
        reps.append(keep);mapping.append(mpmap)
    names=bytearray(cols*rows)
    for z in range(3):
        for c,r,k in encoded[z]:names[r*cols+c]=mapping[z][k]
    # add HUD/pause/clear in zone0 using BASE07 stage1 validation HUD for consistent look
    val=Image.open(REF/'stage1_validation.png').convert('RGB');hud=val.crop((32,24,288,32))
    pause=font_textrow('PAUSE');clear=font_textrow(f'AREA {n} CLEAR')
    def add_row(z,im):
        row=bytearray(32)
        for tx in range(32):
            p,c,ch,rr=encode_tile_rgb(im.crop((tx*8,0,tx*8+8,8)));k=(p,c,rr)
            # exact insert if space, otherwise nearest rep
            if k not in mapping[z]:
                if len(reps[z])<256:
                    mapping[z][k]=len(reps[z]);reps[z].append(k)
                else:
                    mapping[z][k]=min(range(len(reps[z])),key=lambda i:key_distance(k,reps[z][i]))
            row[tx]=mapping[z][k]
        return bytes(row)
    hudrow=add_row(0,hud);pauserow=add_row(0,pause);clearrow=add_row(0,clear)
    gameoverrow=add_row(0,font_textrow('GAME OVER - PRESS FIRE'))
    # Exact font source already used by the static HUD/pause resources.
    # Reserve permanent tile indices for live numeric counters.
    digit_ids=bytes(add_row(0,font_textrow(str(n)))[15] for n in range(10))
    # 30-stone HUD tiles in zone2
    stones=Image.open(CAN/'hud_stones_native.png').convert('RGB');stone_ids=[]
    for sx in (0,8,16):
        p,c,ch,rr=encode_tile_rgb(stones.crop((sx,0,sx+8,8)));k=(p,c,rr)
        if k not in mapping[2]:
            if len(reps[2])<256:
                mapping[2][k]=len(reps[2]);reps[2].append(k)
            else:mapping[2][k]=min(range(len(reps[2])),key=lambda i:key_distance(k,reps[2][i]))
        stone_ids.append(mapping[2][k])
    stonerow=bytearray(32);stonerow[1:31]=bytes([stone_ids[0]])*30
    # World-1 Ocular Sentinel laser. FIX23 chr151..154 are 192x8 beams.
    # Preserve each 24-tile phase as SCREEN4 name rows for all three zones;
    # the runtime overlays these rows directly, avoiding the 8-sprites/scanline limit.
    laser_ids=[0,0,0]
    laser_rows=b''
    if n==1:
        ctab=json.load(open(REF/'chr_table.json'))['pats']
        gsrc=Image.open(REF/'g_chara0.bmp').convert('RGB')
        by_zone=[]
        for z in range(3):
            zrows=[]
            for cid in (151,152,153,154):
                ct=ctab[str(cid)]
                crop=gsrc.crop((ct['x'],ct['y'],ct['x']+ct['w'],ct['y']+ct['h']))
                native=crop.resize((ct['w']//2,ct['h']//2),Image.Resampling.NEAREST)
                row=bytearray()
                for x in range(0,192,8):
                    tile=native.crop((x,0,x+8,8))
                    p0,c0,ch0,rr=encode_tile_rgb(tile); k=(p0,c0,rr)
                    if k not in mapping[z]:
                        if len(reps[z])>=256: raise RuntimeError(f'stage1 laser zone {z} full')
                        mapping[z][k]=len(reps[z]); reps[z].append(k)
                    row.append(mapping[z][k])
                zrows.append(bytes(row))
            by_zone.append(zrows)
        laser_rows=b''.join(row for zrows in by_zone for row in zrows)
        laser_ids=[by_zone[z][0][0] for z in range(3)]
    # patterns/colors
    patt=[b''.join(k[0] for k in reps[z]) for z in range(3)];colsbin=[b''.join(k[1] for k in reps[z]) for z in range(3)]
    # collisions, row-major logical source
    coll=bytearray();offs=[]
    for r in range(rows):
        offs.append(len(coll));vals=[]
        for c in range(cols):
            tid=mp[c*rows+r];vals.append(attr[tid] if (0<=tid<len(attr)) else 0)
        i=0
        while i<cols:
            v=vals[i];j=i+1
            while j<cols and vals[j]==v and j-i<255:j+=1
            coll+=bytes([j-i,v]);i=j
        coll.append(0)
    offb=b''.join(struct.pack('<H',x) for x in offs)
    spawn,spawn_count,stone_params,total_sep=compact_spawn(n,SCROLL_MAX[n])
    # preview
    prev=Image.new('RGB',(256,192),(0,0,0));prev.paste(hud,(0,0))
    for r in range(22):
        for c in range(min(32,cols)):
            prev.paste(stage_tile_image(sheet,mp[c*22+r]),(c*8,8+r*8))
    empty=stones.crop((0,0,8,8))
    for i in range(30):prev.paste(empty,(8+i*8,184))
    prev.save(GEN/f'stage{n}_preview.png')
    return dict(stage=n,cols=cols,rows=rows,names=bytes(names),patt=patt,colors=colsbin,counts=[len(x) for x in reps],changes=changes,
                collision_offsets=offb,collision_rle=bytes(coll),spawn=spawn,spawn_count=spawn_count,stone_params=stone_params,total_sep=total_sep,
                hud=hudrow,pause=pauserow,clear=clearrow,gameover=gameoverrow,digits=digit_ids,stones=bytes(stonerow),stone_ids=stone_ids,laser_ids=laser_ids,laser_rows=laser_rows)

# ------------------------------------------------------------------ bank pack

def add_blob(bank,blob,align=1):
    while len(bank)%align:bank.append(0xFF)
    off=len(bank)
    if off+len(blob)>BANK_SIZE:raise RuntimeError(f'bank overflow {off}+{len(blob)}')
    bank.extend(blob);return 0x8000+off,len(blob)

def patch_word(buf,off,val):buf[off:off+2]=struct.pack('<H',val)

def build_gfx_bank(n,st):
    b=bytearray(b'VG'+bytes([n,1])+bytes(60))
    area=Image.open(FGFX/f'area{n}_original.png').convert('RGB');az,an,ach=pack_static_image(area)
    entries=[]
    for z in range(3):entries.append(add_blob(b,az[z][0]))
    for z in range(3):entries.append(add_blob(b,az[z][1]))
    entries.append(add_blob(b,an))
    for z in range(3):entries.append(add_blob(b,st['patt'][z]))
    for z in range(3):entries.append(add_blob(b,st['colors'][z]))
    # 13 ptr,len entries at offset 4
    o=4
    for ptr,ln in entries:
        patch_word(b,o,ptr);patch_word(b,o+2,ln);o+=4
    b.extend(b'\xff'*(BANK_SIZE-len(b)))
    return bytes(b),dict(area_changes=ach,size_used=BANK_SIZE-b.count(0xFF))

def build_data_banks(n,st):
    ba=bytearray(b'VD'+bytes([n,1])+bytes(60));bb=bytearray()
    # fixed metadata in A
    coll_off_ptr,_=add_blob(ba,st['collision_offsets'],2)
    coll_rle_ptr,_=add_blob(ba,st['collision_rle'])
    spawn_ptr,_=add_blob(ba,st['spawn'],2)
    hud_ptr,_=add_blob(ba,st['hud']);pause_ptr,_=add_blob(ba,st['pause']);clear_ptr,_=add_blob(ba,st['clear']);stones_ptr,_=add_blob(ba,st['stones'])
    # reserve row directory in A
    rowdir_off=len(ba);ba.extend(bytes(22*3));rowdir_ptr=0x8000+rowdir_off
    laser_ptr=0
    if n==1 and st.get('laser_rows'):
        laser_ptr,_=add_blob(ba,st['laser_rows'])
    rowdir=[]
    dataA=DATAA_BANKS[n];dataB=DATAB_BANKS[n]
    # pack each row contiguously; never cross a bank boundary
    for r in range(22):
        row=st['names'][r*st['cols']:(r+1)*st['cols']]
        if len(ba)+len(row)<=BANK_SIZE:
            ptr=0x8000+len(ba);bank=dataA;ba.extend(row)
        else:
            if len(bb)+len(row)>BANK_SIZE:raise RuntimeError(f'stage {n} row data overflow')
            ptr=0x8000+len(bb);bank=dataB;bb.extend(row)
        rowdir.append((bank,ptr))
    # patch row directory
    p=rowdir_off
    for bank,ptr in rowdir:
        ba[p]=bank;ba[p+1:p+3]=struct.pack('<H',ptr);p+=3
    # header
    patch_word(ba,4,st['cols']);patch_word(ba,6,SCROLL_MAX[n]);patch_word(ba,8,spawn_ptr);patch_word(ba,10,st['spawn_count'])
    patch_word(ba,12,coll_off_ptr);patch_word(ba,14,coll_rle_ptr);patch_word(ba,16,rowdir_ptr)
    patch_word(ba,18,hud_ptr);patch_word(ba,20,pause_ptr);patch_word(ba,22,clear_ptr);patch_word(ba,24,stones_ptr)
    ba[26]=st['stone_ids'][0];ba[27]=st['stone_ids'][1];ba[28]=st['stone_ids'][2]
    sx,sy=START_POS[n];ba[29]=sx;ba[30]=sy;ba[31]=BOSS_HP[n];ba[32]=dataA;ba[33]=dataB
    patch_word(ba,34,laser_ptr)
    ba[36:46]=st['digits']
    gameover_ptr,_=add_blob(ba,st['gameover'])
    patch_word(ba,46,gameover_ptr)
    ba.extend(b'\xff'*(BANK_SIZE-len(ba)));bb.extend(b'\xff'*(BANK_SIZE-len(bb)))
    return bytes(ba),bytes(bb),dict(rowdir=rowdir,dataA_used=next((i for i in range(BANK_SIZE-1,-1,-1) if ba[i]!=0xff),-1)+1,dataB_used=next((i for i in range(BANK_SIZE-1,-1,-1) if bb[i]!=0xff),-1)+1)

# ------------------------------------------------------------------ common bank from BASE07 generated assets

def build_common_bank():
    b=bytearray(b'VC'+bytes([8,1])+bytes(60));const=[]
    def put(name,fn,align=1):
        data=(GEN/fn).read_bytes();ptr,ln=add_blob(b,data,align);const.append((name,ptr,ln));return ptr,ln
    # title
    for z in range(3):put(f'TITLE_Z{z}',f'title_z{z}_patterns.bin')
    for z in range(3):put(f'TITLE_C{z}',f'title_z{z}_colors.bin')
    put('TITLE_NAMES','title_names.bin')
    # prologue
    for z in range(3):put(f'INTRO_Z{z}',f'intro_z{z}_patterns.bin')
    for z in range(3):put(f'INTRO_C{z}',f'intro_z{z}_colors.bin')
    for i in range(10):put(f'INTRO_NAMES_{i}',f'intro_names_{i}.lz')
    # common sprites/colors
    put('SPRITE_PATTERNS','sprite_patterns.bin')
    put('INTRO_SPRITE_COLORS','intro_sprite_colors.bin')
    put('GAME_ESCORT_COLORS','game_escort_sprite_colors.bin')
    put('GAME_SENTINEL_COLORS','game_sentinel_sprite_colors.bin')
    # ending static: earth card + two text lines overlaid
    end=Image.open(FGFX/'area_earth_original.png').convert('RGB')
    # reuse original font overlay
    def overlay(text,ty):
        row=font_textrow(text);end.paste(row,(0,ty*8))
    overlay('MISSION COMPLETE',18);overlay('THANK YOU',20)
    ez,en,ech=pack_static_image(end)
    for z in range(3):
        ptr,ln=add_blob(b,ez[z][0]);const.append((f'ENDING_Z{z}',ptr,ln))
    for z in range(3):
        ptr,ln=add_blob(b,ez[z][1]);const.append((f'ENDING_C{z}',ptr,ln))
    ptr,ln=add_blob(b,en);const.append(('ENDING_NAMES',ptr,ln))
    if len(b)>BANK_SIZE:raise RuntimeError(f'common bank overflow {len(b)}')
    b.extend(b'\xff'*(BANK_SIZE-len(b)))
    lines=[f'COMMON_BANK equ {COMMON_BANK}']
    for name,ptr,ln in const:
        lines.append(f'{name}_PTR equ 0x{ptr:04X}')
        lines.append(f'{name}_BYTES equ {ln}')
    return bytes(b),'\n'.join(lines)+'\n',dict(ending_changes=ech,used=next((i for i in range(BANK_SIZE-1,-1,-1) if b[i]!=0xff),-1)+1)

# ------------------------------------------------------------------ run
# First run BASE07 packer (caller does this) so common generated files exist.
stages={n:build_stage(n) for n in range(1,7)}
common,common_const,common_meta=build_common_bank();(GEN/'bank01_common.bin').write_bytes(common)
const_lines=[common_const,'GFX_HDR equ 0x8000','DATA_HDR equ 0x8000']
manifest={'authority_fix23_source_sha256':'34c3b072fb4cba933fe12e1f0f60f14a76e73b86626847d193fe1ec1c50b6aab','mapper':'ASCII16','rom_banks_16k':32,'common':common_meta,'stages':{}}
for n,st in stages.items():
    gb,gmeta=build_gfx_bank(n,st);da,db,dmeta=build_data_banks(n,st)
    (GEN/f'bank{GFX_BANKS[n]:02d}_stage{n}_gfx.bin').write_bytes(gb)
    (GEN/f'bank{DATAA_BANKS[n]:02d}_stage{n}_dataA.bin').write_bytes(da)
    (GEN/f'bank{DATAB_BANKS[n]:02d}_stage{n}_dataB.bin').write_bytes(db)
    const_lines += [f'STAGE{n}_GFX_BANK equ {GFX_BANKS[n]}',f'STAGE{n}_DATA_BANK equ {DATAA_BANKS[n]}',f'STAGE{n}_DATAB_BANK equ {DATAB_BANKS[n]}']
    if n==1:
        const_lines += [f'STAGE1_LASER_TILE_Z0 equ {st["laser_ids"][0]}',f'STAGE1_LASER_TILE_Z1 equ {st["laser_ids"][1]}',f'STAGE1_LASER_TILE_Z2 equ {st["laser_ids"][2]}']
    manifest['stages'][str(n)]={'cols':st['cols'],'scroll_max':SCROLL_MAX[n],'tiles_by_zone':st['counts'],'screen4_quantized_pixels':st['changes'],'spawn_count':st['spawn_count'],'stone_params':st['stone_params'],'script_separators':st['total_sep'],'gfx':gmeta,'data':dmeta}
# Common sprite constant indices from BASE07 constants.inc must stay available to engine.
baseconst=(GEN/'constants.inc').read_text()
# retain only SPR_* and relevant intro sizes generated by BASE07; overwrite dynamic stage constants.
keep=[]
for line in baseconst.splitlines():
    if line.startswith('SPR_') or line.startswith('INTRO_NAME') or line.startswith('GAME_') or line.startswith('INTRO_SPRITE'):
        keep.append(line)
# Title/intro sizes come from common generated constants too, but pointers are new.
for line in baseconst.splitlines():
    if re.match(r'^(TITLE_Z\d_BYTES|INTRO_Z\d_BYTES)\s',line):keep.append(line)
const_lines.append('\n'.join(keep)+'\n')
(GEN/'full_constants.inc').write_text('\n'.join(const_lines)+'\n')
(GEN/'full_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
# preview montage
canvas=Image.new('RGB',(512,576),(16,16,16))
for n in range(1,7):
    im=Image.open(GEN/f'stage{n}_preview.png').convert('RGB');x=((n-1)%2)*256;y=((n-1)//2)*192;canvas.paste(im,(x,y))
canvas.save(GEN/'FULL_GAME_6_STAGE_PREVIEW.png')
print(json.dumps(manifest,indent=2))
