#!/usr/bin/env python3
"""VOLCABAMBA_MSX2_TURBOR_HYBRID - automatic emulator tests (openMSX + C-BIOS).

Not part of the ROM build. Runs the ROM produced by ./build.sh on the free
C-BIOS machines of openMSX and writes validation/EMULATOR_REPORT.json.

  python3 tools/emu/run_emu_tests.py            # all tests
  python3 tools/emu/run_emu_tests.py --quick    # boot tests only

Requirements: openmsx in PATH (or OPENMSX=/path/to/openmsx) with the C-BIOS
machines installed (bundled with openMSX on macOS; Debian/Ubuntu: openmsx cbios).
On a Linux box without display, xvfb-run is used automatically.

C-BIOS has no turboR machine: the turboR branch of BOOT is exercised by a
test harness that answers MSXVER=3 and emulates CHGCPU/GETCPU through
breakpoints (it does not emulate the R800 itself).
"""
from pathlib import Path
import json, os, shutil, subprocess, sys, tempfile, time

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'out'; VAL = ROOT / 'validation'
ROM = OUT / 'VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom'

def syms(name):
    d = {}
    for line in (OUT / name).read_text().splitlines():
        k, _, v = line.split()
        d[k] = int(v, 16)
    return d

SZ, SR, SB = syms('engine_z80.sym'), syms('engine_r800.sym'), syms('boot.sym')
RAM = {k: SZ[k] for k in ('scroll_col', 'en_base', 'hyb_base', 'mid_active', 'boss_active', 'current_stage')}

def openmsx_cmd():
    exe = os.environ.get('OPENMSX') or shutil.which('openmsx')
    if not exe:
        mac = '/Applications/openMSX.app/Contents/MacOS/openmsx'
        exe = mac if Path(mac).exists() else None
    if not exe:
        raise SystemExit('openmsx not found (set OPENMSX=/path/to/openmsx)')
    cmd = [exe]
    if sys.platform.startswith('linux') and not os.environ.get('DISPLAY') and shutil.which('xvfb-run'):
        cmd = ['xvfb-run', '-a'] + cmd
    return cmd

PROLOGUE = 'set throttle off\nset maxframeskip 0\n'
START = '''after time 7 {keymatrixdown 8 1}
after time 7.3 {keymatrixup 8 1}
'''
HOLD_PLAY = 'keymatrixdown 3 1\nkeymatrixdown 5 0x80\n'   # C (invincible) + Z (fire)
FORCE_R = 'keymatrixdown 4 0x80\nafter time 7 {keymatrixup 4 0x80}\n'
DUMP_HYB = '''proc dump_hyb {path} {
  set f [open $path w]
  for {set i 0} {$i < 19} {incr i} { puts -nonewline $f [format "%02X" [debug read memory [expr {@HYB@+$i}]]] }
  puts $f ""
  puts $f [format %c [debug read memory 0x4002]]
  close $f }
'''.replace('@HYB@', str(RAM['hyb_base']))

def run(machine, tcl, timeout=900):
    with tempfile.TemporaryDirectory() as td:
        script = Path(td) / 'test.tcl'
        script.write_text(PROLOGUE + tcl.replace('@TMP@', td))
        cmd = openmsx_cmd() + ['-machine', machine, '-cart', str(ROM), '-romtype', 'ASCII16', '-script', str(script)]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=timeout)
        return {p.name: p.read_text() for p in Path(td).iterdir() if p.suffix == '.txt'}

def hyb_fields(txt):
    hexs, kind = txt.split()
    b = bytes.fromhex(hexs)
    return {'magic': b[0:4].decode('latin-1'), 'msxver': b[4], 'vdp_id': b[5], 'cpu': b[6],
            'engine': chr(b[7]), 'force': b[8], 'cfg': b[9], 'page1_kind': kind}

results = {}
def check(name, ok, **info):
    results[name] = {'pass': bool(ok), **info}
    print(f"{'PASS' if ok else 'FAIL'}  {name}  {json.dumps(info)}", flush=True)

# ---------------------------------------------------------------- boot tests
def t_msx1():
    r = run('C-BIOS_MSX1', 'after time 15 {set f [open @TMP@/screen.txt w]; puts $f [get_screen]; close $f; exit}\n')
    scr = r.get('screen.txt', '')
    check('boot_msx1_notice', 'MSX2 OR HIGHER REQUIRED' in scr, screen=' | '.join(l.strip() for l in scr.splitlines() if l.strip()))

def t_boot(machine, name, pre='', expect=None):
    r = run(machine, pre + DUMP_HYB + START + 'after time 12 {dump_hyb @TMP@/hyb.txt; exit}\n')
    h = hyb_fields(r['hyb.txt'])
    ok = all(h[k] == v for k, v in expect.items())
    check(name, ok, **h)

def fake_turbor_tcl():
    b = (OUT / 'bank00_boot.bin').read_bytes()
    def after(pat):
        out, i = [], b.find(pat)
        while i >= 0:
            out.append(0x4000 + i + len(pat)); i = b.find(pat, i + 1)
        return out
    t = 'set ::cpu 0\nset ::log {}\nproc fake_ret {} { reg pc [peek16 [reg sp]]; reg sp [expr {[reg sp]+2}] }\n'
    cond = '{[debug read memory 0x4000] == 0x41}'          # BOOT bank mapped ("AB")
    for a in after(bytes([0x3A, 0x2D, 0x00])):            # ld a,(MSXVER)
        t += f'debug set_bp 0x{a:04X} {cond} {{reg a 3}}\n'
    for a in after(bytes([0x3A, 0x80, 0x01])) + after(bytes([0x3A, 0x83, 0x01])):
        t += f'debug set_bp 0x{a:04X} {cond} {{reg a 0xC3}}\n'
    t += 'debug set_bp 0x0180 {} {lappend ::log [format CHGCPU_%02X [reg a]]; set ::cpu [expr {[reg a] & 3}]; fake_ret}\n'
    t += 'debug set_bp 0x0183 {} {lappend ::log GETCPU; reg a $::cpu; fake_ret}\n'
    return t

def t_fake_turbor():
    tcl = fake_turbor_tcl() + DUMP_HYB + START + 'after time 12 {dump_hyb @TMP@/hyb.txt; set f [open @TMP@/log.txt w]; puts $f $::log; close $f; exit}\n'
    r = run('C-BIOS_MSX2+', tcl)
    h = hyb_fields(r['hyb.txt'])
    log = r.get('log.txt', '').split()
    check('boot_turbor_branch_harness', h['msxver'] == 3 and h['engine'] == 'R' and h['cpu'] == 2
          and h['page1_kind'] == 'R' and log[:1] == ['CHGCPU_82'], calls=log, **h)

# ---------------------------------------------------- speed + determinism
def stage1_tcl(s, trace):
    t = HOLD_PLAY + START + 'set ::n 0\nset ::sec 0\nset ::rate {}\n'
    if trace:
        t += f'''set ::tf [open @TMP@/trace.txt w]
proc tr {{}} {{
  set s ""
  foreach {{a l}} {{0xC000 0x20 0xC050 0x8A 0xC200 0x196}} {{ for {{set i 0}} {{$i < $l}} {{incr i}} {{ append s [format %02X [debug read memory [expr {{$a+$i}}]]] }} }}
  puts $::tf $s }}
'''
    t += f'debug set_bp 0x{s["game_tick"]:04X} {{}} {{incr ::n{"; tr" if trace else ""}}}\n'
    t += f'''proc sec {{t}} {{ lappend ::rate $::n; set ::n 0 }}
for {{set t 14}} {{$t < 260}} {{incr t}} {{ after time $t "sec $t" }}
after time 260 {{ set f [open @TMP@/rate.txt w]; puts $f $::rate; close $f; {"close $::tf;" if trace else ""} exit }}
'''
    return t

SCRATCH = ({0xC014, 0xC015, 0xC01B, 0xC01C, 0xC01D, 0xC01E} | set(range(0xC024, 0xC030)) |
           set(range(0xC395, 0xC3A1)) - {0xC397, 0xC398, 0xC399} | set(range(0xC0D0, 0xC0D7)) | {0xC0B7})
RANGES = [(0xC000, 0x20), (0xC050, 0x8A), (0xC200, 0x196)]
ADDRS = [a + i for a, l in RANGES for i in range(l)]

def rate_summary(r):
    rates = [int(x) for x in r['rate.txt'].split()]
    active = [x for x in rates[1:] if x > 0]
    clear = next((i for i, x in enumerate(rates[1:], 1) if x == 0), None)
    full = active[:-1] if clear else active
    return {'ticks_per_s_avg': round(sum(full) / len(full), 2), 'ticks_per_s_min': min(full),
            'stage1_cleared': clear is not None, 'seconds_below_31': sum(1 for x in full if x < 31)}

def t_stage1():
    rz = run('C-BIOS_MSX2', stage1_tcl(SZ, True))
    rr = run('C-BIOS_MSX2', FORCE_R + stage1_tcl(SR, True))
    for name, r in (('speed_stage1_z80_engine', rz), ('speed_stage1_r800_engine_on_z80', rr)):
        s = rate_summary(r)
        check(name, s['stage1_cleared'] and s['ticks_per_s_avg'] >= 32.5, **s)
    tz, trr = rz['trace.txt'].split(), rr['trace.txt'].split()
    diff = None
    for n, (a, b) in enumerate(zip(tz, trr)):
        if a != b:
            bad = [hex(ADDRS[i // 2]) for i in range(0, len(a), 2) if a[i:i+2] != b[i:i+2] and ADDRS[i // 2] not in SCRATCH]
            if bad: diff = (n, bad[:8]); break
    check('determinism_z80_vs_r800_engine', diff is None and len(tz) == len(trr) and len(tz) > 5000,
          ticks=len(tz), first_difference=diff)

if __name__ == '__main__':
    if not ROM.exists(): raise SystemExit('run ./build.sh first')
    t0 = time.time()
    t_msx1()
    t_boot('C-BIOS_MSX2', 'boot_msx2_z80_engine', expect={'magic': 'VHYB', 'msxver': 1, 'vdp_id': 0, 'engine': 'Z', 'page1_kind': 'Z', 'cfg': 1})
    t_boot('C-BIOS_MSX2+', 'boot_msx2plus_z80_engine', expect={'magic': 'VHYB', 'msxver': 2, 'vdp_id': 2, 'engine': 'Z', 'page1_kind': 'Z'})
    t_boot('C-BIOS_MSX2', 'boot_override_R_engine', pre=FORCE_R, expect={'engine': 'R', 'page1_kind': 'R', 'force': 0x52})
    t_boot('C-BIOS_MSX2+', 'boot_override_F_faithful', pre='keymatrixdown 3 0x08\n' + FORCE_R + 'after time 7 {keymatrixup 3 0x08}\n',
           expect={'engine': 'R', 'cfg': 0})
    t_fake_turbor()
    if '--quick' not in sys.argv:
        t_stage1()
    VAL.mkdir(exist_ok=True)
    rep = {'rom': ROM.name, 'all_pass': all(v['pass'] for v in results.values()),
           'seconds': round(time.time() - t0), 'tests': results}
    (VAL / 'EMULATOR_REPORT.json').write_text(json.dumps(rep, indent=2) + '\n')
    print('ALL PASS' if rep['all_pass'] else 'SOME TESTS FAILED')
    sys.exit(0 if rep['all_pass'] else 1)
