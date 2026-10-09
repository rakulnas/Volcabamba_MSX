; =============================================================================
; VOLCABAMBA_MSX2_TURBOR_HYBRID - shared contract between BOOT and both engines
; Included by src/boot/boot.asm and src/engine/engine.asm.  Any change here must
; be made once and rebuilt; both runtime modules are assembled from the same
; engine source, so they cannot drift apart.
; =============================================================================

; ---------------- ASCII16 bank map -------------------------------------------
; bank  0      BOOT (fixed at reset): header, machine/CPU detection, MSX1 notice
; bank  1      COMMON shared data (title, intro, sprites, palette, ending)
; bank  2..19  STAGE 1..6 shared data (gfx / dataA / dataB per stage)
; bank 20      ENGINE_Z80  : MSX2 / MSX2+ runtime  (assembled with TURBO=0)
; bank 21      ENGINE_R800 : turboR runtime        (assembled with TURBO=1)
; bank 22..31  free (0xFF)
BOOT_BANK          equ 0
ENGINE_Z80_BANK    equ 20
ENGINE_R800_BANK   equ 21
ASCII16_PAGE1_SEL  equ 0x6000
ASCII16_PAGE2_SEL  equ 0x7000

; ---------------- Engine module ABI ------------------------------------------
; 0x4000 "VE"   signature
; 0x4002 kind   'Z' or 'R'
; 0x4003 abi    ENGINE_ABI
; 0x4004 word   engine size in bytes
; 0x4010        entry point (DI, page 1 = engine bank, page 2 not yet enabled)
ENGINE_SIG0        equ 0x56 ; 'V'
ENGINE_SIG1        equ 0x45 ; 'E'
ENGINE_KIND_Z80    equ 0x5A ; 'Z'
ENGINE_KIND_R800   equ 0x52 ; 'R'
ENGINE_ABI         equ 1
ENGINE_ENTRY       equ 0x4010

; ---------------- Shared RAM block (page 3) ----------------------------------
; Engines keep their own variables in C000h-C7FFh.  E000h-E0FFh belongs to the
; hybrid contract: machine info written by BOOT, plus configuration and records
; that are identical for both runtimes.  It survives a warm reset (signature
; check) but it is NOT battery backed: ASCII16 without SRAM has no persistence.
HYB_BASE           equ 0xE000
HYB_MAGIC          equ 0xE000 ; 4 bytes "VHYB"
HYB_MSXVER         equ 0xE004 ; BIOS MSXVER: 1 MSX2, 2 MSX2+, 3 turboR
HYB_VDP_ID         equ 0xE005 ; S#1 ID: 0 V9938, 2 V9958
HYB_CPU            equ 0xE006 ; GETCPU: 0 Z80, 1 R800 ROM, 2 R800 DRAM
HYB_ENGINE         equ 0xE007 ; 'Z' or 'R' engine actually started
HYB_FORCE          equ 0xE008 ; 0 auto, 'Z'/'R' = boot-time test override
HYB_CFG            equ 0xE009 ; configuration flags (see HCFG_*)
HYB_BOOTS          equ 0xE00A ; boot counter (warm resets with valid block)
HYB_REC_STAGE      equ 0xE010 ; record: best stage reached (1..7, 7 = ending)
HYB_REC_STONES     equ 0xE011 ; record: most Volca-Stones held at once (0..30)
HYB_REC_CLEARS     equ 0xE012 ; record: completed runs (saturates at 255)
HYB_TRAMP          equ 0xE040 ; BOOT -> engine trampoline (RAM, <= 48 bytes)
HYB_END            equ 0xE100

; HYB_CFG bits
HCFG_ENHANCED      equ 1      ; R800 engine: extended sprite multiplexer
HCFG_DEFAULT       equ 1

; ---------------- BIOS (turboR) ----------------------------------------------
CHGCPU             equ 0x0180 ; A = 0x80 | mode (0 Z80, 1 R800 ROM, 2 R800 DRAM)
GETCPU             equ 0x0183 ; -> A = current mode
