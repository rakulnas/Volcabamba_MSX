# MSX turboR-only cartridge

Two genuinely different boot targets compiled from the same SOURCE:

- `out/VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom`: MSX2 uses Z80; turboR uses R800 (automatic detection).
- `out/VOLCABAMBA_MSX_TURBOR_ONLY_H02.rom`: requires MSXVER=3, CHGCPU to R800 DRAM and GETCPU confirmation. It contains no Z80 engine at bank 20 (all 0xFF); R800 engine at bank 21. On older MSX machines it displays a clear incompatibility message.

Run `./build.sh` from extracted SOURCE. Use `SMOOTH_SCROLL=0` (default). WARNING: prior experimental fine scroll is **not** pixel-accurate; it still changes tiles in 8-pixel blocks, so it is not presented as corrected.

In openMSX, configure a Panasonic FS-A1ST or FS-A1GT MSX turboR and insert the ROM as an ASCII16 cartridge; ensure required BIOS ROMs are present. Selecting an MSX2 profile cannot emulate R800. Functional startup in these machine profiles has not yet been tested in this build environment.

The previously reported visual defects (front-of-mothership ship layering, star continuity, CAUTION sign, intro/map reset, tile-stepped scrolling) remain pending and are **not declared fixed** by this dedicated-CPU packaging pass.
