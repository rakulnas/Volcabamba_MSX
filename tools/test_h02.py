#!/usr/bin/env python3
"""Static sanity/parity checks for native H02. Does not emulate MSX gameplay."""
from pathlib import Path
import hashlib, json, re, sys

root=Path(__file__).resolve().parents[1]
rom_path=Path(sys.argv[1]) if len(sys.argv)>1 else root/'out/VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom'
rom=rom_path.read_bytes()
assert len(rom)==524288 and rom[:2]==b'AB', 'Invalid MSX/ASCII16 cartridge ROM'
assert rom[20*16384:20*16384+2]==b'VE'
assert rom[21*16384:21*16384+2]==b'VE'
assert rom[20*16384+2:20*16384+4]==b'Z\x01'
assert rom[21*16384+2:21*16384+4]==b'R\x01'
assert rom[22*16384:]==b'\xff'*(10*16384), 'Unexpected ROM data in unused banks'

src=(root/'src/engine/engine.asm').read_text()
assert '    xor a\n    ld hl,EN_BASE\n    ld de,EN_BASE+1\n    ld bc,279' in src, 'Boss enemy pool zero-fill missing'
assert 'death_stage_start:' in src and 'ld a,(START_X_RAM)' in src, 'Later-stage spawn fix missing'
assert 'call scroll_fine_apply' in src and 'scroll_fine_v9958:' in src
assert 'call WRTVDP' in src
assert src.count('call mid_laser_tick')==2
assert 'call update_scroll' in src and 'call escort_events' in src

# A genuine pixel camera: 1..7 subpixels must yield -1..-7 displacement.
# R#18 shifts a V9938 display left; on V9958: coarse=1 left 8px,
# fine=(8-phase) shifts right 7..1px.
phases=[]
for phase in range(8):
    coarse=0 if phase==0 else 1
    fine=0 if phase==0 else 8-phase
    effective=(-coarse*8+fine)
    assert effective==-phase, (phase,effective)
    phases.append({'subpixel':phase,'v9938_r18_H':phase,'v9958_r26':coarse,'v9958_r27':fine,'screen_delta_px':effective})

sha=lambda b: hashlib.sha256(b).hexdigest()
asset_sha=[sha(rom[i*16384:(i+1)*16384]) for i in range(1,20)]
report={'result':'PASS STATIC ONLY','rom':str(rom_path.name),'sha256':sha(rom),
        'banks':32,'used_asset_banks':19,'shared_asset_sha256':asset_sha,
        'scroll_phase_model':phases,
        'limitations':['No V9938 border/HUD visual test','No V9958 edge wrap visual test',
                       'No MSX2/turboR gameplay/hardware timing test',
                       'Stages 2-6 remain alpha, not demonstrated parity']}
(root/'validation/H02_PARITY.json').write_text(json.dumps(report,indent=2)+'\n')
print('H02 STATIC/PARITY PASS: 32 banks, 19 shared asset banks, 8 scroll phases, boss/respawn invariants')
print('ROM SHA256:',sha(rom))
