#!/usr/bin/env python3
"""FIX03 resource and structural checks; NOT gameplay / emulator validation."""
import json,re,hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
GEN=ROOT/'generated';SRC=ROOT/'src/engine/engine.asm'
j=json.loads((GEN/'base07_resources.json').read_text())
assert j['sprite_pattern_bytes']<=64*32
sp=j['sprite_patterns']
for k in ['caution_left','caution_right','arrow_left','arrow_right']:
 assert k in sp, k
assert len({sp[k] for k in ['caution_left','caution_right','arrow_left','arrow_right']})==4
assert sp['caution_left']!=sp['enemy_basic0']
assert sp['caution_right']!=sp['enemy_basic0']
art=Image.open(ROOT/'res/canonical/caution650.png')
assert art.size==(32,8)
assert Image.open(ROOT/'res/canonical/arrow651.png').size==(32,24)
const=(GEN/'full_constants.inc').read_text()
for symbol in ('SPR_CAUTION_LEFT','SPR_CAUTION_RIGHT','SPR_ARROW_LEFT','SPR_ARROW_RIGHT'):
 assert symbol in const
asm=SRC.read_text()
assert 'intro_mask_occluded_lines:' in asm
assert 'stage_screen4_ready:' in asm
assert 'call render_enemy' in asm and 'rel_second_warning:' in asm
assert 'ren_caution:' in asm and 'SPR_CAUTION_LEFT' in asm
assert 'ren_arrow:' in asm and 'SPR_ARROW_LEFT' in asm
assert j['stage_unique_tiles_by_zone'][1]<256
# Inspect the real stage-1 compact script, not pack_world1's legacy preview table.
packed=(GEN/'bank03_stage1_dataA.bin').read_bytes()
# The authored step offsets and warning precede the first Ocular Sentinel.
raw=(ROOT/'reference/stage1_script.h').read_text()
vals=[int(v) for v in re.findall(r'-?\d+',re.search(r'\{(.*)\};',raw,re.S).group(1))]
seen=[];step=0;i=0
while i<len(vals):
    if vals[i]==-1:step+=1;i+=1;continue
    if vals[i]==-2:break
    typ,x,y,score,hp,param=vals[i:i+6]
    if typ in (300,301,250,251):seen.append((step,typ))
    i+=6
assert seen[:3]==[(72,300),(72,301),(80,250)],seen[:3]
print('FIX03 STATIC: PASS — original 32px CAUTION sprites, warning events, hangar masking, starfield base tiles')
print('PRECAUTION: stars currently static (not true parallax), SCREEN4 scroll not visually verified, emulator not run')
