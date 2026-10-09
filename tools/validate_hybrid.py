#!/usr/bin/env python3
"""Static validation of VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom (run by build.sh).

Checks the ROM produced from SOURCE by this build: bank layout, BOOT header and
messages, both engine modules (signature/ABI/entry/size), that the shared data
banks are exactly the converter output, the Stage-1 data contract inherited
from BASE12, and source audit markers.  Gameplay is validated separately with
tools/emu/run_emu_tests.py (openMSX + C-BIOS).
"""
from pathlib import Path
import hashlib, json, struct, sys

ROOT = Path(__file__).resolve().parents[1]
GEN = ROOT / 'generated'; OUT = ROOT / 'out'; VAL = ROOT / 'validation'; VAL.mkdir(exist_ok=True)
rom = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT / 'VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom'
data = rom.read_bytes()
B = 0x4000
def bank(n): return data[n * B:(n + 1) * B]
checks = []
def ok(cond, what):
    if not cond: raise SystemExit(f'VALIDATION FAIL: {what}')
    checks.append(what)

ok(len(data) == 32 * B, 'ROM is 512 KiB = 32 ASCII16 banks')

# ---- BOOT (bank 0) -------------------------------------------------------
b0 = bank(0)
ok(b0[:2] == b'AB', 'bank 0 has the MSX cartridge header')
init = struct.unpack_from('<H', b0, 2)[0]
ok(0x4010 <= init < 0x8000 and b0[init - 0x4000] == 0xF3, 'BOOT init address is inside bank 0 and starts with DI')
ok(b'MSX2 OR HIGHER REQUIRED' in b0, 'BOOT contains the MSX1 notice')
ok(b'\x32\x00\x60' in b0, 'BOOT selects the engine bank through 6000h (trampoline)')
ok(b'\xCD\x80\x01' in b0, 'BOOT calls CHGCPU (0180h) on turboR')
ok(b'\xCD\x83\x01' in b0, 'BOOT calls GETCPU (0183h) on turboR')
ok(b'\x3A\x2D\x00' in b0, 'BOOT reads MSXVER (002Dh)')

# ---- engines ---------------------------------------------------------------
eng = {}
for n, kind in ((20, b'Z'), (21, b'R')):
    e = bank(n)
    ok(e[0:2] == b'VE' and e[2:3] == kind and e[3] == 1, f'bank {n}: engine signature VE{kind.decode()} ABI 1')
    size = struct.unpack_from('<H', e, 4)[0]
    ok(0x1000 < size <= B and all(x == 0xFF for x in e[size:]), f'bank {n}: engine size {size} bytes, rest 0xFF')
    ok(e[0x10] == 0xF3, f'bank {n}: entry 4010h starts with DI')
    ok(b'\x32\x00\x70' in e, f'bank {n}: engine maps data banks through 7000h')
    ok(b'\x32\x00\x60' not in e, f'bank {n}: engine never switches page 1 (its own bank)')
    ok(e == (OUT / f'bank{n:02d}_engine_{"z80" if kind == b"Z" else "r800"}.bin').read_bytes(), f'bank {n}: identical to assembler output')
    eng[kind.decode()] = {'bank': n, 'bytes': size, 'free': B - size}
ok(bank(20) != bank(21), 'Z80 and R800 engine modules differ (TURBO conditional code)')

# ---- shared data banks -----------------------------------------------------
ok(bank(1) == (GEN / 'bank01_common.bin').read_bytes() and bank(1)[:2] == b'VC', 'bank 1 = shared COMMON data')
for n in range(1, 7):
    g = 2 + (n - 1) * 3
    for off, tag, name in ((0, b'VG', 'gfx'), (1, b'VD', 'dataA'), (2, b'', 'dataB')):
        f = GEN / f'bank{g + off:02d}_stage{n}_{name}.bin'
        ok(bank(g + off) == f.read_bytes(), f'bank {g + off} = shared stage {n} {name}')
        if tag: ok(bank(g + off)[:2] == tag, f'bank {g + off} magic {tag.decode()}')
ok(all(all(x == 0xFF for x in bank(n)) for n in range(22, 32)), 'banks 22..31 free (0xFF)')

# ---- Stage-1 data contract (inherited from BASE12 validate_full.py) --------
manifest = json.loads((GEN / 'full_manifest.json').read_text())
expected = {1: 184, 2: 126, 3: 145, 4: 165, 5: 210, 6: 0}
stones = []
for n in range(1, 7):
    s = manifest['stages'][str(n)]
    ok(s['spawn_count'] == expected[n], f'stage {n}: {expected[n]} script spawns')
    stones += s['stone_params']
ok(sorted(stones) == list(range(30)), '30 Volca-Stones, ids 0..29')
b3 = bank(3)
sp = struct.unpack_from('<H', b3, 8)[0] - 0x8000
recs = []; o = sp
while b3[o:o + 2] != b'\xff\xff':
    recs.append((struct.unpack_from('<H', b3, o)[0],) + tuple(b3[o + 2:o + 7])); o += 7
ok(len(recs) == 184, 'Stage 1 script: 184 FIX23 records')
ok([r[1] for r in recs[:8]] == [3] * 8 and [r[0] for r in recs[:8]] == [36, 38, 40, 42, 44, 46, 48, 50], 'Stage 1 first wave schedule')
ok(len([r for r in recs if r[1] == 13]) == 6, 'Stage 1: six hidden ID99 stone triggers')
laser = struct.unpack_from('<H', b3, 34)[0]
ok(0x8000 <= laser < 0xC000, 'Stage 1 Sentinel laser rows present')

# ---- source audit ----------------------------------------------------------
asm = (ROOT / 'src/engine/engine.asm').read_text()
for marker in ('EN_COUNT       equ 40', 'BUL_COUNT      equ 20', 'SHOT_COUNT     equ 6',
               'spawn_find_free40', 'shot_hits_map_exact', 'update_midboss2', 'boss_death_events',
               'sched_frames', 'colwin_fill', 'render_enemy_list', 'render_bullet_list',
               'layout_table_r800', 'update_records', 'HYB_REC_STAGE'):
    ok(marker in asm, f'engine source marker: {marker}')
ok('call mid_laser_tick' in asm and asm.count('call mid_laser_tick') == 2, 'Sentinel laser advanced once per tick (game_tick alive/death paths only)')
boot = (ROOT / 'src/boot/boot.asm').read_text()
for marker in ('boot_msx1', 'CHGCPU', 'GETCPU', 'HYB_TRAMP', 'ENGINE_R800_BANK', 'ENGINE_Z80_BANK'):
    ok(marker in boot, f'boot source marker: {marker}')

sha = hashlib.sha256(data).hexdigest()
report = {'status': 'PASS', 'rom': rom.name, 'bytes': len(data), 'sha256': sha, 'mapper': 'ASCII16',
          'layout': {'boot': 0, 'shared_data': '1..19', 'engine_z80': 20, 'engine_r800': 21, 'free': '22..31'},
          'engines': eng, 'checks': len(checks), 'check_list': checks,
          'note': 'static/build validation; gameplay is validated by tools/emu/run_emu_tests.py'}
(VAL / 'HYBRID_VALIDATION.json').write_text(json.dumps(report, indent=2) + '\n')
(VAL / 'SHA256SUMS.txt').write_text(f'{sha}  {rom.name}\n')
print(f'VALIDATION PASS: {len(checks)} checks')
print(f'SHA-256 {sha}  {rom.name}')
print(f'engine Z80 : bank 20, {eng["Z"]["bytes"]} bytes ({eng["Z"]["free"]} free)')
print(f'engine R800: bank 21, {eng["R"]["bytes"]} bytes ({eng["R"]["free"]} free)')
