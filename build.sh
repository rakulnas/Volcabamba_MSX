#!/bin/sh
# VOLCABAMBA_MSX2_TURBOR_HYBRID - full clean build from SOURCE.
# SOURCE -> resource converters -> Z80 assembler (boot + 2 engines) -> ASCII16 link -> validate
set -eu
cd "$(dirname "$0")"
SMOOTH_SCROLL=${SMOOTH_SCROLL:-0} # safe default: keep HUD fixed in SCREEN4
ROM=out/VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom
ROM_T=out/VOLCABAMBA_MSX_TURBOR_ONLY_H02.rom
rm -rf out validation generated
mkdir -p out validation generated
python3 tools/pack_world1.py >/dev/null 2>validation/PACK_WARNINGS.log
python3 tools/pack_full_game.py > validation/PACK_REPORT.json 2>>validation/PACK_WARNINGS.log
python3 tools/z80mini.py -D TURBOR_ONLY=0 --sym out/boot.sym src/boot/boot.asm out/bank00_boot.bin > validation/ASSEMBLY.log
python3 tools/z80mini.py -D TURBO=0 -D SMOOTH=$SMOOTH_SCROLL --sym out/engine_z80.sym src/engine/engine.asm out/bank20_engine_z80.bin >> validation/ASSEMBLY.log
python3 tools/z80mini.py -D TURBO=1 -D SMOOTH=$SMOOTH_SCROLL --sym out/engine_r800.sym src/engine/engine.asm out/bank21_engine_r800.bin >> validation/ASSEMBLY.log
python3 tools/build_rom.py out/bank00_boot.bin out/bank20_engine_z80.bin out/bank21_engine_r800.bin $ROM >> validation/ASSEMBLY.log
python3 tools/validate_hybrid.py $ROM > validation/VALIDATE.log
cat validation/ASSEMBLY.log
cat validation/VALIDATE.log

python3 tools/test_frontend_fix01.py
# Independently assembled cartridge boot that REQUIRES real turboR + R800 DRAM.
python3 tools/z80mini.py -D TURBOR_ONLY=1 --sym out/boot_turbor.sym src/boot/boot.asm out/bank00_boot_turbor.bin >> validation/ASSEMBLY.log
python3 tools/build_rom.py out/bank00_boot_turbor.bin out/bank20_engine_z80.bin out/bank21_engine_r800.bin "$ROM_T" --turbor-only >> validation/ASSEMBLY.log
python3 tools/validate_turbor.py "$ROM" "$ROM_T"
sha256sum "$ROM" "$ROM_T" | tee validation/SHA256_BOTH.txt

python3 tools/test_fix03.py | tail -2
