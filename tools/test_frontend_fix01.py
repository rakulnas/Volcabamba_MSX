#!/usr/bin/env python3
"""H02_FIX01 structural regressions. No claim to emulate MSX gameplay."""
from pathlib import Path
import json, struct
root=Path(__file__).resolve().parents[1]
rom=(root/'out/VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom').read_bytes()
asm=(root/'src/engine/engine.asm').read_text()
pack=(root/'tools/pack_full_game.py').read_text()
assert len(rom)==524288
checks=0
for stage in range(1,7):
 gfx=rom[(2+(stage-1)*3)*16384:(3+(stage-1)*3)*16384]
 data=rom[(3+(stage-1)*3)*16384:(4+(stage-1)*3)*16384]
 ids=list(data[36:46]); assert len(ids)==10 and len(set(ids))==10, (stage,ids)
 ptr,plen=struct.unpack_from('<HH',gfx,32)
 patterns=gfx[ptr-0x8000:ptr-0x8000+plen]
 glyphs=[patterns[i*8:i*8+8] for i in ids]
 assert len(set(glyphs))==10 and all(len(g)==8 for g in glyphs),stage
 assert all(any(b for b in g) for g in glyphs), stage
 goptr=struct.unpack_from('<H',data,46)[0]
 assert 0x8000<=goptr<0xC000 and len(data[goptr-0x8000:goptr-0x8000+32])==32
 checks+=4
for t in ['ld (INTRO_X),a','ld (INTRO_Y),a','intro_fr_depart7:','ld hl,DATA_HDR+36',
          'hud_draw:', 'call hud_draw_7', 'ld a,(LIVES)', 'call score_add_enemy',
          'call score_add_1000', 'call score_check_extend', 'call reset_run_state',
          'game_over_wait:', 'jp stage_loop']:
 assert t in asm,t
 checks+=1
assert "gameoverrow=add_row(0,font_textrow('GAME OVER - PRESS FIRE'))" in pack
checks+=1
# Engine code may change; bank contract and original RGB graphics remain source-built.
for bank in (20,21):assert rom[bank*16384:bank*16384+2]==b'VE'
checks+=2
print(f'FRONTEND H02_FIX01 STATIC PASS: {checks} assertions: numeric glyphs/metadata in all 6 stages, lives/game over/score hooks, 2 engines')
