#!/usr/bin/env python3
"""Link VOLCABAMBA_MSX2_TURBOR_HYBRID: BOOT + shared data banks + two engines.

Every input is produced by this build from SOURCE (assembler / converters).
No previous ROM or BIN is read, patched or used as a base.
"""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1];GEN=ROOT/'generated';OUT=ROOT/'out'
BANK=0x4000; NBANKS=32
ENGINE_Z80_BANK=20; ENGINE_R800_BANK=21
if len(sys.argv) not in (5,6) or (len(sys.argv)==6 and sys.argv[5]!='--turbor-only'):
    raise SystemExit('usage: build_rom.py boot.bin engine_z80.bin engine_r800.bin out.rom [--turbor-only]')
boot,ez,er=(Path(a).read_bytes() for a in sys.argv[1:4])
for name,b in (('boot',boot),('engine_z80',ez),('engine_r800',er)):
    if len(b)!=BANK: raise SystemExit(f'{name} must be {BANK} bytes, got {len(b)}')
banks=[bytearray(b'\xff'*BANK) for _ in range(NBANKS)]
banks[0][:]=boot
banks[1][:]=(GEN/'bank01_common.bin').read_bytes()
for n in range(1,7):
    gfx=2+(n-1)*3;da=gfx+1;db=gfx+2
    banks[gfx][:]=(GEN/f'bank{gfx:02d}_stage{n}_gfx.bin').read_bytes()
    banks[da][:]=(GEN/f'bank{da:02d}_stage{n}_dataA.bin').read_bytes()
    banks[db][:]=(GEN/f'bank{db:02d}_stage{n}_dataB.bin').read_bytes()
if len(sys.argv)==5: banks[ENGINE_Z80_BANK][:]=ez # turboR-only bank 20 intentionally blank
banks[ENGINE_R800_BANK][:]=er
out=b''.join(bytes(x) for x in banks)
Path(sys.argv[4]).write_bytes(out)
print(f'wrote {sys.argv[4]} {len(out)} bytes / {NBANKS} ASCII16 banks '
      f'(boot=0, shared=1..19, engine_z80={ENGINE_Z80_BANK if len(sys.argv)==5 else chr(45)}, engine_r800={ENGINE_R800_BANK})')
