include "../shared/bios.inc"
include "../shared/hybrid.inc"

; =============================================================================
; VOLCABAMBA_MSX2_TURBOR_HYBRID - BOOT module (ASCII16 bank 0, page 1)
;
;   BOOT -> detect MSX generation -> detect VDP -> detect turboR/R800
;        -> select runtime engine bank -> switch CPU -> start game
;
; The player never chooses anything.  Test overrides (hold while booting):
;   N : force the Z80 engine (on turboR the CPU also stays in Z80 mode)
;   R : force the R800 engine module (on MSX2/MSX2+ it simply runs on the Z80;
;       used to validate the turboR runtime on emulators without turboR BIOS)
;   F : start with HCFG_ENHANCED cleared (R800 engine with MSX2 sprite limits)
; =============================================================================

KEYROW_CDEFGHIJ equ 3  ; bit3 = F
KEYROW_KLMNOPQR equ 4  ; bit3 = N, bit7 = R

    org 0x4000
    db "AB"
    dw boot_init
    dw 0
    dw 0
    dw 0
    dw 0,0,0

boot_init:
    di
    ld a,(MSXVER)
    or a
    jp z,boot_msx1
    if TURBOR_ONLY
    ; The dedicated cartridge must not masquerade as R800 on a normal MSX2.
    ; MSXVER=3 is the turboR generation; refuse all other generations.
    cp 3
    jp nz,boot_turbor_required
    endif

    ; ---------------- shared block: keep config/records over warm reset -----
    call hyb_block_check
    ld a,(MSXVER)
    ld (HYB_MSXVER),a
    xor a
    ld (HYB_FORCE),a
    ld (HYB_CPU),a

    ; ---------------- VDP identification (V9938=0, V9958=2) ----------------
    ld a,1
    out (0x99),a
    ld a,0x8F
    out (0x99),a           ; R#15 = 1 -> read status register S#1
    in a,(0x99)
    rrca
    and 0x1F
    ld (HYB_VDP_ID),a
    xor a
    out (0x99),a
    ld a,0x8F
    out (0x99),a           ; R#15 = 0 (BIOS interrupt handler expects S#0)

    ; ---------------- boot-time test overrides ----------------------------
    ld a,KEYROW_KLMNOPQR
    call SNSMAT
    ld b,a
    and 0x08               ; N (active low)
    jp nz,boot_no_force_z
    ld a,ENGINE_KIND_Z80
    ld (HYB_FORCE),a
    jp boot_overrides_done
boot_no_force_z:
    ld a,b
    and 0x80               ; R
    jp nz,boot_overrides_done
    ld a,ENGINE_KIND_R800
    ld (HYB_FORCE),a
boot_overrides_done:
    ld a,KEYROW_CDEFGHIJ
    call SNSMAT
    and 0x08               ; F -> faithful sprite limits in the R800 engine
    jp nz,boot_cfg_done
    ld a,(HYB_CFG)
    and 0xFF-HCFG_ENHANCED
    ld (HYB_CFG),a
boot_cfg_done:
    if TURBOR_ONLY
    ; Distinct turboR-only boot path. Key overrides cannot bypass the CPU test.
    jp boot_select_r800_required
    endif

    ; ---------------- engine selection --------------------------------------
    ld a,(HYB_FORCE)
    cp ENGINE_KIND_Z80
    jp z,boot_select_z80
    cp ENGINE_KIND_R800
    jp z,boot_select_r800_forced
    ld a,(HYB_MSXVER)
    cp 3
    jp c,boot_select_z80

    ; turboR: switch to R800 DRAM mode (bit7 also lights the turbo LED).
    ; The BIOS jump table entry must exist (JP opcode) before calling it.
    ld a,(CHGCPU)
    cp 0xC3
    jp nz,boot_select_r800_forced
    ld a,0x82
    call CHGCPU
    di
    ld a,(GETCPU)
    cp 0xC3
    jp nz,boot_select_r800_forced
    call GETCPU
    di
    ld (HYB_CPU),a
boot_select_r800_forced:
    ld a,ENGINE_KIND_R800
    ld (HYB_ENGINE),a
    ld a,ENGINE_R800_BANK
    jp boot_start_engine
; On the dedicated build, select R800 *only after* BIOS confirms DRAM mode.
boot_select_r800_required:
    ld a,(CHGCPU)
    cp 0xC3
    jp nz,boot_turbor_required
    ld a,0x82
    call CHGCPU
    di
    ld a,(GETCPU)
    cp 0xC3
    jp nz,boot_turbor_required
    call GETCPU
    di
    ld (HYB_CPU),a
    cp 2
    jp nz,boot_turbor_required
    ld a,ENGINE_KIND_R800
    ld (HYB_ENGINE),a
    ld a,ENGINE_R800_BANK
    jp boot_start_engine

boot_select_z80:
    ld a,ENGINE_KIND_Z80
    ld (HYB_ENGINE),a
    ld a,ENGINE_Z80_BANK

; A = engine bank.  Page 1 cannot be switched while executing from it, so a
; small trampoline is copied to page-3 RAM.  It verifies the engine signature
; and falls back to BOOT with an error screen if the bank is not an engine.
boot_start_engine:
    push af
    ld hl,boot_tramp_src
    ld de,HYB_TRAMP
    ld bc,boot_tramp_end-boot_tramp_src
    ldir
    ld a,(HYB_BOOTS)
    inc a
    ld (HYB_BOOTS),a
    ld a,(HYB_ENGINE)
    ld b,a
    pop af
    jp HYB_TRAMP

boot_tramp_src:
    ld (ASCII16_PAGE1_SEL),a
    ld a,(0x4000)
    cp ENGINE_SIG0
    jp nz,HYB_TRAMP+(boot_tramp_bad-boot_tramp_src)
    ld a,(0x4001)
    cp ENGINE_SIG1
    jp nz,HYB_TRAMP+(boot_tramp_bad-boot_tramp_src)
    ld a,(0x4002)
    cp b
    jp nz,HYB_TRAMP+(boot_tramp_bad-boot_tramp_src)
    ld a,(0x4003)
    cp ENGINE_ABI
    jp nz,HYB_TRAMP+(boot_tramp_bad-boot_tramp_src)
    jp ENGINE_ENTRY
boot_tramp_bad:
    xor a
    ld (ASCII16_PAGE1_SEL),a
    jp boot_engine_error
boot_tramp_end:

; Keep HYB block across warm resets; initialise it on cold boot / garbage.
hyb_block_check:
    ld a,(HYB_MAGIC)
    cp 0x56
    jp nz,hyb_block_init
    ld a,(HYB_MAGIC+1)
    cp 0x48
    jp nz,hyb_block_init
    ld a,(HYB_MAGIC+2)
    cp 0x59
    jp nz,hyb_block_init
    ld a,(HYB_MAGIC+3)
    cp 0x42
    jp nz,hyb_block_init
    ld a,(HYB_REC_STAGE)
    cp 8
    jp nc,hyb_block_init
    ld a,(HYB_REC_STONES)
    cp 31
    jp nc,hyb_block_init
    ret
hyb_block_init:
    ld hl,HYB_BASE
    ld de,HYB_BASE+1
    ld bc,HYB_END-HYB_BASE-1
    xor a
    ld (hl),a
    ldir
    ld hl,hyb_magic_text
    ld de,HYB_MAGIC
    ld bc,4
    ldir
    ld a,HCFG_DEFAULT
    ld (HYB_CFG),a
    ret
hyb_magic_text:
    db "VHYB"

; ---------------- MSX1: polite notice instead of a hang -----------------------
boot_msx1:
    ei
    call INITXT
    ld hl,msg_msx1
    call boot_print
boot_halt:
    halt
    jp boot_halt

boot_turbor_required:
    ei
    call INITXT
    ld hl,msg_turbor_required
    call boot_print
    jp boot_halt

boot_engine_error:
    ei
    call INITXT
    ld hl,msg_engine_error
    call boot_print
    jp boot_halt

boot_print:
    ld a,(hl)
    or a
    ret z
    call CHPUT
    inc hl
    jp boot_print

msg_msx1:
    db 13,10,13,10
    db " VOLCABAMBA",13,10
    db " LIFE FORTRESS VOLCABAMBA",13,10,13,10
    db " MSX2 OR HIGHER REQUIRED",13,10,13,10
    db " MSX2 / MSX2+ : Z80 ENGINE",13,10
    db " MSX turboR  : R800 ENGINE",13,10,0
msg_turbor_required:
    db 13,10," VOLCABAMBA turboR ONLY",13,10,13,10
    db " PANASONIC FS-A1ST / FS-A1GT",13,10
    db " SELECT AN MSX turboR MACHINE",13,10
    db " R800 DRAM MODE REQUIRED",13,10,0
msg_engine_error:
    db 13,10," VOLCABAMBA: ENGINE BANK ERROR",13,10,0

    assert boot_tramp_end-boot_tramp_src <= 48, "trampoline too large"
    assert $ <= 0x8000, "boot bank overflow"
    ds 0x8000-$,0xFF
