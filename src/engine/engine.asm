include "../shared/bios.inc"
include "../shared/hybrid.inc"
include "../../generated/full_constants.inc"

; VOLCABAMBA_MSX2_TURBOR_HYBRID - runtime engine (one source, two modules)
;   TURBO=0 -> ENGINE_Z80  (ASCII16 bank 20): MSX2 / MSX2+, faithful + optimised
;   TURBO=1 -> ENGINE_R800 (ASCII16 bank 21): turboR, same game logic, extended
;              sprite multiplexer and other optional enhancements (HYB_CFG).
; Game logic, tick order, timings and every byte of map/script/graphics data are
; shared.  BOOT (bank 0) selects the module; the engine never touches bank 0.
; Page 1 = engine bank (fixed while running), page 2 = data banks via 7000h.
; All mutable state lives in page 3 RAM. No previous ROM is read or patched.

; ---------------- RAM ---------------------------------------------------------
SCROLL_COL     equ 0xC000 ; word
SCROLL_SUB     equ 0xC002
PLAYER_X       equ 0xC003
PLAYER_Y       equ 0xC004
PLAYER_FRAME   equ 0xC005
SHOT_DIR       equ 0xC006
SHOTF_ON       equ 0xC007
SHOTF_X        equ 0xC008
SHOTF_Y        equ 0xC009
SHOTR_ON       equ 0xC00A
SHOTR_X        equ 0xC00B
SHOTR_Y        equ 0xC00C
DIR_LATCH      equ 0xC00D
START_LATCH    equ 0xC00E
INV_LATCH      equ 0xC00F
INVINCIBLE     equ 0xC010
DEATH_T        equ 0xC011
PAUSED         equ 0xC012
IS_PAL         equ 0xC013
FRAME_PHASE    equ 0xC014
STICK_TMP      equ 0xC015
BOSS_ACTIVE    equ 0xC016
BOSS_HP        equ 0xC017
BOSS_Y         equ 0xC018
BOSS_DIR       equ 0xC019
ANIM_T         equ 0xC01A
RUN_COUNT      equ 0xC01B
RUN_VALUE      equ 0xC01C
TMP_TOKEN      equ 0xC01D
TMP_LEN        equ 0xC01E
STAGE_CLEAR    equ 0xC01F
CMP_PTR        equ 0xC020 ; word
SPAWN_PTR      equ 0xC022 ; word
COL_TARGET     equ 0xC024 ; word
COL_ROW        equ 0xC026
TMP_KIND       equ 0xC027
TMP_Y          equ 0xC028
TMP_SPEED      equ 0xC029
TMP_EX         equ 0xC02A
TMP_EY         equ 0xC02B
CHECK_X        equ 0xC02C
CHECK_Y        equ 0xC02D
EN_PTR         equ 0xC02E ; word
TMP_PARAM      equ 0xC02F
; BASE12 deep parity pools. The original engine has 40 logical enemy slots
; and 20 enemy projectile slots. Keep that logical capacity even though the MSX2
; hardware renderer can display fewer sprites on one scanline.
EN_BASE        equ 0xC200
EN_COUNT       equ 40
EN_REC_SIZE    equ 7
EN0            equ 0xC200
EN1            equ 0xC207
EN2            equ 0xC20E
EN3            equ 0xC215
EN4            equ 0xC21C
EN5            equ 0xC223
EN6            equ 0xC22A
EN7            equ 0xC231
BUL_BASE       equ 0xC318
BUL_COUNT      equ 20
BUL_REC_SIZE   equ 5
BUL0           equ 0xC318
BUL1           equ 0xC31D
BUL2           equ 0xC322
BUL3           equ 0xC327
BUL4           equ 0xC32C
BUL5           equ 0xC331
BUL6           equ 0xC336
BUL7           equ 0xC33B
; Player projectiles: 3 front + 3 rear, 4 bytes each: active,x,y,vector.
SHOT_BASE      equ 0xC37C
SHOT_COUNT     equ 6
SHOT_REC_SIZE  equ 4
SHOT_COOL      equ 0xC394
SHOT_PTR       equ 0xC395 ; word
SCRIPT_STEP    equ 0xC397 ; word, exact stage1 script step (4 logic ticks)
SCRIPT_DIV     equ 0xC399
TMP_X         equ 0xC39A
TMP_HP        equ 0xC39B
BUL_PTR        equ 0xC39C ; word
RENDER_COUNT   equ 0xC39E
RENDER_SATPTR  equ 0xC39F ; word
BOSS_DEATH_T   equ 0xC3A1
BOSS_TIMER     equ 0xC3A2 ; word
RNG_STATE      equ 0xC3A4
; HYBRID sprite multiplexer (shared by both engines, behaviour selected by layout)
RL_MAX         equ 0xC3A6 ; slots available in the current list
RL_SLOTS       equ 0xC3A7 ; word, pointer to the SAT slot list
RL_SLOT        equ 0xC3A9 ; current SAT slot
RL_IDX         equ 0xC3AA ; current logical record index
EN_ROT         equ 0xC3AB ; first enemy record to show next frame (rotation)
BUL_ROT        equ 0xC3AC ; first bullet record to show next frame (rotation)
RL_ROTATE      equ 0xC3AD ; 1 = rotate start record when a list overflows
SLOT_COLOR     equ 0xC3C0 ; 32 bytes: colour last written to each SAT slot
; HYBRID real-time scheduler
TICK_CREDIT    equ 0xC3AE ; logic ticks owed to real time (capped at 2)
LAST_JIFFY     equ 0xC3AF ; low byte of JIFFY seen by the scheduler
SKIP_RENDER    equ 0xC3B0 ; 1 = catch-up tick, skip SAT rendering
; HYBRID collision window: 22 rows x 64 columns ring of decoded attributes
CW_ROW         equ 0xC3B1
CW_COLOFF      equ 0xC3B2
CW_TMP         equ 0xC3B3
CW_TMPV        equ 0xC3B4
CW_NEXT        equ 0xC3B5 ; word, first column not decoded yet
SHOT_LIST_N    equ 0xC3E0 ; active player shots this tick
SHOT_LIST      equ 0xC3E1 ; 6 x (record ptr word, centre x, centre y)
COLWIN         equ 0xD000 ; 22*64 = 1408 bytes
CW_PTR         equ 0xD600 ; 22 words, RLE cursor per row
CW_LEFT        equ 0xD640 ; 22 bytes, columns left in the current run
CW_VAL         equ 0xD660 ; 22 bytes, attribute of the current run
COLWIN_AHEAD   equ 40     ; decoded columns from SCROLL_COL (screen = 32)
INTRO_T        equ 0xC050
INTRO_FRAME    equ 0xC051
INTRO_X        equ 0xC052
INTRO_Y        equ 0xC053
BOSS_PAT       equ 0xC054
BOSS_PAT_T     equ 0xC055
BOSS_PROJ_T    equ 0xC056
ESC0           equ 0xC060 ; active,x,y
ESC1           equ 0xC063
ESC2           equ 0xC066
ESC3           equ 0xC069
ESC4           equ 0xC06C
ESC_MASK       equ 0xC06F
STONE_GOT      equ 0xC070 ; 30 bytes
STONE_ROW_BUF  equ 0xC090 ; 32 tile names, positions 1..30 are stones
MID_ACTIVE     equ 0xC0B0
MID_KIND       equ 0xC0B1
MID_X          equ 0xC0B2
MID_Y          equ 0xC0B3
MID_STATE      equ 0xC0B4
MID_T          equ 0xC0B5
SATBUF         equ 0xC100
CURRENT_STAGE  equ 0xC0B6
CURRENT_BANK   equ 0xC0B7
DATA_BANK      equ 0xC0B8
GFX_BANK       equ 0xC0B9
SCROLL_MAX     equ 0xC0BA ; word
STAGE_COLS_VAR equ 0xC0BC ; word
COLL_OFF_PTR   equ 0xC0BE ; word
COLL_RLE_PTR   equ 0xC0C0 ; word
HUD_PTR_RAM    equ 0xC0C2 ; word
PAUSE_PTR_RAM  equ 0xC0C4 ; word
CLEAR_PTR_RAM  equ 0xC0C6 ; word
STONES_PTR_RAM equ 0xC0C8 ; word
STONE_EMPTY_TILE equ 0xC0CA
STONE_GOT_TILE equ 0xC0CB
STONE_GLOW_TILE equ 0xC0CC
BOSS_HP_INIT   equ 0xC0CD
START_X_RAM    equ 0xC0CE
START_Y_RAM    equ 0xC0CF
BANK_SRC       equ 0xC0D0 ; word
BANK_LEN       equ 0xC0D2 ; word
DRAW_ROW       equ 0xC0D4
DRAW_VRAM      equ 0xC0D5 ; word
MID_LASER_T    equ 0xC0D7
BUL_SPAWN_TYPE equ 0xC0D8
MID_LASER_PTR  equ 0xC0D9 ; word, stage1 3 zones x 4 phases x 24 name bytes
ROW_DIR_RAM    equ 0xC180 ; 66 bytes (22 * bank+ptr)
STAGE_RAM      equ 0xC400 ; 768-byte intro decompression scratch only
HUD_ROW_BUF    equ 0xC700 ; dynamic name row, outside intro scratch and SAT
HUD_DIGITS     equ 0xC0E0 ; 10 zone-0 tile names generated from original font
LIVES          equ 0xC0EA ; includes the active ship, HUD shows LIVES-1
SCORE_DIGITS   equ 0xC0F0 ; 7 unpacked decimal digits
EXTEND_DIGITS  equ 0xC0F7 ; 7 digits: first extend at 20000, then +50000
HUD_TMP        equ 0xC0FE
INTRO_COLORBUF equ 0xC720 ; per-scanline sprite occlusion in the hangar

; Common bank resource aliases generated by tools/pack_full_game.py.
title_z0_patterns equ title_z0_ptr
title_z1_patterns equ title_z1_ptr
title_z2_patterns equ title_z2_ptr
title_z0_colors equ title_c0_ptr
title_z1_colors equ title_c1_ptr
title_z2_colors equ title_c2_ptr
title_names equ title_names_ptr
intro_z0_patterns equ intro_z0_ptr
intro_z1_patterns equ intro_z1_ptr
intro_z2_patterns equ intro_z2_ptr
intro_z0_colors equ intro_c0_ptr
intro_z1_colors equ intro_c1_ptr
intro_z2_colors equ intro_c2_ptr
intro_names_0 equ intro_names_0_ptr
intro_names_1 equ intro_names_1_ptr
intro_names_2 equ intro_names_2_ptr
intro_names_3 equ intro_names_3_ptr
intro_names_4 equ intro_names_4_ptr
intro_names_5 equ intro_names_5_ptr
intro_names_6 equ intro_names_6_ptr
intro_names_7 equ intro_names_7_ptr
intro_names_8 equ intro_names_8_ptr
intro_names_9 equ intro_names_9_ptr
sprite_patterns equ sprite_patterns_ptr
SPRITE_PAT_BYTES equ sprite_patterns_bytes
intro_sprite_colors equ intro_sprite_colors_ptr
game_escort_sprite_colors equ game_escort_colors_ptr
game_sentinel_sprite_colors equ game_sentinel_colors_ptr

org 0x4000
engine_header:
    db ENGINE_SIG0,ENGINE_SIG1
    if TURBO
    db ENGINE_KIND_R800
    else
    db ENGINE_KIND_Z80
    endif
    db ENGINE_ABI
    dw engine_end-0x4000
    ds ENGINE_ENTRY-$,0

engine_start:
    di
    call enable_cart_page2
    ; Rotation (sprite multiplexing over frames) is an R800-engine enhancement.
    xor a
    ld (RL_ROTATE),a
    ld (EN_ROT),a
    ld (BUL_ROT),a
    if TURBO
    ld a,(HYB_CFG)
    and HCFG_ENHANCED
    ld (RL_ROTATE),a
    endif
    ; ASCII16: this engine bank stays fixed at 4000h-7FFFh, page 2 is selected via 7000h.
    ld a,COMMON_BANK
    call select_bank
    ei
game_restart:
    ld a,COMMON_BANK
    call select_bank
    if SMOOTH
    ; Reinitialize scroll-related VDP registers even after warm reset.
    call scroll_fine_reset
    endif
    call show_title
    call new_game_state
stage_loop:
    if SMOOTH
    call scroll_fine_reset
    endif
    call show_area_current
    ld a,(CURRENT_STAGE)
    cp 1
    jp nz,stage_no_prologue
    ld a,COMMON_BANK
    call select_bank
    call show_prologue
stage_no_prologue:
    call stage_init
    call colwin_reset
    call sched_reset
    jp main_loop

; Shared records (HYB block, identical layout for both engines).
update_records:
    ld a,(HYB_REC_STAGE)
    ld b,a
    ld a,(CURRENT_STAGE)
    cp b
    jp c,ur_stones
    jp z,ur_stones
    ld (HYB_REC_STAGE),a
ur_stones:
    ld hl,STONE_GOT
    ld b,30
    ld c,0
ur_count:
    ld a,(hl)
    or a
    jp z,ur_count_next
    inc c
ur_count_next:
    inc hl
    djnz ur_count
    ld a,(HYB_REC_STONES)
    cp c
    ret nc
    ld a,c
    ld (HYB_REC_STONES),a
    ret

new_game_state:
    ld a,1
    ld (CURRENT_STAGE),a
    call reset_run_state
    ret

reset_run_state:
    ld a,3
    ld (LIVES),a
    xor a
    ld hl,SCORE_DIGITS
    ld de,SCORE_DIGITS+1
    ld bc,6
    ld (hl),a
    ldir
    ld hl,EXTEND_DIGITS
    ld de,EXTEND_DIGITS+1
    ld bc,6
    ld (hl),a
    ldir
    ld a,2                   ; 0020000 = first extend at 20,000 points
    ld (EXTEND_DIGITS+2),a
    xor a
    ld hl,STONE_GOT
    ld de,STONE_GOT+1
    ld bc,29
    ld (hl),a
    ldir
    ret

select_bank:
    ld (0x7000),a
    ld (CURRENT_BANK),a
    ret

select_stage_gfx:
    ld a,(CURRENT_STAGE)
    dec a
    ld e,a
    ld d,0
    ld hl,stage_gfx_bank_table
    add hl,de
    ld a,(hl)
    ld (GFX_BANK),a
    jp select_bank

select_stage_data:
    ld a,(CURRENT_STAGE)
    dec a
    ld e,a
    ld d,0
    ld hl,stage_data_bank_table
    add hl,de
    ld a,(hl)
    ld (DATA_BANK),a
    jp select_bank

restore_data_bank:
    ld a,(DATA_BANK)
    jp select_bank

stage_gfx_bank_table:
    db 2,5,8,11,14,17
stage_data_bank_table:
    db 3,6,9,12,15,18

; Standard MSX page-1 slot -> page-2 slot mapping, including expanded slots.
enable_cart_page2:
    call RSLREG
    rrca
    rrca
    and 3
    ld c,a
    add a,0xC1
    ld l,a
    ld h,0xFC
    ld a,(hl)
    and 0x80
    or c
    ld c,a
    inc l
    inc l
    inc l
    inc l
    ld a,(hl)
    and 0x0C
    or c
    ld h,0x80
    call ENASLT
    ret

show_title:
    call DISSCR
    ld a,4
    call CHGMOD
    call load_palette
    ld hl,title_z0_patterns
    ld de,0x0000
    ld bc,TITLE_Z0_BYTES
    call LDIRVM
    ld hl,title_z1_patterns
    ld de,0x0800
    ld bc,TITLE_Z1_BYTES
    call LDIRVM
    ld hl,title_z2_patterns
    ld de,0x1000
    ld bc,TITLE_Z2_BYTES
    call LDIRVM
    ld hl,title_z0_colors
    ld de,0x2000
    ld bc,TITLE_Z0_BYTES
    call LDIRVM
    ld hl,title_z1_colors
    ld de,0x2800
    ld bc,TITLE_Z1_BYTES
    call LDIRVM
    ld hl,title_z2_colors
    ld de,0x3000
    ld bc,TITLE_Z2_BYTES
    call LDIRVM
    ld hl,title_names
    ld de,0x1800
    ld bc,768
    call LDIRVM
    call ENASCR
wait_title_release:
    xor a
    call GTTRIG
    or a
    jp nz,wait_title_release
wait_title_press:
    xor a
    call GTTRIG
    or a
    jp z,wait_title_press
    ret

show_area_current:
    call select_stage_gfx
    call DISSCR
    ld a,4
    call CHGMOD
    call load_palette
    ld hl,GFX_HDR+4
    ld de,0x0000
    call load_bank_entry_vram
    ld hl,GFX_HDR+8
    ld de,0x0800
    call load_bank_entry_vram
    ld hl,GFX_HDR+12
    ld de,0x1000
    call load_bank_entry_vram
    ld hl,GFX_HDR+16
    ld de,0x2000
    call load_bank_entry_vram
    ld hl,GFX_HDR+20
    ld de,0x2800
    call load_bank_entry_vram
    ld hl,GFX_HDR+24
    ld de,0x3000
    call load_bank_entry_vram
    ld hl,GFX_HDR+28
    ld de,0x1800
    call load_bank_entry_vram
    call ENASCR
    ld b,50
area_wait:
    halt
    djnz area_wait
    ret

; HL points to a [source word,length word] entry in the currently mapped bank.
; DE is the target VRAM address.
load_bank_entry_vram:
    ld a,(hl)
    ld (BANK_SRC),a
    inc hl
    ld a,(hl)
    ld (BANK_SRC+1),a
    inc hl
    ld a,(hl)
    ld (BANK_LEN),a
    inc hl
    ld a,(hl)
    ld (BANK_LEN+1),a
    ld hl,(BANK_SRC)
    ld a,(BANK_LEN)
    ld c,a
    ld a,(BANK_LEN+1)
    ld b,a
    call LDIRVM
    ret

; -----------------------------------------------------------------------------
; World-1 launch prologue reconstructed from FIX23 label_593 timing.
; The mothership graphics are canonical FIX23 assets. This is deliberately
; blocking until intro_t=124; gameplay then begins with the same player position.
show_prologue:
    call DISSCR
    ld a,4
    call CHGMOD
    ld b,0
    ld c,7
    call WRTVDP
    ld a,(RG1SAV)
    or 2
    ld b,a
    ld c,1
    call WRTVDP
    call load_palette
    ld hl,intro_z0_patterns
    ld de,0x0000
    ld bc,INTRO_Z0_BYTES
    call LDIRVM
    ld hl,intro_z1_patterns
    ld de,0x0800
    ld bc,INTRO_Z1_BYTES
    call LDIRVM
    ld hl,intro_z2_patterns
    ld de,0x1000
    ld bc,INTRO_Z2_BYTES
    call LDIRVM
    ld hl,intro_z0_colors
    ld de,0x2000
    ld bc,INTRO_Z0_BYTES
    call LDIRVM
    ld hl,intro_z1_colors
    ld de,0x2800
    ld bc,INTRO_Z1_BYTES
    call LDIRVM
    ld hl,intro_z2_colors
    ld de,0x3000
    ld bc,INTRO_Z2_BYTES
    call LDIRVM
    ld hl,sprite_patterns
    ld de,0x3800
    ld bc,SPRITE_PAT_BYTES
    call LDIRVM
    ld hl,intro_sprite_colors
    ld de,0x1C00
    ld bc,INTRO_SPRITE_COLOR_BYTES
    call LDIRVM
    ld hl,game_sat_template
    ld de,SATBUF
    ld bc,16
    ldir
    ld a,216
    ld (SATBUF+12),a       ; slot 3 terminator: no stale SAT sprites in prologue
    xor a
    ld (INTRO_T),a
    ld a,0xFF
    ld (INTRO_FRAME),a
    ; Correct alignment to the door in the canonical mothership graphics.
    ; The hatch occupies screen x=81..127 at y=64..73: centre the 16px
    ; fighter at x=96 and start above the hatch for the vertical launch.
    ld a,96
    ld (INTRO_X),a
    ld a,48
    ld (INTRO_Y),a
    ld a,2
    call intro_set_frame
    call intro_render
    call ENASCR
intro_loop:
    ; 33 Hz-ish logic: alternate one/two VBlanks on PAL; two on NTSC.
    halt
    ld a,(RG9SAV)
    and 2
    jp z,intro_ntsc_wait
    ld a,(INTRO_T)
    and 1
    jp nz,intro_wait_done
    halt
    jp intro_wait_done
intro_ntsc_wait:
    halt
intro_wait_done:
    call intro_logic
    ld a,(INTRO_T)
    inc a
    ld (INTRO_T),a
    cp 125
    jp c,intro_loop
    ; leave the player where the launch sequence ended
    ret

intro_logic:
    ld a,(INTRO_T)
    cp 18
    jp c,intro_fr_depart0
    cp 23
    jp c,intro_fr_closed
    cp 67
    jp c,intro_fr_open
    cp 72
    jp c,intro_fr_closed
    cp 84
    jp c,intro_fr_depart0
    cp 90
    jp c,intro_fr_depart0
    cp 96
    jp c,intro_fr_depart1
    cp 102
    jp c,intro_fr_depart2
    cp 108
    jp c,intro_fr_depart3
    cp 114
    jp c,intro_fr_depart4
    cp 120
    jp c,intro_fr_depart5
    cp 123
    jp c,intro_fr_depart6
    jp intro_fr_depart7
intro_fr_closed:
    ld a,0
    call intro_set_frame
    jp intro_move_player
intro_fr_open:
    ld a,1
    call intro_set_frame
    jp intro_move_player
intro_fr_depart0:
    ld a,2
    call intro_set_frame
    jp intro_move_player
intro_fr_depart1:
    ld a,3
    call intro_set_frame
    jp intro_move_player
intro_fr_depart2:
    ld a,4
    call intro_set_frame
    jp intro_move_player
intro_fr_depart3:
    ld a,5
    call intro_set_frame
    jp intro_move_player
intro_fr_depart4:
    ld a,6
    call intro_set_frame
    jp intro_move_player
intro_fr_depart5:
    ld a,7
    call intro_set_frame
    jp intro_move_player
intro_fr_depart6:
    ld a,8
    call intro_set_frame
    jp intro_move_player
intro_fr_depart7:
    ; Final canonical frame contains no remaining mothership pixels.
    ; Display it before swapping VRAM to the scrolling world.
    ld a,9
    call intro_set_frame
intro_move_player:
    ld a,(INTRO_T)
    cp 30
    jp c,intro_render_now
    cp 86
    jp nc,intro_launch_x
    ld a,(INTRO_Y)
    cp 96
    jp nc,intro_render_now
    inc a
    ld (INTRO_Y),a
    jp intro_render_now
intro_launch_x:
    ld a,(INTRO_T)
    cp 89
    jp c,intro_render_now
    cp 91
    jp nc,intro_launch_x_slow
    ld a,(INTRO_X)
    add a,8
    ld (INTRO_X),a
    jp intro_render_now
intro_launch_x_slow:
    cp 94
    jp nc,intro_render_now
    ld a,(INTRO_X)
    add a,4
    ld (INTRO_X),a
intro_render_now:
    call intro_render
    ret

intro_set_frame:
    ld b,a
    ld a,(INTRO_FRAME)
    cp b
    ret z
    ld a,b
    ld (INTRO_FRAME),a
    cp 0
    jp z,intro_src0
    cp 1
    jp z,intro_src1
    cp 2
    jp z,intro_src2
    cp 3
    jp z,intro_src3
    cp 4
    jp z,intro_src4
    cp 5
    jp z,intro_src5
    cp 6
    jp z,intro_src6
    cp 7
    jp z,intro_src7
    cp 8
    jp z,intro_src8
    ld hl,intro_names_9
    jp intro_unpack
intro_src0: ld hl,intro_names_0
    jp intro_unpack
intro_src1: ld hl,intro_names_1
    jp intro_unpack
intro_src2: ld hl,intro_names_2
    jp intro_unpack
intro_src3: ld hl,intro_names_3
    jp intro_unpack
intro_src4: ld hl,intro_names_4
    jp intro_unpack
intro_src5: ld hl,intro_names_5
    jp intro_unpack
intro_src6: ld hl,intro_names_6
    jp intro_unpack
intro_src7: ld hl,intro_names_7
    jp intro_unpack
intro_src8: ld hl,intro_names_8
intro_unpack:
    ; BASE09: frame swaps are atomic. BASE08 wrote 768 name bytes while the
    ; display was active and C-BIOS exposed visible mothership corruption.
    call DISSCR
    ld de,STAGE_RAM
intro_decomp_next:
    ld a,d
    cp 0xC7
    jp nz,intro_decomp_read
    ld a,e
    or a
    jp z,intro_decomp_done
intro_decomp_read:
    ld a,(hl)
    inc hl
    cp 128
    jp c,intro_decomp_literal
    ld (TMP_TOKEN),a
    ld a,(hl)
    inc hl
    ld c,a
    ld (CMP_PTR),hl
    ld a,(TMP_TOKEN)
    and 0x70
    srl a
    srl a
    srl a
    srl a
    ld b,a
    inc bc
    ld a,(TMP_TOKEN)
    and 0x0F
    add a,3
    ld (TMP_LEN),a
    ld h,d
    ld l,e
    or a
    sbc hl,bc
    ld a,(TMP_LEN)
    ld b,a
intro_decomp_backcopy:
    ld a,(hl)
    ld (de),a
    inc hl
    inc de
    djnz intro_decomp_backcopy
    ld hl,(CMP_PTR)
    jp intro_decomp_next
intro_decomp_literal:
    inc a
    ld b,a
intro_decomp_lit_loop:
    ld a,(hl)
    inc hl
    ld (de),a
    inc de
    djnz intro_decomp_lit_loop
    jp intro_decomp_next
intro_decomp_done:
    ld hl,STAGE_RAM
    ld de,0x1800
    ld bc,768
    call LDIRVM
    call ENASCR
    ret

intro_render:
    ; Reset the 13 active launch slots every frame.  The original five escort
    ; fighters are NOT part of label_593 itself; they are spawned by label_601
    ; after gameplay scroll starts, so the prologue only draws fighter + flame.
    ld hl,game_sat_template
    ld de,SATBUF
    ld bc,16
    ldir
    ld a,216
    ld (SATBUF+12),a       ; slot 3 terminator: no stale SAT sprites in prologue
    ; The mothership must occlude the fighter (MSX sprites are always on top).
    ; Mask lines still inside the hull through per-scanline sprite-mode-2 colours.
    call intro_mask_occluded_lines
    ; fighter, exact two-colour canonical player
    ld a,(INTRO_Y)
    ld (SATBUF+0),a
    ld (SATBUF+4),a
    ld a,(INTRO_X)
    ld (SATBUF+1),a
    ld (SATBUF+5),a
    ld a,SPR_PLAYER0_WHITE
    ld (SATBUF+2),a
    ld a,SPR_PLAYER0_GREEN
    ld (SATBUF+6),a
    ; flame during vertical launch and first horizontal kick
    ld a,(INTRO_T)
    cp 30
    jp c,intro_commit
    cp 63
    jp nc,intro_rear_flame
    ld a,(INTRO_Y)
    add a,12
    ld (SATBUF+8),a
    ld a,(INTRO_X)
    ld (SATBUF+9),a
    ld a,SPR_FLAME_DOWN
    ld (SATBUF+10),a
    jp intro_commit
intro_rear_flame:
    ld a,(INTRO_T)
    cp 89
    jp c,intro_commit
    cp 91
    jp nc,intro_commit
    ld a,(INTRO_Y)
    ld (SATBUF+8),a
    ld a,(INTRO_X)
    sub 12
    ld (SATBUF+9),a
    ld a,SPR_FLAME_REAR
    ld (SATBUF+10),a
intro_commit:
    ; No flame may shine through the undeparted mothership hull.
    ld a,(INTRO_Y)
    cp 80
    jp nc,intro_commit_visible_flame
    ld a,200
    ld (SATBUF+8),a
intro_commit_visible_flame:
    ld hl,SATBUF
    ld de,0x1E00
    ld bc,16
    call LDIRVM
    ret

intro_mask_occluded_lines:
    ; Mother hull occupies screen y=32..87. A fighter pixel appears only when
    ; that sprite scanline has passed y=87. Both colour layers use same mask.
    ld hl,INTRO_COLORBUF
    ld b,16
    ld c,0
imask_white:
    ld a,(INTRO_Y)
    add a,c
    cp 88
    jp c,imask_w_zero
    ld a,15
    jp imask_w_store
imask_w_zero:
    xor a
imask_w_store:
    ld (hl),a
    inc hl
    inc c
    djnz imask_white
    ld b,16
    ld c,0
imask_green:
    ld a,(INTRO_Y)
    add a,c
    cp 88
    jp c,imask_g_zero
    ld a,12
    jp imask_g_store
imask_g_zero:
    xor a
imask_g_store:
    ld (hl),a
    inc hl
    inc c
    djnz imask_green
    ld hl,INTRO_COLORBUF
    ld de,0x1C00
    ld bc,32
    call LDIRVM
    ret

stage_init:
    call update_records
    call DISSCR
    ; Stage 1 already has SCREEN4 from prologue: don't reset VDP/memory again.
    ld a,(CURRENT_STAGE)
    cp 1
    jp z,stage_screen4_ready
    ld a,4
    call CHGMOD
stage_screen4_ready:
    ld b,0
    ld c,7
    call WRTVDP
    ld a,(RG1SAV)
    or 2
    ld b,a
    ld c,1
    call WRTVDP
    call load_palette

    ; Load the current stage tile patterns/colours from its graphics bank.
    call select_stage_gfx
    ld hl,GFX_HDR+32
    ld de,0x0000
    call load_bank_entry_vram
    ld hl,GFX_HDR+36
    ld de,0x0800
    call load_bank_entry_vram
    ld hl,GFX_HDR+40
    ld de,0x1000
    call load_bank_entry_vram
    ld hl,GFX_HDR+44
    ld de,0x2000
    call load_bank_entry_vram
    ld hl,GFX_HDR+48
    ld de,0x2800
    call load_bank_entry_vram
    ld hl,GFX_HDR+52
    ld de,0x3000
    call load_bank_entry_vram

    ; Common player/shot/enemy sprites live in bank 1 and are loaded once per stage.
    ld a,COMMON_BANK
    call select_bank
    ld hl,sprite_patterns
    ld de,0x3800
    ld bc,SPRITE_PAT_BYTES
    call LDIRVM
    ld hl,game_escort_sprite_colors
    ld de,0x1C00
    ld bc,GAME_ESCORT_COLOR_BYTES
    call LDIRVM
    ; Enemy bullets use SAT slots 20..27, bright yellow in this pass.
    ld hl,0x1D40
    ld a,10
    ld bc,128
    call FILVRM
    call slot_color_invalidate

    ; Map current stage data and cache its pointers/directory in RAM.
    call select_stage_data
    ld hl,(DATA_HDR+4)
    ld (STAGE_COLS_VAR),hl
    ld hl,(DATA_HDR+6)
    ld (SCROLL_MAX),hl
    ld hl,(DATA_HDR+8)
    ld (SPAWN_PTR),hl
    ld hl,(DATA_HDR+12)
    ld (COLL_OFF_PTR),hl
    ld hl,(DATA_HDR+14)
    ld (COLL_RLE_PTR),hl
    ld hl,(DATA_HDR+18)
    ld (HUD_PTR_RAM),hl
    ld hl,(DATA_HDR+20)
    ld (PAUSE_PTR_RAM),hl
    ld hl,(DATA_HDR+22)
    ld (CLEAR_PTR_RAM),hl
    ld hl,(DATA_HDR+24)
    ld (STONES_PTR_RAM),hl
    ld a,(DATA_HDR+26)
    ld (STONE_EMPTY_TILE),a
    ld a,(DATA_HDR+27)
    ld (STONE_GOT_TILE),a
    ld a,(DATA_HDR+28)
    ld (STONE_GLOW_TILE),a
    ld a,(DATA_HDR+29)
    ld (START_X_RAM),a
    ld a,(DATA_HDR+30)
    ld (START_Y_RAM),a
    ld a,(DATA_HDR+31)
    ld (BOSS_HP_INIT),a
    ; Each stage carries its own numeric glyph indices in graphics zone 0.
    ld hl,DATA_HDR+36
    ld de,HUD_DIGITS
    ld bc,10
    ldir
    ld hl,(DATA_HDR+34)
    ld (MID_LASER_PTR),hl
    ld hl,(DATA_HDR+16)
    ld de,ROW_DIR_RAM
    ld bc,66
    ldir
    ld hl,(STONES_PTR_RAM)
    ld de,STONE_ROW_BUF
    ld bc,32
    ldir
    call sync_stone_row

    ld hl,game_sat_template
    ld de,SATBUF
    ld bc,128
    ldir
    ld hl,0
    ld (SCROLL_COL),hl
    xor a
    ld (SCROLL_SUB),a
    ld (PLAYER_FRAME),a
    ld (SHOTF_ON),a
    ld (SHOTR_ON),a
    ld (DIR_LATCH),a
    ld (START_LATCH),a
    ld (INV_LATCH),a
    ld (INVINCIBLE),a
    ld (DEATH_T),a
    ld (PAUSED),a
    ld (FRAME_PHASE),a
    ld (BOSS_ACTIVE),a
    ld (BOSS_DEATH_T),a
    ld (BOSS_TIMER),a
    ld (BOSS_TIMER+1),a
    ld (STAGE_CLEAR),a
    ld (ANIM_T),a
    ; Clear original-capacity logical pools: 40 enemies, 20 hostile bullets,
    ; and the 3+3 player shot slots.
    ld hl,EN_BASE
    ld de,EN_BASE+1
    ld bc,279
    ld (hl),a
    ldir
    ld hl,BUL_BASE
    ld de,BUL_BASE+1
    ld bc,99
    ld (hl),a
    ldir
    ld hl,SHOT_BASE
    ld de,SHOT_BASE+1
    ld bc,23
    ld (hl),a
    ldir
    xor a
    ld (SHOT_COOL),a
    ld hl,0
    ld (SCRIPT_STEP),hl
    xor a
    ld (SCRIPT_DIV),a
    ld a,0x5D
    ld (RNG_STATE),a
    xor a
    ld (ESC0),a
    ld (ESC1),a
    ld (ESC2),a
    ld (ESC3),a
    ld (ESC4),a
    ld (ESC_MASK),a
    ld (MID_ACTIVE),a
    ld (MID_KIND),a
    ld (MID_STATE),a
    ld (MID_T),a
    ld (MID_LASER_T),a
    ld (BUL_SPAWN_TYPE),a

    ; World 1 starts exactly where the mothership sequence leaves the fighter.
    ld a,(CURRENT_STAGE)
    cp 1
    jp nz,stage_use_header_start
    ld a,(INTRO_X)
    ld (PLAYER_X),a
    ld a,(INTRO_Y)
    ld (PLAYER_Y),a
    jp stage_start_done
stage_use_header_start:
    ld a,(START_X_RAM)
    ld (PLAYER_X),a
    ld a,(START_Y_RAM)
    ld (PLAYER_Y),a
stage_start_done:
    ld a,2
    ld (SHOT_DIR),a

    ld a,(RG9SAV)
    and 2
    jp z,stage_ntsc
    ld a,1
    ld (IS_PAL),a
    jp stage_video_known
stage_ntsc:
    xor a
    ld (IS_PAL),a
stage_video_known:
    call draw_stage
    call render_sprites
    call ENASCR
wait_stage_start_release:
    ld a,8
    call SNSMAT
    and 1
    jp z,wait_stage_start_release
    xor a
    ld (START_LATCH),a
    ret

sync_stone_row:
    ld hl,STONE_GOT
    ld de,STONE_ROW_BUF+1
    ld b,30
sync_stone_loop:
    ld a,(hl)
    or a
    jp z,sync_stone_next
    ld a,(STONE_GOT_TILE)
    ld (de),a
sync_stone_next:
    inc hl
    inc de
    djnz sync_stone_loop
    ret

; Stage maps are row-banked in ROM; no whole-map decompression is required.

load_palette:
    ld c,16
    ld b,0
    call WRTVDP
    ld hl,palette
    ld b,32
pal_loop:
    ld a,(hl)
    out (0x9A),a
    inc hl
    djnz pal_loop
    ret

main_loop:
    halt
main_after_halt:
    ; HYBRID scheduler: logic ticks follow REAL frames (JIFFY), with the exact
    ; BASE12 cadence (PAL 2 of 3 frames, NTSC 5 of 9 frames = 33.3 Hz).  A
    ; tick that overruns a frame no longer slows the game down: the owed tick
    ; runs next, without sprite rendering (max 2 owed ticks).
    call sched_frames
main_dispatch:
    call check_pause
    ld a,(PAUSED)
    or a
    jp nz,main_paused
    ld a,(STAGE_CLEAR)
    or a
    jp nz,stage_clear_wait
    ld a,(TICK_CREDIT)
    or a
    jp z,main_loop
    dec a
    ld (TICK_CREDIT),a
    ld (SKIP_RENDER),a        ; render only the last owed tick
    call game_tick
    call hud_draw
    xor a
    ld (SKIP_RENDER),a
    ; frames that elapsed during the tick are counted before halting again
    jp main_after_halt
main_paused:
    xor a
    ld (TICK_CREDIT),a
    jp main_loop

sched_reset:
    ld a,(JIFFY)
    ld (LAST_JIFFY),a
    xor a
    ld (TICK_CREDIT),a
    ld (SKIP_RENDER),a
    ret

sched_frames:
    ld a,(LAST_JIFFY)
    ld c,a
    ld a,(JIFFY)
    ld (LAST_JIFFY),a
    sub c
    ret z
    cp 5
    jp c,sched_count_ok
    ld a,4
sched_count_ok:
    ld b,a
sched_frame_loop:
    ld a,(IS_PAL)
    or a
    jp z,sched_ntsc
    ld a,(FRAME_PHASE)
    inc a
    cp 3
    jp c,sched_pal_store
    xor a
sched_pal_store:
    ld (FRAME_PHASE),a
    cp 2
    jp z,sched_next
    jp sched_credit
sched_ntsc:
    ld a,(FRAME_PHASE)
    inc a
    cp 9
    jp c,sched_ntsc_store
    xor a
sched_ntsc_store:
    ld (FRAME_PHASE),a
    and 1
    jp z,sched_credit          ; phases 0,2,4,6,8 tick; 1,3,5,7 idle
    jp sched_next
sched_credit:
    ld a,(TICK_CREDIT)
    cp 2
    jp nc,sched_next
    inc a
    ld (TICK_CREDIT),a
sched_next:
    djnz sched_frame_loop
    ret

check_pause:
    ld a,8
    call SNSMAT
    and 1
    jp nz,pause_released
    ld a,(START_LATCH)
    or a
    ret nz
    ld a,1
    ld (START_LATCH),a
    ld a,(PAUSED)
    xor 1
    ld (PAUSED),a
    or a
    jp z,hide_pause
    ld hl,(PAUSE_PTR_RAM)
    ld de,0x1800
    ld bc,32
    call LDIRVM
    ret
hide_pause:
    call hud_draw
    ret
pause_released:
    xor a
    ld (START_LATCH),a
    ret

stage_clear_wait:
    ld hl,(CLEAR_PTR_RAM)
    ld de,0x1800
    ld bc,32
    call LDIRVM
clear_release:
    xor a
    call GTTRIG
    or a
    jp nz,clear_release
clear_press:
    xor a
    call GTTRIG
    or a
    jp z,clear_press
advance_stage:
    call update_records
    ld a,(CURRENT_STAGE)
    inc a
    cp 7
    jp nc,show_ending
    ld (CURRENT_STAGE),a
    jp stage_loop

show_ending:
    if SMOOTH
    call scroll_fine_reset
    endif
    ld a,7
    ld (CURRENT_STAGE),a
    call update_records
    ld a,(HYB_REC_CLEARS)
    inc a
    jp z,show_ending_sat
    ld (HYB_REC_CLEARS),a
show_ending_sat:
    ld a,COMMON_BANK
    call select_bank
    call DISSCR
    ld a,4
    call CHGMOD
    call load_palette
    ld hl,ENDING_Z0_PTR
    ld de,0x0000
    ld bc,ENDING_Z0_BYTES
    call LDIRVM
    ld hl,ENDING_Z1_PTR
    ld de,0x0800
    ld bc,ENDING_Z1_BYTES
    call LDIRVM
    ld hl,ENDING_Z2_PTR
    ld de,0x1000
    ld bc,ENDING_Z2_BYTES
    call LDIRVM
    ld hl,ENDING_C0_PTR
    ld de,0x2000
    ld bc,ENDING_C0_BYTES
    call LDIRVM
    ld hl,ENDING_C1_PTR
    ld de,0x2800
    ld bc,ENDING_C1_BYTES
    call LDIRVM
    ld hl,ENDING_C2_PTR
    ld de,0x3000
    ld bc,ENDING_C2_BYTES
    call LDIRVM
    ld hl,ENDING_NAMES_PTR
    ld de,0x1800
    ld bc,768
    call LDIRVM
    call ENASCR
ending_release:
    xor a
    call GTTRIG
    or a
    jp nz,ending_release
ending_press:
    xor a
    call GTTRIG
    or a
    jp z,ending_press
    jp game_restart

game_tick:
    ld a,(ANIM_T)
    inc a
    and 31
    ld (ANIM_T),a
    call update_scroll
    ; FIX23 order: scroll/events -> player -> script -> enemies/boss -> bullets -> collisions.
    call escort_events
    call toggle_invincible
    call change_direction
    ld a,(DEATH_T)
    or a
    jp z,alive_tick
    call death_tick
    call update_enemies
    call boss_update
    call update_escorts
    call update_midboss
    call mid_laser_tick
    call update_enemy_bullets
    call render_sprites
    ret
alive_tick:
    call move_player
    call fire_input
    call update_shots
    call spawn_update
    call update_enemies
    call boss_update
    call update_escorts
    call update_midboss
    call mid_laser_tick
    call check_midboss_collisions
    call update_enemy_bullets
    call check_enemy_collisions
    call check_collision
    call render_sprites
    ret

update_scroll:
    ld a,(BOSS_ACTIVE)
    or a
    ret nz
    ld a,(SCROLL_SUB)
    inc a
    cp 8
    jp c,scroll_sub_only
    xor a
    ld (SCROLL_SUB),a
    ld hl,(SCROLL_COL)
    ld a,(SCROLL_MAX)
    ld e,a
    ld a,(SCROLL_MAX+1)
    ld d,a
    or a
    sbc hl,de
    jp nc,scroll_done
    ld hl,(SCROLL_COL)
    inc hl
    ld (SCROLL_COL),hl
    ; Register phase zero BEFORE replacing the 32-column name table.
    ; This prevents carrying the old 7px phase across the 8px boundary.
    if SMOOTH
    call scroll_fine_apply
    endif
    call draw_stage
    jp colwin_fill
scroll_sub_only:
    ld (SCROLL_SUB),a
    if SMOOTH
    call scroll_fine_apply
    endif
scroll_done:
    ret

; H02 smooth-scroll experiment: interpolate the authored 8px tile camera with
; VDP horizontal shift.  Logical timing/events/collisions remain unchanged.
; V9938: R#18 display-adjust (1..7 dots to the left).  Hardware caveat: this
; also adjusts the border / HUD and needs a raster split for perfect fidelity.
; V9958: R#26 + R#27 native horizontal scroll in SCREEN 4; R#25 remains zero.
; Both paths are reversible by setting SMOOTH_SCROLL=0 during the build.
scroll_fine_reset:
    push af
    push bc
    xor a
    ld (SCROLL_SUB),a
    ; Do not clobber the user's vertical display adjustment.
    ld a,(0xFFF1)
    and 0xF0
    ld b,a
    ld c,18
    call WRTVDP
    ld a,(HYB_VDP_ID)
    cp 2
    jp nz,scroll_fine_reset_done
    ld b,0
    ld c,25
    call WRTVDP
    ld b,0
    ld c,26
    call WRTVDP
    ld b,0
    ld c,27
    call WRTVDP
scroll_fine_reset_done:
    pop bc
    pop af
    ret

scroll_fine_apply:
    push af
    push bc
    ld a,(HYB_VDP_ID)
    cp 2
    jp z,scroll_fine_v9958
    ; V9938 horizontal adjustment sign: H=1..7 means left 1..7 dots.
    ; Preserve vertical adjustment high nibble rather than moving up/down.
    ld a,(0xFFF1)
    and 0xF0
    ld b,a
    ld a,(SCROLL_SUB)
    or b
    ld b,a
    ld c,18
    call WRTVDP
    jp scroll_fine_end
scroll_fine_v9958:
    ld a,(SCROLL_SUB)
    or a
    jp z,scroll_fine_v9958_zero
    ; Equivalent displacement: -8 + (8-sub) = -sub pixels.
    ld b,1
    ld c,26
    call WRTVDP
    ld a,8
    ld b,a
    ld a,(SCROLL_SUB)
    ld c,a
    ld a,b
    sub c
    ld b,a
    ld c,27
    call WRTVDP
    jp scroll_fine_end
scroll_fine_v9958_zero:
    ld b,0
    ld c,26
    call WRTVDP
    ld b,0
    ld c,27
    call WRTVDP
scroll_fine_end:
    pop bc
    pop af
    ret

; -----------------------------------------------------------------------------
; FIX23 label_601 escort fighters.  They are spawned after the launch sequence
; at the exact scroll/sub positions from events585, not inside the mothership
; prologue.  Speed 1600 in the original HSPDX engine = 16 px640/tick = 8 native.
escort_events:
    ld a,(CURRENT_STAGE)
    cp 1
    ret nz
    ld a,(SCROLL_COL+1)
    or a
    ret nz
    ld a,(SCROLL_COL)
    cp 0
    jp z,escort_col0
    cp 1
    jp z,escort_col1
    cp 3
    jp z,escort_col3
    ret
escort_col0:
    ld a,(SCROLL_SUB)
    cp 2
    ret nz
    ld hl,ESC0
    ld b,96
    jp spawn_escort
escort_col1:
    ld a,(SCROLL_SUB)
    cp 0
    jp z,escort_c1_a
    cp 4
    ret nz
    ld hl,ESC2
    ld b,116
    jp spawn_escort
escort_c1_a:
    ld hl,ESC1
    ld b,140
    jp spawn_escort
escort_col3:
    ld a,(SCROLL_SUB)
    cp 2
    jp z,escort_c3_a
    cp 6
    ret nz
    ld hl,ESC4
    ld b,140
    jp spawn_escort
escort_c3_a:
    ld hl,ESC3
    ld b,100
spawn_escort:
    ld a,(hl)
    or a
    ret nz
    ld a,1
    ld (hl),a
    inc hl
    ld a,16
    ld (hl),a
    inc hl
    ld (hl),b
    ret

update_escorts:
    ld hl,ESC0
    call update_one_escort
    ld hl,ESC1
    call update_one_escort
    ld hl,ESC2
    call update_one_escort
    ld hl,ESC3
    call update_one_escort
    ld hl,ESC4
    call update_one_escort
    ret
update_one_escort:
    ld a,(hl)
    or a
    ret z
    ld d,h
    ld e,l
    inc hl
    ld a,(hl)
    add a,8
    ld (hl),a
    cp 248
    ret c
    ld h,d
    ld l,e
    xor a
    ld (hl),a
    ret

; -----------------------------------------------------------------------------
; Ocular Sentinel #1/#2 priority events (FIX23 IDs 250/251).  #1 follows the
; original label_374 state sequence in native-pixel units; it is deliberately
; not destructible (the source gives it 9999 HP).
update_midboss:
    ld a,(MID_ACTIVE)
    or a
    ret z
    ; HYBRID fix: mid_laser_tick is already called once per tick by game_tick.
    ; BASE12 also called it here, running FIX23 case 100 at double speed.
    ld a,(MID_KIND)
    cp 2
    jp z,update_midboss2
    ld a,(MID_STATE)
    cp 1
    jp z,mid1_state1
    cp 2
    jp z,mid1_state2
    cp 3
    jp z,mid1_state3
    cp 11
    jp z,mid1_state11
    ; states 4..10 alternate 32-tick holds and the exact 32-step vertical wave
    and 1
    jp z,mid1_wave
    jp mid1_hold
mid1_state1:
    ; FIX23 label_374: x 272 px640 -> native x=104.
    ld a,(MID_X)
    cp 105
    jp c,mid1_s1_done
    sub 8
    ld (MID_X),a
    ret
mid1_s1_done:
    ld a,104
    ld (MID_X),a
    ld a,2
    ld (MID_STATE),a
    xor a
    ld (MID_T),a
    ret
mid1_state2:
    ld a,(MID_T)
    inc a
    ld (MID_T),a
    cp 6
    ret c
    ld a,3
    ld (MID_STATE),a
    xor a
    ld (MID_T),a
    ret
mid1_state3:
    ld a,(ANIM_T)
    and 1
    ret nz
    ld a,(MID_X)
    cp 192
    jp nc,mid1_s3_done
    add a,8
    ld (MID_X),a
    ld a,(MID_T)
    inc a
    ld (MID_T),a
    cp 11
    ret c
mid1_s3_done:
    ld a,192
    ld (MID_X),a
    ld a,4
    ld (MID_STATE),a
    xor a
    ld (MID_T),a
    ret
mid1_hold:
    ; FIX23 label_378: at the start of each hold spawn one type100 beam entity
    ; for each emitter.  BASE12 renders them as exact 192x8 background strips.
    ld a,(MID_T)
    or a
    call z,mid_laser_start
    ld a,(MID_T)
    inc a
    ld (MID_T),a
    cp 32
    ret c
    xor a
    ld (MID_T),a
    ld a,(MID_STATE)
    inc a
    ld (MID_STATE),a
    ret
mid1_wave:
    ; FIX23 label_379: movement and popcorn cadence are gated by GLOBAL anim8,
    ; while en_param (MID_T here) is the 0..31 wave step.
    ld a,(ANIM_T)
    and 1
    ret nz
    ld a,(MID_T)
    ld b,a
    cp 4
    jp c,mid_wave_up
    cp 12
    jp c,mid_wave_down
    cp 20
    jp c,mid_wave_up
    cp 28
    jp c,mid_wave_down
mid_wave_up:
    ld a,(MID_Y)
    cp 8
    jp c,mid_wave_step
    sub 8
    ld (MID_Y),a
    jp mid_wave_step
mid_wave_down:
    ld a,(MID_Y)
    cp 120
    jp nc,mid_wave_step
    add a,8
    ld (MID_Y),a
mid_wave_step:
    ld a,(MID_T)
    ld b,a
    ; Source fires while k<=20 when anim8 is 2 or 6.
    cp 21
    jp nc,mid_wave_no_fire
    ld a,(ANIM_T)
    and 7
    cp 2
    call z,mid1_fire_popcorn
    ld a,(ANIM_T)
    and 7
    cp 6
    call z,mid1_fire_popcorn
mid_wave_no_fire:
    ld a,(MID_T)
    inc a
    ld (MID_T),a
    cp 32
    ret c
    xor a
    ld (MID_T),a
    ld a,(MID_STATE)
    inc a
    ld (MID_STATE),a
    ret

mid_laser_start:
    ld a,1
    ld (MID_LASER_T),a
    jp mid_laser_render

; FIX23 type100 / chr151..154.  The two beams originate at px640 x=64, so in
; native MSX2 coordinates they span x=0..191.  They charge/flicker for 21 ticks,
; become lethal only at source states 22..23, then fade through 153/154.
mid_laser_tick:
    ld a,(MID_LASER_T)
    or a
    ret z
    inc a
    ld (MID_LASER_T),a
    cp 28
    jp c,mid_laser_render
    xor a
    ld (MID_LASER_T),a
    ; Restore both covered name-table rows from the authored stage.
    call draw_stage
    ret

mid_laser_render:
    ld a,(MID_LASER_T)
    cp 22
    jp c,mid_laser_phase0
    cp 24
    jp c,mid_laser_phase1
    cp 26
    jp c,mid_laser_phase2
    ld c,3
    jp mid_laser_phase_ready
mid_laser_phase0:
    ld c,0
    jp mid_laser_phase_ready
mid_laser_phase1:
    ld c,1
    jp mid_laser_phase_ready
mid_laser_phase2:
    ld c,2
mid_laser_phase_ready:
    ld a,c
    ld (TMP_TOKEN),a
    ld a,(MID_Y)
    add a,12
    call mid_laser_draw_line
    ld a,(MID_Y)
    add a,45
    call mid_laser_draw_line
    ; In the source only chr152 (ticks 22..23) carries type128 damage.
    ld a,(MID_LASER_T)
    cp 22
    ret c
    cp 24
    ret nc
    ld a,(INVINCIBLE)
    or a
    ret nz
    ld a,(PLAYER_X)
    cp 192
    ret nc
    ld a,(PLAYER_Y)
    add a,8
    ld b,a
    ld a,(MID_Y)
    add a,12
    call mid_laser_hit_y
    or a
    jp nz,trigger_death
    ld a,(MID_Y)
    add a,45
    call mid_laser_hit_y
    or a
    jp nz,trigger_death
    ret

; A=beam y, B=player centre y. Return A=1 if within the 8px laser strip.
mid_laser_hit_y:
    ld c,a
    ld a,b
    sub c
    jp nc,mlhy_pos
    cpl
    inc a
mlhy_pos:
    cp 9
    jp nc,mlhy_no
    ld a,1
    ret
mlhy_no:
    xor a
    ret

; A=screen y. Draw the exact 24-tile source row for current phase.  Laser rows
; are packed zone-major: 3 zones * 4 phases * 24 bytes in Stage-1 data bank.
mid_laser_draw_line:
    ld (DRAW_ROW),a
    srl a
    srl a
    srl a
    ld b,a                      ; name-table row 0..23
    ; VRAM destination = 1800h + row*32.
    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,0x1800
    add hl,de
    ld (DRAW_VRAM),hl
    ; Source pointer = base + zone*96 + phase*24.
    ld hl,(MID_LASER_PTR)
    ld a,b
    cp 8
    jp c,mld_zone_ready
    cp 16
    jp c,mld_zone1
    ld de,192
    add hl,de
    jp mld_zone_ready
mld_zone1:
    ld de,96
    add hl,de
mld_zone_ready:
    ld a,(TMP_TOKEN)
    or a
    jp z,mld_phase_ready
    ld de,24
mld_phase_add:
    add hl,de
    dec a
    jp nz,mld_phase_add
mld_phase_ready:
    ld (BANK_SRC),hl
    call restore_data_bank
    ld hl,(BANK_SRC)
    ld a,(DRAW_VRAM)
    ld e,a
    ld a,(DRAW_VRAM+1)
    ld d,a
    ld bc,24
    call LDIRVM
    ret

mid1_fire_popcorn:
    ; FIX23 label_379: ID3 at (x+32,y+56) px640 => (+16,+28) native,
    ; direction 45+rnd(7), speed 800 => native 4px vector table.
    ld a,(RNG_STATE)
    rrca
    xor 0xB8
    ld (RNG_STATE),a
    and 7
    cp 7
    jp nz,mfp_dir_ok
    xor a
mfp_dir_ok:
    add a,45
    ld (TMP_PARAM),a
    ld a,30
    ld (TMP_KIND),a
    ld a,(MID_X)
    add a,16
    ld (TMP_X),a
    ld a,(MID_Y)
    add a,28
    ld (TMP_Y),a
    ld a,1
    ld (TMP_HP),a
    call spawn_manual_enemy_exact
    ret

mid1_state11:
    ld a,(MID_T)
    cp 4
    jp c,mid11_advance
    cp 7
    jp c,mid11_down
    cp 18
    jp c,mid11_advance
    ld a,(MID_Y)
    cp 8
    jp c,midboss_end
    sub 8
    ld (MID_Y),a
    jp mid11_advance
mid11_down:
    ld a,(MID_Y)
    cp 120
    jp nc,mid11_advance
    add a,8
    ld (MID_Y),a
mid11_advance:
    ld a,(MID_T)
    inc a
    ld (MID_T),a
    ret
midboss_end:
    xor a
    ld (MID_ACTIVE),a
    ld a,(MID_LASER_T)
    or a
    ret z
    xor a
    ld (MID_LASER_T),a
    call draw_stage
    ret

; Sentinel #2 (label_381) enters from the ceiling later in World 1.  The full
; ceiling-break debris is still compacted, but the complete sentinel graphic and
; its entrance/exit are now guaranteed instead of being droppable.
update_midboss2:
    ; FIX23 label_381, translated from px640 to native coordinates.
    ld a,(MID_STATE)
    cp 1
    jp z,mid2_state1
    cp 2
    jp z,mid2_state2
    cp 12
    jp z,mid2_state12
    cp 32
    jp nc,mid2_patrol
    ; States 3..11 and 13..31 are one-tick holds.
    inc a
    ld (MID_STATE),a
    ret
mid2_state1:
    ; Impact / roof break tick: source y += 16px640 (=8 native).
    ld a,(MID_Y)
    add a,8
    ld (MID_Y),a
    ld a,2
    ld (MID_STATE),a
    ret
mid2_state2:
    ; Descend until source y>=208px640 => screen y=80 native.
    ld a,(MID_Y)
    cp 80
    jp nc,mid2_state2_done
    add a,8
    ld (MID_Y),a
    ret
mid2_state2_done:
    ld a,3
    ld (MID_STATE),a
    ret
mid2_state12:
    ; Rise to source y<=176px640 => screen y=64 native.
    ld a,(MID_Y)
    cp 65
    jp c,mid2_state12_done
    sub 8
    ld (MID_Y),a
    ret
mid2_state12_done:
    ld a,13
    ld (MID_STATE),a
    ret
mid2_patrol:
    ; Twice the terrain scroll: -8 native at scroll_sub 0 and 4.
    ld a,(SCROLL_SUB)
    cp 0
    jp z,mid2_move_left
    cp 4
    jp nz,mid2_fire_check
mid2_move_left:
    ld a,(MID_X)
    cp 9
    jp c,midboss_end
    sub 8
    ld (MID_X),a
mid2_fire_check:
    ; Source only emits mines while x>128px640 => x>32 native.
    ld a,(MID_X)
    cp 33
    jp c,mid2_advance_state
    ld a,(MID_STATE)
    cp 40
    jp z,mid2_spawn_mine_top
    cp 60
    jp z,mid2_spawn_mine_bottom
    jp mid2_advance_state
mid2_spawn_mine_top:
    ld a,(MID_X)
    add a,24
    ld (TMP_X),a
    ld a,(MID_Y)
    add a,12
    ld (TMP_Y),a
    jp mid2_spawn_mine
mid2_spawn_mine_bottom:
    ld a,(MID_X)
    add a,24
    ld (TMP_X),a
    ld a,(MID_Y)
    add a,36
    ld (TMP_Y),a
mid2_spawn_mine:
    ld a,28
    ld (TMP_KIND),a
    ld a,255
    ld (TMP_HP),a
    xor a
    ld (TMP_PARAM),a
    call spawn_manual_enemy_exact
mid2_advance_state:
    ld a,(MID_STATE)
    inc a
    cp 72
    jp c,mid2_store_state
    ld a,32
mid2_store_state:
    ld (MID_STATE),a
    ret

toggle_invincible:
    ld a,3
    call SNSMAT
    and 1
    jp nz,inv_released
    ld a,(INV_LATCH)
    or a
    ret nz
    ld a,1
    ld (INV_LATCH),a
    ld a,(INVINCIBLE)
    xor 1
    ld (INVINCIBLE),a
    ret
inv_released:
    xor a
    ld (INV_LATCH),a
    ret

change_direction:
    ld a,3
    call GTTRIG
    or a
    jp nz,dir_pressed
    ld a,5
    call SNSMAT
    and 32
    jp z,dir_pressed
    xor a
    ld (DIR_LATCH),a
    ret
dir_pressed:
    ld a,(DIR_LATCH)
    or a
    ret nz
    ld a,1
    ld (DIR_LATCH),a
    ld a,(SHOT_DIR)
    inc a
    cp 4
    jp c,dir_store
    xor a
dir_store:
    ld (SHOT_DIR),a
    ret

move_player:
    xor a
    ld (PLAYER_FRAME),a
    ld a,1
    call GTSTCK
    or a
    jp nz,move_have
    xor a
    call GTSTCK
move_have:
    ld (STICK_TMP),a
    cp 1
    jp z,move_up4
    cp 2
    jp z,move_ur3
    cp 3
    jp z,move_right4
    cp 4
    jp z,move_dr3
    cp 5
    jp z,move_down4
    cp 6
    jp z,move_dl3
    cp 7
    jp z,move_left4
    cp 8
    jp z,move_ul3
    ret
move_up4:
    ld a,1
    ld (PLAYER_FRAME),a
    ld a,(PLAYER_Y)
    cp 12
    jp c,set_y_min
    sub 4
    ld (PLAYER_Y),a
    ret
move_down4:
    ld a,2
    ld (PLAYER_FRAME),a
    ld a,(PLAYER_Y)
    cp 165
    jp nc,set_y_max
    add a,4
    ld (PLAYER_Y),a
    ret
move_left4:
    ld a,(PLAYER_X)
    cp 4
    jp c,set_x_min
    sub 4
    ld (PLAYER_X),a
    ret
move_right4:
    ld a,(PLAYER_X)
    cp 221
    jp nc,set_x_max
    add a,4
    ld (PLAYER_X),a
    ret
move_ur3:
    ld a,1
    ld (PLAYER_FRAME),a
    call move_right3
    jp move_up3
move_dr3:
    ld a,2
    ld (PLAYER_FRAME),a
    call move_right3
    jp move_down3
move_dl3:
    ld a,2
    ld (PLAYER_FRAME),a
    call move_left3
    jp move_down3
move_ul3:
    ld a,1
    ld (PLAYER_FRAME),a
    call move_left3
    jp move_up3
move_right3:
    ld a,(PLAYER_X)
    cp 222
    jp nc,set_x_max
    add a,3
    ld (PLAYER_X),a
    ret
move_left3:
    ld a,(PLAYER_X)
    cp 3
    jp c,set_x_min
    sub 3
    ld (PLAYER_X),a
    ret
move_up3:
    ld a,(PLAYER_Y)
    cp 11
    jp c,set_y_min
    sub 3
    ld (PLAYER_Y),a
    ret
move_down3:
    ld a,(PLAYER_Y)
    cp 166
    jp nc,set_y_max
    add a,3
    ld (PLAYER_Y),a
    ret
set_x_min:
    xor a
    ld (PLAYER_X),a
    ret
set_x_max:
    ld a,224
    ld (PLAYER_X),a
    ret
set_y_min:
    ld a,8
    ld (PLAYER_Y),a
    ret
set_y_max:
    ld a,168
    ld (PLAYER_Y),a
    ret

fire_input:
    ; Original cadence: one front+rear attempt every 3 logical ticks while held.
    ld a,(SHOT_COOL)
    or a
    jp z,fire_read_input
    dec a
    ld (SHOT_COOL),a
fire_read_input:
    ld a,1
    call GTTRIG
    or a
    jp nz,fire_pressed
    ; Keyboard Z, same matrix bit used by the previous MSX2 build.
    ld a,5
    call SNSMAT
    and 128
    ret nz
fire_pressed:
    ld a,(SHOT_COOL)
    or a
    ret nz
    call spawn_shots
    ld a,3
    ld (SHOT_COOL),a
    ret

spawn_shots:
    ; HSP source quantises the projectile origin to a 16px640 cell = 8 native px.
    ld a,(PLAYER_X)
    add a,4
    and 0xF8
    ld (TMP_X),a
    ld a,(PLAYER_Y)
    add a,4
    and 0xF8
    ld (TMP_Y),a
    ; Front group: records 0..2, vector 0..3.
    ld hl,SHOT_BASE
    ld a,(SHOT_DIR)
    call spawn_one_player_shot
    ; Rear group: records 3..5, vector 4..7.
    ld hl,SHOT_BASE+12
    ld a,(SHOT_DIR)
    add a,4
    call spawn_one_player_shot
    ret

; A=vector 0..7, HL=first record of a 3-record group.
spawn_one_player_shot:
    ld (TMP_PARAM),a
    ld b,3
sops_find:
    ld a,(hl)
    or a
    jp z,sops_fill
    ld de,SHOT_REC_SIZE
    add hl,de
    djnz sops_find
    ret
sops_fill:
    ld (SHOT_PTR),hl
    ld a,(TMP_PARAM)
    call shot_spawn_coords
    ; D=x, E=y. Wrapped/offscreen starts are discarded like the HSP window clip.
    ld a,d
    cp 248
    ret nc
    ld a,e
    cp 184
    ret nc
    ld hl,(SHOT_PTR)
    ld a,1
    ld (hl),a
    inc hl
    ld (hl),d
    inc hl
    ld (hl),e
    inc hl
    ld a,(TMP_PARAM)
    ld (hl),a
    ret

; A=vector, returns D=x/E=y using the exact native offsets from the GDD.
shot_spawn_coords:
    ld b,a
    ld a,(TMP_X)
    ld d,a
    ld a,(TMP_Y)
    ld e,a
    ld a,b
    cp 0
    jp z,ssc_vf
    cp 1
    jp z,ssc_sf
    cp 2
    jp z,ssc_hf
    cp 3
    jp z,ssc_bf
    cp 4
    jp z,ssc_vr
    cp 5
    jp z,ssc_sr
    cp 6
    jp z,ssc_hr
    ; vector 7: rear backslash = -12,-12
    ld a,d
    sub 12
    ld d,a
    ld a,e
    sub 12
    ld e,a
    ret
ssc_vf:
    ld a,e
    sub 20
    ld e,a
    ret
ssc_sf:
    ld a,d
    add a,12
    ld d,a
    ld a,e
    sub 12
    ld e,a
    ret
ssc_hf:
    ld a,d
    add a,20
    ld d,a
    ret
ssc_bf:
    ld a,d
    add a,12
    ld d,a
    ld a,e
    add a,12
    ld e,a
    ret
ssc_vr:
    ld a,e
    add a,20
    ld e,a
    ret
ssc_sr:
    ld a,d
    sub 12
    ld d,a
    ld a,e
    add a,12
    ld e,a
    ret
ssc_hr:
    ld a,d
    sub 20
    ld d,a
    ret

update_shots:
    ld hl,SHOT_BASE
    ld b,SHOT_COUNT
update_shots_loop:
    push bc
    push hl
    call update_one_player_shot
    pop hl
    ld de,SHOT_REC_SIZE
    add hl,de
    pop bc
    djnz update_shots_loop
    ret

update_one_player_shot:
    ld a,(hl)
    or a
    ret z
    ld (SHOT_PTR),hl
    ld de,3
    add hl,de
    ld a,(hl)
    ld (TMP_PARAM),a
    ; Move at source speed 3200 = 16 native px/tick. Diagonal components use 11.
    cp 0
    jp z,ups_vf
    cp 1
    jp z,ups_sf
    cp 2
    jp z,ups_hf
    cp 3
    jp z,ups_bf
    cp 4
    jp z,ups_vr
    cp 5
    jp z,ups_sr
    cp 6
    jp z,ups_hr
    jp ups_br
ups_vf:
    ld hl,(SHOT_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 16
    jp c,player_shot_kill
    sub 16
    ld (hl),a
    jp ups_after_move
ups_sf:
    ld hl,(SHOT_PTR)
    inc hl
    ld a,(hl)
    cp 237
    jp nc,player_shot_kill
    add a,11
    ld (hl),a
    inc hl
    ld a,(hl)
    cp 11
    jp c,player_shot_kill
    sub 11
    ld (hl),a
    jp ups_after_move
ups_hf:
    ld hl,(SHOT_PTR)
    inc hl
    ld a,(hl)
    cp 232
    jp nc,player_shot_kill
    add a,16
    ld (hl),a
    jp ups_after_move
ups_bf:
    ld hl,(SHOT_PTR)
    inc hl
    ld a,(hl)
    cp 237
    jp nc,player_shot_kill
    add a,11
    ld (hl),a
    inc hl
    ld a,(hl)
    cp 173
    jp nc,player_shot_kill
    add a,11
    ld (hl),a
    jp ups_after_move
ups_vr:
    ld hl,(SHOT_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 168
    jp nc,player_shot_kill
    add a,16
    ld (hl),a
    jp ups_after_move
ups_sr:
    ld hl,(SHOT_PTR)
    inc hl
    ld a,(hl)
    cp 11
    jp c,player_shot_kill
    sub 11
    ld (hl),a
    inc hl
    ld a,(hl)
    cp 173
    jp nc,player_shot_kill
    add a,11
    ld (hl),a
    jp ups_after_move
ups_hr:
    ld hl,(SHOT_PTR)
    inc hl
    ld a,(hl)
    cp 16
    jp c,player_shot_kill
    sub 16
    ld (hl),a
    jp ups_after_move
ups_br:
    ld hl,(SHOT_PTR)
    inc hl
    ld a,(hl)
    cp 11
    jp c,player_shot_kill
    sub 11
    ld (hl),a
    inc hl
    ld a,(hl)
    cp 11
    jp c,player_shot_kill
    sub 11
    ld (hl),a
ups_after_move:
    call shot_hits_map_exact
    or a
    jp nz,player_shot_kill
    ret
player_shot_kill:
    ld hl,(SHOT_PTR)
    xor a
    ld (hl),a
    ret

; Exact GDD shot/tile sample geometry in native pixels. Returns A=1 if attr 1/4.
shot_hits_map_exact:
    ld hl,(SHOT_PTR)
    inc hl
    ld a,(hl)
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    ld (TMP_Y),a
    ld a,(TMP_PARAM)
    and 3
    cp 0
    jp z,shm_vertical
    cp 1
    jp z,shm_slash
    cp 2
    jp z,shm_horizontal
    jp shm_backslash
shm_vertical:
    ld a,(TMP_X)
    add a,8
    ld (CHECK_X),a
    ld a,(TMP_Y)
    cp 8
    jp c,shm_v2
    sub 8
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
shm_v2:
    ld a,(TMP_X)
    add a,8
    ld (CHECK_X),a
    ld a,(TMP_Y)
    add a,4
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
    ld a,(TMP_X)
    add a,8
    ld (CHECK_X),a
    ld a,(TMP_Y)
    cp 168
    jp nc,shm_clear
    add a,16
    ld (CHECK_Y),a
    jp shot_point_blocked
shm_slash:
    ld a,(TMP_X)
    cp 240
    jp nc,shm_s2
    add a,16
    ld (CHECK_X),a
    ld a,(TMP_Y)
    cp 8
    jp c,shm_s2
    sub 8
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
shm_s2:
    ld a,(TMP_X)
    add a,4
    ld (CHECK_X),a
    ld a,(TMP_Y)
    add a,4
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
    ld a,(TMP_X)
    cp 8
    jp c,shm_clear
    sub 8
    ld (CHECK_X),a
    ld a,(TMP_Y)
    cp 168
    jp nc,shm_clear
    add a,16
    ld (CHECK_Y),a
    jp shot_point_blocked
shm_backslash:
    ld a,(TMP_X)
    cp 240
    jp nc,shm_b2
    add a,16
    ld (CHECK_X),a
    ld a,(TMP_Y)
    cp 168
    jp nc,shm_b2
    add a,16
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
shm_b2:
    ld a,(TMP_X)
    add a,4
    ld (CHECK_X),a
    ld a,(TMP_Y)
    add a,4
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
    ld a,(TMP_X)
    cp 8
    jp c,shm_clear
    sub 8
    ld (CHECK_X),a
    ld a,(TMP_Y)
    cp 8
    jp c,shm_clear
    sub 8
    ld (CHECK_Y),a
    jp shot_point_blocked
shm_horizontal:
    ; six source samples: x=-8,+4,+16 crossed with y=+4,+12.
    ld a,(TMP_X)
    cp 8
    jp c,shm_h_x2
    sub 8
    ld (CHECK_X),a
    ld a,(TMP_Y)
    add a,4
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
    ld a,(TMP_Y)
    add a,12
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
shm_h_x2:
    ld a,(TMP_X)
    add a,4
    ld (CHECK_X),a
    ld a,(TMP_Y)
    add a,4
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
    ld a,(TMP_Y)
    add a,12
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
    ld a,(TMP_X)
    cp 240
    jp nc,shm_clear
    add a,16
    ld (CHECK_X),a
    ld a,(TMP_Y)
    add a,4
    ld (CHECK_Y),a
    call shot_point_blocked
    or a
    ret nz
    ld a,(TMP_Y)
    add a,12
    ld (CHECK_Y),a
    jp shot_point_blocked
shm_clear:
    xor a
    ret

; CHECK_X/CHECK_Y is an absolute MSX screen point. Playfield starts at y=8.
shot_point_blocked:
    ld a,(CHECK_Y)
    cp 8
    jp c,spb_clear
    cp 184
    jp nc,spb_clear
    sub 8
    srl a
    srl a
    srl a
    cp 22
    jp nc,spb_clear
    ; HYBRID: CHECK_X/8 is always 0..31, inside the decoded collision window,
    ; so index it directly (identical result to collision_at).
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,(CHECK_X)
    rrca
    rrca
    rrca
    and 31
    ld b,a
    ld a,(SCROLL_COL)
    add a,b
    and 63
    ld e,a
    ld d,0
    add hl,de
    ld de,COLWIN
    add hl,de
    ld a,(hl)
    cp 1
    jp z,spb_yes
    cp 4
    jp z,spb_yes
spb_clear:
    xor a
    ret
spb_yes:
    ld a,1
    ret

; -----------------------------------------------------------------------------
; Stage-1 script interpreter. BASE09 preserves the FIX23 source script step
; exactly: one script step every four gameplay ticks. Records are
; [step16, kind, x, y, hp, param]. Other stages keep the BASE08 compact path.
spawn_update:
    ld a,(CURRENT_STAGE)
    cp 1
    jp nz,spawn_update_compact
    call spawn1_step
    ret

spawn1_step:
    ld a,(SCRIPT_DIV)
    or a
    jp nz,spawn1_advance_div
spawn1_loop:
    ld hl,(SPAWN_PTR)
    ld a,(hl)
    ld b,a
    inc hl
    ld a,(hl)
    ld c,a
    inc hl
    ld a,b
    cp 0xFF
    jp nz,spawn1_compare
    ld a,c
    cp 0xFF
    jp z,spawn1_advance_div
spawn1_compare:
    ; Return from the parse loop if the next authored step is still in future.
    ld a,(SCRIPT_STEP+1)
    cp c
    jp c,spawn1_advance_div
    jp nz,spawn1_due
    ld a,(SCRIPT_STEP)
    cp b
    jp c,spawn1_advance_div
spawn1_due:
    ld a,(hl)
    ld (TMP_KIND),a
    inc hl
    ld a,(hl)
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    ld (TMP_Y),a
    inc hl
    ld a,(hl)
    ld (TMP_HP),a
    inc hl
    ld a,(hl)
    ld (TMP_PARAM),a
    inc hl
    ld (CMP_PTR),hl            ; next record; commit only after successful spawn

    ld a,(TMP_KIND)
    cp 10
    jp z,spawn1_mid1
    cp 11
    jp z,spawn1_mid2
    cp 13
    jp nz,spawn1_find
    ; Already collected stones never respawn.
    ld a,(TMP_PARAM)
    ld e,a
    ld d,0
    ld hl,STONE_GOT
    add hl,de
    ld a,(hl)
    or a
    jp nz,spawn1_commit_skip
spawn1_find:
    ld hl,EN_BASE
    ld b,EN_COUNT
spawn1_find_loop:
    ld a,(hl)
    or a
    jp z,spawn1_store
    ld de,7
    add hl,de
    djnz spawn1_find_loop
    ; Never discard authored traffic. Retry this same record next gameplay tick.
    jp spawn1_advance_div
spawn1_store:
    ld a,1
    ld (hl),a
    inc hl
    ld a,(TMP_X)
    ld (hl),a
    inc hl
    ld a,(TMP_Y)
    ld (hl),a
    inc hl
    ld a,(TMP_KIND)
    ld (hl),a
    inc hl
    ld a,1
    ld (hl),a
    inc hl
    ld a,(TMP_HP)
    ld (hl),a
    inc hl
    ld a,(TMP_PARAM)
    ld (hl),a
spawn1_commit_skip:
    ld hl,(CMP_PTR)
    ld (SPAWN_PTR),hl
    jp spawn1_loop
spawn1_mid1:
    ld a,1
    ld (MID_ACTIVE),a
    ld (MID_KIND),a
    ld a,(TMP_X)
    ld (MID_X),a
    ld a,(TMP_Y)
    ld (MID_Y),a
    ld a,1
    ld (MID_STATE),a
    xor a
    ld (MID_T),a
    call load_sentinel_colors
    jp spawn1_commit_skip
spawn1_mid2:
    ld a,1
    ld (MID_ACTIVE),a
    ld a,2
    ld (MID_KIND),a
    ld a,(TMP_X)
    ld (MID_X),a
    ld a,(TMP_Y)
    ld (MID_Y),a
    ld a,1
    ld (MID_STATE),a
    xor a
    ld (MID_T),a
    call load_sentinel_colors
    jp spawn1_commit_skip
spawn1_advance_div:
    ld a,(SCRIPT_DIV)
    inc a
    and 3
    ld (SCRIPT_DIV),a
    ret nz
    ld hl,(SCRIPT_STEP)
    inc hl
    ld (SCRIPT_STEP),hl
    ret

; BASE08 compact schedule remains for stages 2..6 alpha.
spawn_update_compact:
spawn_loop:
    ld hl,(SPAWN_PTR)
    ld a,(hl)
    ld b,a
    inc hl
    ld a,(hl)
    ld c,a
    inc hl
    ld a,b
    cp 0xFF
    jp nz,spawn_not_end
    ld a,c
    cp 0xFF
    ret z
spawn_not_end:
    ld a,(SCROLL_COL+1)
    cp c
    ret c
    jp nz,spawn_due
    ld a,(SCROLL_COL)
    cp b
    ret c
spawn_due:
    ld a,(hl)
    ld (TMP_KIND),a
    inc hl
    ld a,(hl)
    ld (TMP_Y),a
    inc hl
    ld a,(hl)
    ld (TMP_SPEED),a
    inc hl
    ld a,(hl)
    ld (TMP_PARAM),a
    inc hl
    ld (SPAWN_PTR),hl
    ld a,(TMP_KIND)
    cp 10
    jp z,spawn_midboss1
    cp 11
    jp z,spawn_midboss2
    cp 5
    jp nz,spawn_normal
    ; Do not respawn an already collected Volca-Stone.
    ld a,(TMP_PARAM)
    ld e,a
    ld d,0
    ld hl,STONE_GOT
    add hl,de
    ld a,(hl)
    or a
    jp nz,spawn_loop
spawn_normal:
    ; BASE12 deep parity: the original HSPDX engine has forty logical
    ; enemy records. Search all forty before dropping a script spawn.
    ld hl,EN_BASE
    ld b,EN_COUNT
spawn_find_free40:
    ld a,(hl)
    or a
    jp z,spawn_fill_free40
    ld de,EN_REC_SIZE
    add hl,de
    djnz spawn_find_free40
    jp spawn_loop
spawn_fill_free40:
    ld a,1
    ld (hl),a
    inc hl
    ld a,248
    ld (hl),a
    inc hl
    ld a,(TMP_Y)
    ld (hl),a
    inc hl
    ld a,(TMP_KIND)
    ld (hl),a
    inc hl
    xor a
    ld (hl),a
    inc hl
    ld a,(TMP_SPEED)
    ld (hl),a
    inc hl
    ld a,(TMP_PARAM)
    ld (hl),a
    jp spawn_loop
spawn_midboss1:
    ld a,1
    ld (MID_ACTIVE),a
    ld (MID_KIND),a
    ld a,248
    ld (MID_X),a
    ld a,(TMP_Y)
    ld (MID_Y),a
    ld a,1
    ld (MID_STATE),a
    xor a
    ld (MID_T),a
    call load_sentinel_colors
    jp spawn_loop
spawn_midboss2:
    ld a,1
    ld (MID_ACTIVE),a
    ld a,2
    ld (MID_KIND),a
    ; FIX23 label_381: source x=320px640 -> native playfield x=128.
    ld a,128
    ld (MID_X),a
    ; Source y=-32px640 starts above the playfield.  Clamp to the first visible
    ; row; the state machine immediately descends by 8 native px/tick.
    xor a
    ld (MID_Y),a
    ld a,1
    ld (MID_STATE),a
    xor a
    ld (MID_T),a
    call load_sentinel_colors
    jp spawn_loop
load_sentinel_colors:
    ld a,COMMON_BANK
    call select_bank
    ld hl,game_sentinel_sprite_colors
    ld de,0x1C80
    ld bc,GAME_SENTINEL_COLOR_BYTES
    call LDIRVM
    call slot_color_invalidate
    call restore_data_bank
    ret

update_enemies:
    ld hl,EN_BASE
    ld b,EN_COUNT
update_enemies_loop:
    push bc
    push hl
    call update_enemy
    pop hl
    ld de,EN_REC_SIZE
    add hl,de
    pop bc
    djnz update_enemies_loop
    ret

; BASE09 Stage-1 behaviour records: active,x,y,kind,state,hp,param.
; active=2 is the canonical 8-tick four-frame death explosion.
update_enemy:
    ld a,(hl)
    or a
    ret z
    ld (EN_PTR),hl
    cp 2
    jp z,enemy_death_update
    ld de,3
    add hl,de
    ld a,(hl)
    cp 1
    jp z,en_type4
    cp 2
    jp z,en_type12
    cp 3
    jp z,en_type7
    cp 4
    jp z,en_type8
    cp 5
    jp z,en_type5
    cp 6
    jp z,en_type6
    cp 7
    jp z,en_type105
    cp 8
    jp z,en_type103
    cp 9
    jp z,en_type101
    cp 12
    jp z,en_type102
    cp 13
    jp z,en_type99
    cp 14
    jp z,en_type10
    cp 15
    jp z,en_type11
    cp 16
    jp z,en_type106
    cp 17
    jp z,en_type107
    cp 18
    jp z,en_type125
    cp 19
    jp z,en_type200
    cp 20
    jp z,en_warning
    cp 21
    jp z,en_warning
    cp 22
    jp z,en_type303
    cp 23
    jp z,en_type199
    cp 24
    jp z,en_boss108
    cp 25
    jp z,en_boss14
    cp 26
    jp z,en_boss109
    cp 27
    jp z,en_boss110
    cp 28
    jp z,en_mid2_mine
    cp 29
    jp z,en_id2_missile
    cp 30
    jp z,en_id3_popcorn
    cp 31
    jp z,en_id9_vent
    cp 32
    jp z,en_id64_capsule
    ret

en_type4:
    ld a,(ANIM_T)
    and 1
    jp nz,enemy_bounds
    call enemy_scroll_left8
    jp enemy_bounds

en_type7:
    ld b,22
    call enemy_arc_inc
    call enemy_apply_dir6
    jp enemy_bounds
en_type8:
    ld b,22
    call enemy_arc_dec
    call enemy_apply_dir6
    jp enemy_bounds
en_type5:
    ld b,20
    call enemy_arc_inc
    call enemy_apply_dir6
    jp enemy_bounds
en_type6:
    ld b,26
    call enemy_arc_dec
    call enemy_apply_dir6
    jp enemy_bounds

enemy_arc_inc:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    cp b
    jp c,earci_store
    dec a
    ld (hl),a
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    inc a
    and 63
    cp 29
    jp nz,earci_param
    ld a,28
earci_param:
    ld (hl),a
    ret
earci_store:
    ld (hl),a
    ret

enemy_arc_dec:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    cp b
    jp c,earcd_store
    dec a
    ld (hl),a
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    or a
    jp nz,earcd_nonzero
    ld a,64
earcd_nonzero:
    dec a
    cp 3
    jp nz,earcd_param
    ld a,4
earcd_param:
    ld (hl),a
    ret
earcd_store:
    ld (hl),a
    ret

enemy_apply_dir6:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    ld e,a
    ld d,0
    ld hl,dir_dx6
    add hl,de
    ld b,(hl)
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,b
    ld (hl),a
    ld hl,dir_dy6
    add hl,de
    ld b,(hl)
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    add a,b
    ld (hl),a
    ret

enemy_apply_dir4:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    ld e,a
    ld d,0
    ld hl,dir_dx4
    add hl,de
    ld b,(hl)
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,b
    ld (hl),a
    ld hl,dir_dy4
    add hl,de
    ld b,(hl)
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    add a,b
    ld (hl),a
    ret

en_type12:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    cp 29
    jp c,en12_state_ok
    ld a,1
en12_state_ok:
    ld e,a
    ld d,0
    ld hl,wave12_native
    add hl,de
    ld b,(hl)
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    add a,b
    ld (hl),a
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    or a
    jp nz,en12_right
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    sub 3
    ld (hl),a
    jp en12_next
en12_right:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,3
    ld (hl),a
en12_next:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    cp 29
    jp c,en12_store
    ld a,1
en12_store:
    ld (hl),a
    jp enemy_bounds

en_type105:
    ld a,(ANIM_T)
    and 1
    jp nz,enemy_bounds
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    cp 1
    jp nz,en105_started
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp 8
    jp c,enemy_kill_current
    sub 8
    ld (hl),a
    ld b,a
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld c,(hl)
    ld a,b
    cp c
    jp nc,enemy_bounds
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,2
    ld (hl),a
    jp enemy_bounds
en105_started:
    inc a
    ld (hl),a
    cp 6
    jp z,en105_fire
    cp 9
    jp z,en105_fire
    cp 20
    jp c,enemy_bounds
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,8
    ld (hl),a
    jp enemy_bounds
en105_fire:
    call enemy_spawn_pair_left
    jp enemy_bounds

en_type103:
    call enemy_scroll_left8_if_col
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    ld (hl),a
    jp enemy_bounds

en_type101:
    call enemy_scroll_left8_if_col
    call vent_tick_up
    jp enemy_bounds
en_type102:
    call enemy_scroll_left8_if_col
    call vent_tick_down
    jp enemy_bounds

vent_tick_up:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    cp 80
    jp c,vent_up_store
    xor a
vent_up_store:
    ld (hl),a
    cp 34
    jp z,vent_fire_up
    cp 42
    jp z,vent_fire_up
    cp 50
    jp z,vent_fire_up
    ret
vent_fire_up:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,4
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    sub 6
    ld (TMP_Y),a
    ld a,31
    ld (TMP_KIND),a
    ld a,255
    ld (TMP_HP),a
    xor a
    ld (TMP_PARAM),a
    jp spawn_manual_enemy_exact

vent_tick_down:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    cp 80
    jp c,vent_down_store
    xor a
vent_down_store:
    ld (hl),a
    cp 34
    jp z,vent_fire_down
    cp 42
    jp z,vent_fire_down
    cp 50
    jp z,vent_fire_down
    ret
vent_fire_down:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,4
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    add a,15
    ld (TMP_Y),a
    ld a,31
    ld (TMP_KIND),a
    ld a,255
    ld (TMP_HP),a
    ld a,1
    ld (TMP_PARAM),a
    jp spawn_manual_enemy_exact

en_type99:
    ; Hidden Volca-Stone trigger. It deliberately has no visible sprite.
    call enemy_scroll_left8_if_col
    jp enemy_bounds

en_type10:
    call enemy_apply_dir4
    call enemy_projectile_terrain
    jp enemy_bounds
en_type11:
    call enemy_apply_dir4
    call enemy_projectile_terrain
    jp enemy_bounds

en_type106:
    call enemy_scroll_left8_if_col
    jp enemy_bounds
en_type107:
    call enemy_scroll_left8_if_col
    jp enemy_bounds

en_type125:
    call enemy_scroll_left8_if_col
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    cp 57
    jp c,en125_store
    ld a,1
en125_store:
    ld (hl),a
    cp 36
    jp nz,enemy_bounds
    ; Source requires x>200px640 => native local x>68.
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp 69
    jp c,enemy_bounds
    ld a,(hl)
    add a,3
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    ld b,a
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    or a
    jp nz,en125_child_down
    ld a,b
    sub 2
    ld (TMP_Y),a
    xor a
    jp en125_child_spawn
en125_child_down:
    ld a,b
    add a,8
    ld (TMP_Y),a
    ld a,1
en125_child_spawn:
    ld (TMP_PARAM),a
    ld a,32
    ld (TMP_KIND),a
    ld a,5                 ; source HP50 / 10
    ld (TMP_HP),a
    call spawn_manual_enemy_exact
    jp enemy_bounds

en_type200:
    call enemy_scroll_left8_if_col
    ld a,(ANIM_T)
    cp 2
    jp z,en200_phase
    cp 6
    jp nz,enemy_bounds
en200_phase:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    inc a
    cp 18
    jp c,en200_param_ok
    ld a,2
en200_param_ok:
    ld (hl),a
    ld b,a
    cp 2
    jp c,en200_firecheck
    cp 5
    jp c,en200_down
    cp 7
    jp c,en200_firecheck
    cp 13
    jp c,en200_up
    cp 15
    jp c,en200_firecheck
    jp en200_down
en200_down:
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    add a,8
    ld (hl),a
    jp en200_firecheck
en200_up:
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    sub 8
    ld (hl),a
en200_firecheck:
    ld a,b
    cp 5
    jp z,en200_fire
    cp 13
    jp nz,enemy_bounds
en200_fire:
    ; FIX23 spawn349(2,x-24,y+44): native offsets -12,+22.
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    sub 12
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    add a,22
    ld (TMP_Y),a
    ld a,29
    ld (TMP_KIND),a
    ld a,255
    ld (TMP_HP),a
    xor a
    ld (TMP_PARAM),a
    call spawn_manual_enemy_exact
    jp enemy_bounds

en_warning:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    or a
    call nz,enemy_scroll_left8_if_col
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    ld (hl),a
    cp 29
    jp nc,enemy_kill_current
    ret

en_type303:
    call enemy_scroll_left8_if_col
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    ld (hl),a
    jp enemy_bounds

en_type199:
    call enemy_scroll_left8_if_col
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    cp 34
    jp c,en199_store
    ld a,2
en199_store:
    ld (hl),a
    jp enemy_bounds

 ; Kraken source hazards ---------------------------------------------------------
; kind24 = FIX23 type108/chr159: straight lethal shot, x -= 16 px640 -> 8 native.
en_boss108:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp 8
    jp c,enemy_kill_current
    sub 8
    ld (hl),a
    ret

; kind25 = FIX23 type14/chr160..164.  It arms at p=18, then accelerates left.
en_boss14:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    ld b,a
    cp 18
    jp c,en14_inc
    cp 19
    jp nz,en14_after19
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    dec a                         ; original -2 px640 -> -1 native
    ld (hl),a
    jp en14_inc
 en14_after19:
    cp 20
    jp nz,en14_fast
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    sub 4                        ; original -8 -> -4 native
    ld (hl),a
    jp en14_inc
 en14_fast:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    sub 6                        ; original -12 -> -6 native
    ld (hl),a
 en14_inc:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    inc a
    ld (hl),a
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp 248
    jp nc,enemy_kill_current
    ret

; kind26 = FIX23 type109. p==3 and p=16..24 rise; p>=32 retracts down.
en_boss109:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    cp 42
    jp nc,enemy_kill_current
    ld b,a
    cp 3
    jp z,en109_up
    cp 16
    jp c,en109_inc
    cp 25
    jp c,en109_up
    cp 32
    jp c,en109_inc
    ; p 32..41: y += 8 native
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    add a,8
    ld (hl),a
    jp en109_inc
 en109_up:
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    sub 8
    ld (hl),a
 en109_inc:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    inc a
    ld (hl),a
    ret

; kind27 = FIX23 type110: stationary column animation, lethal from p>=16.
en_boss110:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    cp 42
    jp nc,enemy_kill_current
    ld a,(hl)
    inc a
    ld (hl),a
    ret

; kind28 = FIX23 ID13 mine released by Ocular Sentinel #2 (label_386).
; Source: states 1..5 drift right, states 6..21 arm, state22 locks an aim,
; then HSPDX auto-motion continues.  MSX2 stores the aimed up/down-left vector
; in param and advances it at ~800px640/tick (3 native px per component).
en_mid2_mine:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    cp 6
    jp c,en_mine_drift
    cp 22
    jp z,en_mine_lock
    cp 23
    jp nc,en_mine_fly
    inc a
    ld (hl),a
    ret
en_mine_drift:
    inc a
    ld (hl),a
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,4
    ld (hl),a
    jp enemy_bounds
en_mine_lock:
    ; Aim once at the current player position, as es_aim does in the source.
    inc a
    ld (hl),a
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(PLAYER_Y)
    cp (hl)
    ld a,0
    jp c,en_mine_store_dir
    ld a,1
en_mine_store_dir:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld (hl),a
    ret
en_mine_fly:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp 4
    jp c,enemy_kill_current
    sub 3
    ld (hl),a
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    or a
    jp z,en_mine_up
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 188
    jp nc,enemy_kill_current
    add a,3
    ld (hl),a
    ret
en_mine_up:
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 4
    jp c,enemy_kill_current
    sub 3
    ld (hl),a
    ret


; Exact Stage-1 child entities from FIX23 enemies.inc -------------------------
; kind29 = ID2 accelerated missile from base 200, type128.
en_id2_missile:
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    ld b,a
    inc a
    ld (hl),a
    ld a,b
    cp 3
    jp c,id2_dx1
    cp 5
    jp c,id2_dx2
    ld b,4
    jp id2_move
id2_dx1:
    ld b,1
    jp id2_move
id2_dx2:
    ld b,2
id2_move:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp b
    jp c,enemy_kill_current
    sub b
    ld (hl),a
    ret

; kind30 = ID3 popcorn: shootable type32, dir45+rnd(7), speed800.
en_id3_popcorn:
    call enemy_apply_dir4
    jp enemy_bounds

; kind31 = ID9 vent jet: indestructible type128, anchored to scroll and vertical.
en_id9_vent:
    call enemy_scroll_left8_if_col
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    or a
    jp nz,id9_down
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 4
    jp c,enemy_kill_current
    sub 4
    ld (hl),a
    jp enemy_projectile_terrain
id9_down:
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 188
    jp nc,enemy_kill_current
    add a,4
    ld (hl),a
    jp enemy_projectile_terrain

; kind32 = ID64 capsule from launcher 125: shootable, anchored, 3px/t vertical.
en_id64_capsule:
    call enemy_scroll_left8_if_col
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    or a
    jp nz,id64_down
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 4
    jp c,enemy_kill_current
    sub 3
    ld (hl),a
    cp 48
    ret nc
    jp enemy_kill_current
id64_down:
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 180
    jp nc,enemy_kill_current
    add a,3
    ld (hl),a
    cp 132
    ret c
    jp enemy_kill_current

enemy_scroll_left8_if_col:
    ld a,(SCROLL_SUB)
    or a
    ret nz
enemy_scroll_left8:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp 8
    jp c,enemy_kill_current
    sub 8
    ld (hl),a
    ret

enemy_projectile_terrain:
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,8
    srl a
    srl a
    srl a
    ld b,a
    ld hl,(SCROLL_COL)
    ld a,l
    add a,b
    ld l,a
    jp nc,ept_nocarry
    inc h
ept_nocarry:
    ld (COL_TARGET),hl
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    srl a
    srl a
    srl a
    cp 22
    ret nc
    ld (COL_ROW),a
    call collision_at
    cp 1
    jp z,enemy_kill_current
    cp 4
    jp z,enemy_kill_current
    ret

enemy_bounds:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld b,(hl)              ; state
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    cp 251
    jp c,enemy_bounds_y
    ld a,b
    cp 3
    jp nc,enemy_kill_current
enemy_bounds_y:
    ld hl,(EN_PTR)
    ld de,2
    add hl,de
    ld a,(hl)
    cp 192
    ret c
    jp enemy_kill_current

enemy_kill_current:
    ld hl,(EN_PTR)
    xor a
    ld (hl),a
    ret

enemy_start_death:
    push bc
    push de
    call score_add_enemy
    pop de
    pop bc
    ld hl,(EN_PTR)
    ld a,2
    ld (hl),a
    ld de,4
    add hl,de
    xor a
    ld (hl),a
    ret

enemy_death_update:
    ; Anchored source entities continue to drift with the map while exploding.
    ld hl,(EN_PTR)
    ld de,3
    add hl,de
    ld a,(hl)
    cp 8
    jp z,enemy_death_scroll
    cp 9
    jp z,enemy_death_scroll
    cp 12
    jp z,enemy_death_scroll
    cp 13
    jp z,enemy_death_scroll
    cp 16
    jp z,enemy_death_scroll
    cp 17
    jp z,enemy_death_scroll
    cp 18
    jp z,enemy_death_scroll
    cp 19
    jp nz,enemy_death_tick
enemy_death_scroll:
    call enemy_scroll_left8_if_col
enemy_death_tick:
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    inc a
    ld (hl),a
    cp 8
    ret c
    ; ID99 turns into the visible ID199 Volca-Stone after its explosion.
    ld hl,(EN_PTR)
    ld de,3
    add hl,de
    ld a,(hl)
    cp 13
    jp nz,enemy_kill_current
    ld hl,(EN_PTR)
    ld a,1
    ld (hl),a
    ld de,3
    add hl,de
    ld a,23
    ld (hl),a
    inc hl
    ld a,2
    ld (hl),a
    inc hl
    ld a,1
    ld (hl),a
    ret

; Two straight bullets used by the FIX23 wall-caterpillar ID105.
enemy_spawn_pair_left:
    ld hl,(EN_PTR)
    inc hl
    ld b,(hl)
    inc hl
    ld a,(hl)
    add a,4
    ld c,a
    ld d,251
    ld e,0
    call spawn_enemy_bar
    ld hl,(EN_PTR)
    inc hl
    ld b,(hl)
    inc hl
    ld a,(hl)
    add a,16
    ld c,a
    ld d,251
    ld e,0
    jp spawn_enemy_bar


; -----------------------------------------------------------------------------
; Stage-1 enemy bullet pool.  The original uses separate entities; this fixed
; eight-record pool preserves visible midboss/vent/caterpillar fire and terrain
; blocking without sacrificing authored enemy slots.
spawn_enemy_bullet:
    ld a,1
    ld (BUL_SPAWN_TYPE),a
    jp spawn_enemy_bullet_find
spawn_enemy_bar:
    ld a,2
    ld (BUL_SPAWN_TYPE),a
spawn_enemy_bullet_find:
    ; Preserve spawn arguments while scanning the original 20-slot bullet pool.
    ld a,b
    ld (TMP_X),a
    ld a,c
    ld (TMP_Y),a
    ld a,d
    ld (TMP_SPEED),a
    ld a,e
    ld (TMP_PARAM),a
    ld hl,BUL_BASE
    ld b,BUL_COUNT
spawn_enemy_bullet_scan:
    ld a,(hl)
    or a
    jp z,seb_fill
    ld de,BUL_REC_SIZE
    add hl,de
    djnz spawn_enemy_bullet_scan
    ret
seb_fill:
    ld a,(BUL_SPAWN_TYPE)
    ld (hl),a
    inc hl
    ld a,(TMP_X)
    ld (hl),a
    inc hl
    ld a,(TMP_Y)
    ld (hl),a
    inc hl
    ld a,(TMP_SPEED)
    ld (hl),a
    inc hl
    ld a,(TMP_PARAM)
    ld (hl),a
    ret

update_enemy_bullets:
    ld hl,BUL_BASE
    ld b,BUL_COUNT
update_enemy_bullets_loop:
    push bc
    push hl
    call update_one_bullet
    pop hl
    ld de,BUL_REC_SIZE
    add hl,de
    pop bc
    djnz update_enemy_bullets_loop
    ret

update_one_bullet:
    ld a,(hl)
    or a
    ret z
    ld (BUL_PTR),hl
    ld de,3
    add hl,de
    ld a,(hl)
    ld (TMP_SPEED),a
    inc hl
    ld a,(hl)
    ld (TMP_PARAM),a
    ld hl,(BUL_PTR)
    inc hl
    ld b,(hl)
    ld a,(TMP_SPEED)
    add a,b
    ld (hl),a
    ld (TMP_EX),a
    cp 248
    jp nc,kill_current_bullet
    inc hl
    ld b,(hl)
    ld a,(TMP_PARAM)
    add a,b
    ld (hl),a
    ld (TMP_EY),a
    cp 192
    jp nc,kill_current_bullet

    ; Terrain sample at bullet centre; FIX23 IDs 10/11 die only on attrs 1/4.
    ld a,(TMP_EX)
    add a,2
    srl a
    srl a
    srl a
    ld b,a
    ld hl,(SCROLL_COL)
    ld a,l
    add a,b
    ld l,a
    jp nc,uob_col_ok
    inc h
uob_col_ok:
    ld (COL_TARGET),hl
    ld a,(TMP_EY)
    cp 6
    jp c,kill_current_bullet
    sub 6
    srl a
    srl a
    srl a
    cp 22
    jp nc,kill_current_bullet
    ld (COL_ROW),a
    call collision_at
    cp 1
    jp z,kill_current_bullet
    cp 4
    jp z,kill_current_bullet

    ; Player hit.
    ld a,(INVINCIBLE)
    or a
    ret nz
    ld a,(PLAYER_X)
    add a,8
    ld (CHECK_X),a
    ld a,(PLAYER_Y)
    add a,8
    ld (CHECK_Y),a
    xor a
    ld (TMP_KIND),a
    call near_enemy
    or a
    ret z
    call kill_current_bullet
    jp trigger_death

kill_current_bullet:
    ld hl,(BUL_PTR)
    xor a
    ld (hl),a
    ret

check_midboss_collisions:
    ld a,(MID_ACTIVE)
    or a
    ret z
    ; Body is invulnerable but consumes shots, matching HP9999/type32.
    ld hl,SHOT_BASE
    ld b,SHOT_COUNT
cmc_shots:
    push bc
    push hl
    ld a,(hl)
    or a
    jp z,cmc_next
    inc hl
    ld a,(hl)
    add a,8
    ld c,a
    inc hl
    ld a,(hl)
    add a,8
    ld d,a
    ; Sentinel authored size 40x64, hit 95%: centre MID+(20,32).
    ld a,(MID_X)
    add a,20
    sub c
    jp nc,cmc_dx
    cpl
    inc a
cmc_dx:
    cp 27
    jp nc,cmc_next
    ld a,(MID_Y)
    add a,32
    sub d
    jp nc,cmc_dy
    cpl
    inc a
cmc_dy:
    cp 39
    jp nc,cmc_next
    pop hl
    xor a
    ld (hl),a
    push hl
cmc_next:
    pop hl
    ld de,SHOT_REC_SIZE
    add hl,de
    pop bc
    djnz cmc_shots
    ld a,(INVINCIBLE)
    or a
    ret nz
    ld a,(PLAYER_X)
    add a,8
    ld c,a
    ld a,(MID_X)
    add a,20
    sub c
    jp nc,cmc_pdx
    cpl
    inc a
cmc_pdx:
    cp 22
    ret nc
    ld a,(PLAYER_Y)
    add a,8
    ld c,a
    ld a,(MID_Y)
    add a,32
    sub c
    jp nc,cmc_pdy
    cpl
    inc a
cmc_pdy:
    cp 34
    ret nc
    jp trigger_death

check_enemy_collisions:
    ; HYBRID: compact list of active player shots (centre = x+8,y+8), built
    ; once per tick instead of rescanning the six records for every enemy.
    xor a
    ld (SHOT_LIST_N),a
    ld de,SHOT_LIST
    ld hl,SHOT_BASE
    ld b,SHOT_COUNT
cec_build:
    ld a,(hl)
    or a
    jp z,cec_build_next
    ld a,l
    ld (de),a
    inc de
    ld a,h
    ld (de),a
    inc de
    inc hl
    ld a,(hl)
    add a,8
    ld (de),a
    inc de
    inc hl
    ld a,(hl)
    add a,8
    ld (de),a
    inc de
    dec hl
    dec hl
    ld a,(SHOT_LIST_N)
    inc a
    ld (SHOT_LIST_N),a
cec_build_next:
    inc hl
    inc hl
    inc hl
    inc hl
    djnz cec_build
    ld hl,EN_BASE
    ld b,EN_COUNT
check_enemy_collisions_loop:
    push bc
    push hl
    call check_one_enemy
    pop hl
    ld de,EN_REC_SIZE
    add hl,de
    pop bc
    djnz check_enemy_collisions_loop
    ret

check_one_enemy:
    ld a,(hl)
    or a
    ret z
    cp 2
    ret z
    ld (EN_PTR),hl
    inc hl
    ld a,(hl)
    ld (TMP_EX),a
    inc hl
    ld a,(hl)
    ld (TMP_EY),a
    inc hl
    ld a,(hl)
    ld (TMP_KIND),a
    cp 20
    ret z
    cp 21
    ret z
    cp 22
    ret z
    cp 23
    jp z,check_player_item_exact
    cp 24
    jp z,check_boss_hazard_always
    cp 25
    jp z,check_boss_hazard14
    cp 26
    jp z,check_boss_hazard_column
    cp 27
    jp z,check_boss_hazard_column
    cp 28
    jp z,check_mid2_mine_hazard
    cp 29
    jp z,check_boss_hazard_always
    cp 31
    jp z,check_boss_hazard_always

    ; Test all six canonical player projectile slots (3 front + 3 rear).
    call check_player_shots_vs_enemy
    or a
    ret nz
    jp check_hidden_touch

check_mid2_mine_hazard:
    ; Source ID13 becomes type128 (lethal contact) from state 6 onward.
    ld hl,(EN_PTR)
    ld de,4
    add hl,de
    ld a,(hl)
    cp 6
    ret c
    jp check_boss_hazard_always

check_player_shots_vs_enemy:
    ld a,(SHOT_LIST_N)
    or a
    ret z
    ld b,a
    ld hl,SHOT_LIST
cpse_loop:
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl                    ; HL -> centre x
    ld a,(de)
    or a
    jp z,cpse_skip2           ; consumed by an earlier enemy this tick
    ; Coarse reject (superset of every near_enemy box, same 8-bit maths):
    ; a hit is only possible if CHECK_X-EX in [-6,38] and CHECK_Y-EY in [-6,46].
    ld a,(TMP_EX)
    ld c,a
    ld a,(hl)
    sub c
    add a,6
    cp 45
    jp nc,cpse_skip2
    inc hl
    ld a,(TMP_EY)
    ld c,a
    ld a,(hl)
    sub c
    add a,6
    cp 53
    jp nc,cpse_skip1
    ld a,(hl)
    ld (CHECK_Y),a
    dec hl
    ld a,(hl)
    ld (CHECK_X),a
    inc hl
    ld a,e
    ld (SHOT_PTR),a
    ld a,d
    ld (SHOT_PTR+1),a
    push bc
    push hl
    call near_enemy
    pop hl
    pop bc
    or a
    jp z,cpse_skip1
    ld hl,(SHOT_PTR)
    xor a
    ld (hl),a
    call enemy_take_hit
    ld a,1
    ret
cpse_skip2:
    inc hl
cpse_skip1:
    inc hl
    djnz cpse_loop
    xor a
    ret

check_hidden_touch:
    ld a,(TMP_KIND)
    cp 13
    ret z
    ; FIX23 ID99/type8 is invisible and non-harmful. It is revealed only by a
    ; player shot hitting it; touching it or merely holding fire does nothing.
    jp check_player_enemy_exact

check_player_item_exact:
    ld a,(PLAYER_X)
    add a,8
    ld (CHECK_X),a
    ld a,(PLAYER_Y)
    add a,8
    ld (CHECK_Y),a
    call player_near_enemy
    or a
    ret z
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    ld (TMP_PARAM),a
    ld e,a
    ld d,0
    ld hl,STONE_GOT
    add hl,de
    ld a,1
    ld (hl),a
    ld a,(TMP_PARAM)
    inc a
    ld e,a
    ld d,0
    ld hl,STONE_ROW_BUF
    add hl,de
    ld a,(STONE_GOT_TILE)
    ld (hl),a
    call score_add_1000      ; Original collected Volca-Stone award
    ld hl,(EN_PTR)
    xor a
    ld (hl),a
    call draw_stone_row
    ret

check_player_enemy_exact:
    ld a,(INVINCIBLE)
    or a
    ret nz
    ld a,(PLAYER_X)
    add a,8
    ld (CHECK_X),a
    ld a,(PLAYER_Y)
    add a,8
    ld (CHECK_Y),a
    call player_near_enemy
    or a
    ret z
    jp trigger_death

check_boss_hazard14:
    ; FIX23 type14 is harmless while forming and becomes type128 at p>=18.
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    cp 18
    ret c
    ld a,(INVINCIBLE)
    or a
    ret nz
    ld a,(PLAYER_X)
    add a,8
    ld b,a
    ld a,(TMP_EX)
    add a,4
    sub b
    jp nc,cbh14x
    cpl
    inc a
cbh14x:
    cp 7
    ret nc
    ld a,(PLAYER_Y)
    add a,8
    ld b,a
    ld a,(TMP_EY)
    add a,12
    sub b
    jp nc,cbh14y
    cpl
    inc a
cbh14y:
    cp 14
    ret nc
    jp trigger_death
check_boss_hazard_column:
    ; FIX23 type109/110 becomes type128 at p>=16.
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    cp 16
    ret c
check_boss_hazard_always:
    ld a,(INVINCIBLE)
    or a
    ret nz
    ld a,(PLAYER_X)
    add a,8
    ld (CHECK_X),a
    ld a,(PLAYER_Y)
    add a,8
    ld (CHECK_Y),a
    call player_near_enemy
    or a
    ret z
    jp trigger_death

enemy_take_hit:
    ; FIX23 weapons.inc label_116: every player shot removes 10 HP, not 1.
    ; BASE09 stored canonical HP (60/80/etc.) but decremented by one, making
    ; plants and eyes appear effectively indestructible.
    ld hl,(EN_PTR)
    ld de,5
    add hl,de
    ld a,(hl)
    cp 11
    jp c,enemy_take_hit_die
    sub 10
    ld (hl),a
    ret
enemy_take_hit_die:
    jp enemy_start_death


near_enemy:
    ; Player-shot vs enemy: source es_check uses projectile hitbox (~13x13 native)
    ; plus the enemy authored hitbox. This is intentionally wider than contact.
    ld a,(TMP_KIND)
    cp 9
    jp z,shot_near_24
    cp 12
    jp z,shot_near_24
    cp 19
    jp z,shot_near_base
    cp 24
    jp z,shot_near_24
    cp 7
    jp z,shot_near_tall
    cp 16
    jp z,shot_near_tall
    cp 17
    jp z,shot_near_tall
shot_near_16:
    ld a,(TMP_EX)
    add a,8
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,sn16x
    cpl
    inc a
sn16x:
    cp 15
    jp nc,near_no
    ld a,(TMP_EY)
    add a,8
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,sn16y
    cpl
    inc a
sn16y:
    cp 15
    jp nc,near_no
    ld a,1
    ret
shot_near_24:
    ld a,(TMP_EX)
    add a,12
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,sn24x
    cpl
    inc a
sn24x:
    cp 19
    jp nc,near_no
    ld a,(TMP_EY)
    add a,12
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,sn24y
    cpl
    inc a
sn24y:
    cp 19
    jp nc,near_no
    ld a,1
    ret
shot_near_tall:
    ld a,(TMP_EX)
    add a,8
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,sntx
    cpl
    inc a
sntx:
    cp 15
    jp nc,near_no
    ld a,(TMP_EY)
    add a,12
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,snty
    cpl
    inc a
snty:
    cp 19
    jp nc,near_no
    ld a,1
    ret
shot_near_base:
    ld a,(TMP_EX)
    add a,16
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,snbx
    cpl
    inc a
snbx:
    cp 23
    jp nc,near_no
    ld a,(TMP_EY)
    add a,20
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,snby
    cpl
    inc a
snby:
    cp 27
    jp nc,near_no
    ld a,1
    ret

player_near_enemy:
    ; Player hitbox is 4x4 native. Entity contact is much tighter than shots.
    ld a,(TMP_KIND)
    cp 9
    jp z,pne24
    cp 12
    jp z,pne24
    cp 19
    jp z,pnebase
    cp 26
    jp z,pnecolumn
    cp 27
    jp z,pnecolumn
    cp 7
    jp z,pnetall
    cp 16
    jp z,pnetall
    cp 17
    jp z,pnetall
pne16:
    ld a,(TMP_EX)
    add a,8
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,pne16x
    cpl
    inc a
pne16x:
    cp 10
    jp nc,near_no
    ld a,(TMP_EY)
    add a,8
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,pne16y
    cpl
    inc a
pne16y:
    cp 10
    jp nc,near_no
    ld a,1
    ret
pne24:
    ld a,(TMP_EX)
    add a,12
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,pne24x
    cpl
    inc a
pne24x:
    cp 14
    jp nc,near_no
    ld a,(TMP_EY)
    add a,12
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,pne24y
    cpl
    inc a
pne24y:
    cp 14
    jp nc,near_no
    ld a,1
    ret
pnetall:
    ld a,(TMP_EX)
    add a,8
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,pnetx
    cpl
    inc a
pnetx:
    cp 10
    jp nc,near_no
    ld a,(TMP_EY)
    add a,12
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,pnety
    cpl
    inc a
pnety:
    cp 14
    jp nc,near_no
    ld a,1
    ret
pnebase:
    ld a,(TMP_EX)
    add a,16
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,pnebx
    cpl
    inc a
pnebx:
    cp 18
    jp nc,near_no
    ld a,(TMP_EY)
    add a,20
    ld b,a
    ld a,(CHECK_Y)
    sub b
    jp nc,pneby
    cpl
    inc a
pneby:
    cp 22
    jp nc,near_no
    ld a,1
    ret
pnecolumn:
    ; Dynamic Kraken tentacles occupy a narrow 8px column with height determined
    ; by their source param. Approximate the currently grown segment accurately.
    ld a,(TMP_EX)
    add a,8
    ld b,a
    ld a,(CHECK_X)
    sub b
    jp nc,pnecx
    cpl
    inc a
pnecx:
    cp 10
    jp nc,near_no
    ld hl,(EN_PTR)
    ld de,6
    add hl,de
    ld a,(hl)
    cp 16
    jp c,near_no
    ; Once armed, the authored metasprite spans the growing/retracting column.
    ld a,(CHECK_Y)
    ld b,a
    ld a,(TMP_KIND)
    cp 26
    jp z,pnecol_bottom
    ; top tentacle: top at entity y, extends downward up to 88 native.
    ld a,(TMP_EY)
    cp b
    jp nc,near_no
    add a,88
    cp b
    jp c,near_no
    ld a,1
    ret
pnecol_bottom:
    ; bottom tentacle entity y is moving top edge; cover y..y+88.
    ld a,(TMP_EY)
    cp b
    jp nc,near_no
    add a,88
    cp b
    jp c,near_no
    ld a,1
    ret
near_no:
    xor a
    ret

check_collision:
    ld a,(INVINCIBLE)
    or a
    ret nz
    ld a,(PLAYER_X)
    add a,8
    srl a
    srl a
    srl a
    ld b,a
    ld hl,(SCROLL_COL)
    ld a,l
    add a,b
    ld l,a
    jp nc,col_no_carry
    inc h
col_no_carry:
    ld (COL_TARGET),hl
    ; Player collision point is the sprite centre.  Playfield begins at y=8,
    ; so (PLAYER_Y + 8 - 8) / 8 == PLAYER_Y / 8.
    ld a,(PLAYER_Y)
    srl a
    srl a
    srl a
    cp 22
    jp c,col_row_ok
    ld a,21
col_row_ok:
    ld (COL_ROW),a
    call collision_at
    cp 1
    jp z,trigger_death
    cp 2
    jp z,trigger_death
    cp 4
    jp z,trigger_death
    cp 5
    jp z,trigger_death
    ret

; HYBRID fast path: columns SCROLL_COL..SCROLL_COL+39 come from the decoded
; window; anything else falls back to the original RLE walk (same result).
collision_at:
    ld hl,(SCROLL_COL)
    ld b,h
    ld c,l
    ld hl,(COL_TARGET)
    or a
    sbc hl,bc
    jp c,collision_at_rle
    ld a,h
    or a
    jp nz,collision_at_rle
    ld a,l
    cp COLWIN_AHEAD
    jp nc,collision_at_rle
    ld a,(COL_ROW)
    cp 22
    jp nc,collision_at_rle
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,(COL_TARGET)
    and 63
    ld e,a
    ld d,0
    add hl,de
    ld de,COLWIN
    add hl,de
    ld a,(hl)
    ret

collision_at_rle:
    ld hl,(COL_TARGET)
    ld b,h
    ld c,l
    ld a,(COL_ROW)
    add a,a
    ld e,a
    ld d,0
    ld hl,(COLL_OFF_PTR)
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld hl,(COLL_RLE_PTR)
    add hl,de
coll_run:
    ld a,(hl)
    inc hl
    or a
    jp z,coll_none
    ld d,a
    ld a,(hl)
    inc hl
    ld e,a
    ld a,b
    or a
    jp nz,coll_sub_hi
    ld a,c
    cp d
    jp c,coll_found
    sub d
    ld c,a
    jp coll_run
coll_sub_hi:
    ld a,c
    sub d
    ld c,a
    jp nc,coll_run
    dec b
    jp coll_run
coll_found:
    ld a,e
    ret
coll_none:
    xor a
    ret

; Rebuild the window for the current SCROLL_COL (stage start).
colwin_reset:
    call restore_data_bank
    xor a
    ld (CW_ROW),a
cwr_row:
    ld a,(CW_ROW)
    add a,a
    ld e,a
    ld d,0
    ld hl,(COLL_OFF_PTR)
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld hl,(COLL_RLE_PTR)
    add hl,de                 ; HL = row RLE start
    ld a,(SCROLL_COL)
    ld c,a
    ld a,(SCROLL_COL+1)
    ld b,a                    ; BC = columns to skip
cwr_run:
    ld a,(hl)
    or a
    jp z,cwr_eor
    ld d,a
    ld a,b
    or a
    jp nz,cwr_skip_hi
    ld a,c
    cp d
    jp c,cwr_inside
cwr_skip_hi:
    ld a,c
    sub d
    ld c,a
    jp nc,cwr_skip_done
    dec b
cwr_skip_done:
    inc hl
    inc hl
    jp cwr_run
cwr_inside:
    ld a,d
    sub c
    ld (CW_TMP),a             ; columns left in this run
    inc hl
    ld a,(hl)
    ld (CW_TMPV),a
    inc hl
    jp cwr_store
cwr_eor:
    ld a,255
    ld (CW_TMP),a
    xor a
    ld (CW_TMPV),a
cwr_store:
    push hl
    ld a,(CW_ROW)
    ld e,a
    ld d,0
    ld hl,CW_PTR
    add hl,de
    add hl,de
    pop bc
    ld (hl),c
    inc hl
    ld (hl),b
    ld hl,CW_LEFT
    add hl,de
    ld a,(CW_TMP)
    ld (hl),a
    ld hl,CW_VAL
    add hl,de
    ld a,(CW_TMPV)
    ld (hl),a
    ld a,(CW_ROW)
    inc a
    ld (CW_ROW),a
    cp 22
    jp c,cwr_row
    ld hl,(SCROLL_COL)
    ld (CW_NEXT),hl
    ; fall through: decode the visible window

; Decode columns until CW_NEXT == SCROLL_COL + COLWIN_AHEAD.
colwin_fill:
    call restore_data_bank
cwf_loop:
    ld hl,(SCROLL_COL)
    ld de,COLWIN_AHEAD
    add hl,de
    ld b,h
    ld c,l
    ld hl,(CW_NEXT)
    or a
    sbc hl,bc
    ret nc
    call colwin_decode_column
    ld hl,(CW_NEXT)
    inc hl
    ld (CW_NEXT),hl
    jp cwf_loop

colwin_decode_column:
    ld a,(CW_NEXT)
    and 63
    ld (CW_COLOFF),a
    xor a
    ld (CW_ROW),a
cwd_row:
    ld a,(CW_ROW)
    ld e,a
    ld d,0
    ld hl,CW_LEFT
    add hl,de
    ld a,(hl)
    or a
    jp nz,cwd_emit
    ld hl,CW_PTR
    add hl,de
    add hl,de
    push hl
    ld e,(hl)
    inc hl
    ld d,(hl)                 ; DE = RLE cursor
    ld a,(de)
    or a
    jp z,cwd_eor
    ld (CW_TMP),a
    inc de
    ld a,(de)
    ld (CW_TMPV),a
    inc de
    pop hl
    ld (hl),e
    inc hl
    ld (hl),d
    jp cwd_newrun
cwd_eor:
    pop hl                    ; cursor stays on the row terminator
    ld a,255
    ld (CW_TMP),a
    xor a
    ld (CW_TMPV),a
cwd_newrun:
    ld a,(CW_ROW)
    ld e,a
    ld d,0
    ld hl,CW_VAL
    add hl,de
    ld a,(CW_TMPV)
    ld (hl),a
    ld hl,CW_LEFT
    add hl,de
    ld a,(CW_TMP)
    ld (hl),a
cwd_emit:
    dec a
    ld (hl),a                 ; HL = &CW_LEFT[row]
    ld a,(CW_ROW)
    ld e,a
    ld d,0
    ld hl,CW_VAL
    add hl,de
    ld a,(hl)
    ld (CW_TMPV),a
    ld a,(CW_ROW)
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,(CW_COLOFF)
    ld e,a
    ld d,0
    add hl,de
    ld de,COLWIN
    add hl,de
    ld a,(CW_TMPV)
    ld (hl),a
    ld a,(CW_ROW)
    inc a
    ld (CW_ROW),a
    cp 22
    jp c,cwd_row
    ret

trigger_death:
    ld a,(BOSS_ACTIVE)
    cp 2
    ret nc
    ld a,(DEATH_T)
    or a
    ret nz
    ld a,1
    ld (DEATH_T),a
    ; Damage to the ship decrements reserves exactly once per death.
    ld a,(LIVES)
    or a
    jp z,trigger_clear_shots
    dec a
    ld (LIVES),a
trigger_clear_shots:
    ; Original player projectiles are removed with the ship death.
    xor a
    ld hl,SHOT_BASE
    ld de,SHOT_BASE+1
    ld bc,23
    ld (hl),a
    ldir
    ld (SHOT_COOL),a
    ret

death_tick:
    ld a,(DEATH_T)
    inc a
    ld b,a
    ld a,(LIVES)
    or a
    ld a,b
    jp z,death_last_ship
    cp 41
    jp c,death_store
    jp death_complete
death_last_ship:
    ; FIX23 holds the final explosion longer than an ordinary respawn.
    cp 71
    jp c,death_store
death_complete:
    xor a
    ld (DEATH_T),a
    ld a,(LIVES)
    or a
    jp z,game_over_wait
    ; H02: respawn from the active stage start. H01 incorrectly used the
    ; prologue's INTRO_X/Y for every later stage after ship destruction.
    ld a,(CURRENT_STAGE)
    cp 1
    jp nz,death_stage_start
    ld a,(INTRO_X)
    ld (PLAYER_X),a
    ld a,(INTRO_Y)
    ld (PLAYER_Y),a
    jp death_reset_frame
death_stage_start:
    ld a,(START_X_RAM)
    ld (PLAYER_X),a
    ld a,(START_Y_RAM)
    ld (PLAYER_Y),a
death_reset_frame:
    xor a
    ld (PLAYER_FRAME),a
    ret
game_over_wait:
    ; Original GAME OVER: the player cannot respawn at zero lives.
    call restore_data_bank
    ld hl,(DATA_HDR+46)
    ld de,0x1800
    ld bc,32
    call LDIRVM
    call ENASCR
game_over_release:
    xor a
    call GTTRIG
    or a
    jp nz,game_over_release
game_over_press:
    xor a
    call GTTRIG
    or a
    jp z,game_over_press
    ; Original continue: restart CURRENT_STAGE with 3 ships, zero score,
    ; reset stones, and first extend at 20,000 (not a forced title restart).
    ; This path is entered through main_dispatch -> game_tick -> death_tick.
    ; Discard those two pending CALL return addresses before tail-jumping.
    pop hl
    pop hl
    call reset_run_state
    jp stage_loop

death_store:
    ld (DEATH_T),a
    ret

boss_update:
    ld a,(BOSS_ACTIVE)
    cp 2
    jp z,boss_death_update
    or a
    jp nz,boss_live
    ld hl,(SCROLL_COL)
    ld a,(SCROLL_MAX)
    ld e,a
    ld a,(SCROLL_MAX+1)
    ld d,a
    or a
    sbc hl,de
    ret c
    ; FIX23 stage1_events.inc boss427: Kraken at (528,232) px640 ->
    ; native weak point (232,92), 700 damage units = 70 player hits.
    ld a,1
    ld (BOSS_ACTIVE),a
    ld a,(BOSS_HP_INIT)
    ld (BOSS_HP),a
    ld a,92
    ld (BOSS_Y),a
    xor a
    ld (BOSS_DIR),a
    ld (BOSS_PAT),a
    ld (BOSS_PAT_T),a
    ld (BOSS_PROJ_T),a
    ld a,0x72
    ld (BOSS_TIMER),a
    ld a,0x05
    ld (BOSS_TIMER+1),a
    ; H02: clear the 40-entry enemy pool with ZERO, not 05h.
    ; H01 left A=05h from BOSS_TIMER+1: LDIR populated every record with
    ; active=5, producing phantom enemies and possible false collisions.
    xor a
    ld hl,EN_BASE
    ld de,EN_BASE+1
    ld bc,279
    ld (hl),a
    ldir
boss_live:
    ; Source boss timer: 1394 logic ticks. TIME OVER also enters the death sequence.
    ld hl,(BOSS_TIMER)
    ld a,h
    or l
    jp z,boss_force_death
    dec hl
    ld (BOSS_TIMER),hl
    ; FIX23 label_438..443: test boss_pat_t first, then increment it.
    ld a,(BOSS_PAT_T)
    ld b,a
    ld a,(BOSS_PAT)
    cp 0
    jp z,boss_pat_charge
    cp 1
    jp z,boss_pat_rays
    cp 2
    jp z,boss_pat_spikes
    cp 3
    jp z,boss_pat_charge
    cp 4
    jp z,boss_pat_rays
    jp boss_pat_tentacles
boss_pat_charge:
    ld a,b
    inc a
    ld (BOSS_PAT_T),a
    cp 25
    jp c,boss_collision
    call boss_next_pattern
    jp boss_collision
boss_pat_rays:
    ld a,b
    cp 0
    jp z,boss_spawn_type108
    cp 4
    jp z,boss_spawn_type108
    cp 8
    jp z,boss_spawn_type108
    cp 12
    jp z,boss_spawn_type108
    jp boss_rays_advance
boss_spawn_type108:
    ; spawn349(108,496,224): native x=216,y=88, always harmful.
    ld a,24
    ld (TMP_KIND),a
    ld a,216
    ld (TMP_X),a
    ld a,88
    ld (TMP_Y),a
    ld a,255
    ld (TMP_HP),a
    xor a
    ld (TMP_PARAM),a
    call spawn_manual_enemy_exact
boss_rays_advance:
    ld a,(BOSS_PAT_T)
    inc a
    ld (BOSS_PAT_T),a
    cp 16
    jp c,boss_collision
    call boss_next_pattern
    jp boss_collision
boss_pat_spikes:
    ; Source label_441 exact 16-event timing/positions.
    ld hl,boss_spike_events
    ld c,16
bps_loop:
    ld a,(hl)
    cp b
    jp z,bps_spawn
    inc hl
    inc hl
    inc hl
    dec c
    jp nz,bps_loop
    jp boss_spike_endcheck
bps_spawn:
    inc hl
    ld a,(hl)
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    ld (TMP_Y),a
    ld a,25
    ld (TMP_KIND),a
    ld a,255
    ld (TMP_HP),a
    xor a
    ld (TMP_PARAM),a
    call spawn_manual_enemy_exact
boss_spike_endcheck:
    ld a,(BOSS_PAT_T)
    inc a
    ld (BOSS_PAT_T),a
    cp 160
    jp c,boss_collision
    ld a,3
    ld (BOSS_PAT),a
    xor a
    ld (BOSS_PAT_T),a
    jp boss_collision
boss_pat_tentacles:
    ; Source label_442 exact type109/type110 sequence.
    ld hl,boss_tentacle_events
    ld c,8
bpt_loop:
    ld a,(hl)
    cp b
    jp z,bpt_spawn
    inc hl
    inc hl
    inc hl
    inc hl
    dec c
    jp nz,bpt_loop
    jp boss_tent_endcheck
bpt_spawn:
    inc hl
    ld a,(hl)
    ld (TMP_KIND),a
    inc hl
    ld a,(hl)
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    ld (TMP_Y),a
    ld a,255
    ld (TMP_HP),a
    xor a
    ld (TMP_PARAM),a
    call spawn_manual_enemy_exact
boss_tent_endcheck:
    ld a,(BOSS_PAT_T)
    inc a
    ld (BOSS_PAT_T),a
    cp 96
    jp c,boss_collision
    xor a
    ld (BOSS_PAT),a
    ld (BOSS_PAT_T),a
    jp boss_collision
boss_next_pattern:
    ld a,(BOSS_PAT)
    inc a
    cp 6
    jp c,boss_store_pattern
    xor a
boss_store_pattern:
    ld (BOSS_PAT),a
    xor a
    ld (BOSS_PAT_T),a
    ret

; Spawn one boss hazard into any of the eight Stage-1 entity records.
; Inputs: TMP_KIND, TMP_X, TMP_Y, TMP_HP, TMP_PARAM.
spawn_manual_enemy_exact:
    ld hl,EN_BASE
    ld b,EN_COUNT
sme_find:
    ld a,(hl)
    or a
    jp z,sme_fill
    ld de,7
    add hl,de
    djnz sme_find
    ret
sme_fill:
    ld a,1
    ld (hl),a
    inc hl
    ld a,(TMP_X)
    ld (hl),a
    inc hl
    ld a,(TMP_Y)
    ld (hl),a
    inc hl
    ld a,(TMP_KIND)
    ld (hl),a
    inc hl
    ld a,1
    ld (hl),a
    inc hl
    ld a,(TMP_HP)
    ld (hl),a
    inc hl
    ld a,(TMP_PARAM)
    ld (hl),a
    ret

boss_collision:
    ; Weak point source position: (528,232) px640 -> native screen top-left (232,92),
    ; actual 8x8 target centre (236,96). Test all 3+3 player projectile slots.
    ld hl,SHOT_BASE
    ld b,SHOT_COUNT
boss_shot_loop:
    push bc
    push hl
    ld a,(hl)
    or a
    jp z,boss_shot_next
    ld (SHOT_PTR),hl
    inc hl
    ld a,(hl)
    add a,8
    ld (CHECK_X),a
    inc hl
    ld a,(hl)
    add a,8
    ld (CHECK_Y),a
    call boss_shot_near
    or a
    jp z,boss_shot_next
    ld hl,(SHOT_PTR)
    xor a
    ld (hl),a
    call boss_damage
    ld a,(BOSS_ACTIVE)
    or a
    jp z,boss_shot_abort
boss_shot_next:
    pop hl
    ld de,SHOT_REC_SIZE
    add hl,de
    pop bc
    djnz boss_shot_loop
    jp boss_player
boss_shot_abort:
    pop hl
    pop bc
    ret

boss_shot_near:
    ld a,(CHECK_X)
    sub 236
    jp nc,bsn_x
    cpl
    inc a
bsn_x:
    cp 11
    jp nc,bsn_no
    ld a,(CHECK_Y)
    sub 96
    jp nc,bsn_y
    cpl
    inc a
bsn_y:
    cp 11
    jp nc,bsn_no
    ld a,1
    ret
bsn_no:
    xor a
    ret

boss_player:
    ld a,(BOSS_ACTIVE)
    or a
    ret z
    ld a,(INVINCIBLE)
    or a
    ret nz
    ; Player hitbox is 4x4 native; test its centre against the 8x8 weak point.
    ld a,(PLAYER_X)
    add a,8
    sub 236
    jp nc,bpl_x
    cpl
    inc a
bpl_x:
    cp 7
    ret nc
    ld a,(PLAYER_Y)
    add a,8
    sub 96
    jp nc,bpl_y
    cpl
    inc a
bpl_y:
    cp 7
    ret nc
    jp trigger_death

boss_damage:
    ld a,(BOSS_HP)
    dec a
    ld (BOSS_HP),a
    ret nz
boss_force_death:
    ld a,2
    ld (BOSS_ACTIVE),a
    xor a
    ld (BOSS_DEATH_T),a
    ; Source death phase removes active attack entities before the explosion chain.
    ld hl,EN_BASE
    ld de,EN_BASE+1
    ld bc,279
    ld (hl),a
    ldir
    ret

boss_death_update:
    ld a,(BOSS_DEATH_T)
    inc a
    ld (BOSS_DEATH_T),a
    ld b,a
    ; Twelve authored large explosions from t16 through t60 every four ticks.
    ld hl,boss_death_events
    ld c,12
bdu_scan:
    ld a,(hl)
    cp b
    jp z,bdu_spawn
    inc hl
    inc hl
    inc hl
    dec c
    jp nz,bdu_scan
    jp bdu_endcheck
bdu_spawn:
    inc hl
    ld a,(hl)
    ld (TMP_X),a
    inc hl
    ld a,(hl)
    ld (TMP_Y),a
    call spawn_boss_death_explosion
bdu_endcheck:
    ld a,b
    cp 120
    ret c
    xor a
    ld (BOSS_ACTIVE),a
    ld a,1
    ld (STAGE_CLEAR),a
    ret

spawn_boss_death_explosion:
    ld hl,EN_BASE
    ld b,EN_COUNT
sbde_find:
    ld a,(hl)
    or a
    jp z,sbde_fill
    ld de,EN_REC_SIZE
    add hl,de
    djnz sbde_find
    ret
sbde_fill:
    ld a,2
    ld (hl),a
    inc hl
    ld a,(TMP_X)
    ld (hl),a
    inc hl
    ld a,(TMP_Y)
    ld (hl),a
    inc hl
    xor a
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    ret

render_sprites:
    ld a,(SKIP_RENDER)
    or a
    ret nz
    ; Start from a 31-slot hidden gameplay SAT + terminator.
    ld hl,game_sat_template
    ld de,SATBUF
    ld bc,128
    ldir
    ld a,(DEATH_T)
    or a
    jp nz,render_death
render_player:
    ld a,(PLAYER_Y)
    ld (SATBUF+0),a
    ld (SATBUF+4),a
    ld a,(PLAYER_X)
    ld (SATBUF+1),a
    ld (SATBUF+5),a
    ld a,(PLAYER_FRAME)
    cp 1
    jp z,rp_up
    cp 2
    jp z,rp_down
    ld a,SPR_PLAYER0_WHITE
    ld (SATBUF+2),a
    ld a,SPR_PLAYER0_GREEN
    ld (SATBUF+6),a
    jp render_shots
rp_up:
    ld a,SPR_PLAYER1_WHITE
    ld (SATBUF+2),a
    ld a,SPR_PLAYER1_GREEN
    ld (SATBUF+6),a
    jp render_shots
rp_down:
    ld a,SPR_PLAYER2_WHITE
    ld (SATBUF+2),a
    ld a,SPR_PLAYER2_GREEN
    ld (SATBUF+6),a
    jp render_shots
render_death:
    cp 31
    jp nc,render_shots
    ld a,(PLAYER_Y)
    ld (SATBUF+0),a
    ld (SATBUF+28),a
    ld a,(PLAYER_X)
    ld (SATBUF+1),a
    ld (SATBUF+29),a
    ld a,(DEATH_T)
    cp 11
    jp c,rexp20
    cp 21
    jp c,rexp21
    ld a,SPR_EXPLOSION22_WHITE
    ld (SATBUF+2),a
    ld a,SPR_EXPLOSION22_ORANGE
    ld (SATBUF+30),a
    jp render_shots
rexp20:
    ld a,SPR_EXPLOSION20_WHITE
    ld (SATBUF+2),a
    ld a,SPR_EXPLOSION20_ORANGE
    ld (SATBUF+30),a
    jp render_shots
rexp21:
    ld a,SPR_EXPLOSION21_WHITE
    ld (SATBUF+2),a
    ld a,SPR_EXPLOSION21_ORANGE
    ld (SATBUF+30),a
render_shots:
    ld hl,SHOT_BASE
    ld de,SATBUF+8
    call render_one_player_shot
    ld hl,SHOT_BASE+4
    ld de,SATBUF+12
    call render_one_player_shot
    ld hl,SHOT_BASE+8
    ld de,SATBUF+16
    call render_one_player_shot
    ld hl,SHOT_BASE+12
    ld de,SATBUF+20
    call render_one_player_shot
    ld hl,SHOT_BASE+16
    ld de,SATBUF+24
    call render_one_player_shot
    ld hl,SHOT_BASE+20
    ld de,SATBUF+28
    call render_one_player_shot
    jp render_enemies

; HL=shot record, DE=SAT slot.
render_one_player_shot:
    ld a,(hl)
    or a
    ret z
    inc hl
    ld b,(hl)             ; x
    inc hl
    ld c,(hl)             ; y
    inc hl
    ld a,(hl)             ; vector
    ld (TMP_PARAM),a
    ld a,c
    ld (de),a
    inc de
    ld a,b
    ld (de),a
    inc de
    ld a,(TMP_PARAM)
    cp 4
    jp nc,rops_rear
    cp 0
    jp z,rops_f0
    cp 1
    jp z,rops_f1
    cp 2
    jp z,rops_f2
    ld a,SPR_SHOT_FRONT3
    jp rops_store
rops_f0:
    ld a,SPR_SHOT_FRONT0
    jp rops_store
rops_f1:
    ld a,SPR_SHOT_FRONT1
    jp rops_store
rops_f2:
    ld a,SPR_SHOT_FRONT2
    jp rops_store
rops_rear:
    sub 4
    cp 0
    jp z,rops_r0
    cp 1
    jp z,rops_r1
    cp 2
    jp z,rops_r2
    ld a,SPR_SHOT_REAR3
    jp rops_store
rops_r0:
    ld a,SPR_SHOT_REAR0
    jp rops_store
rops_r1:
    ld a,SPR_SHOT_REAR1
    jp rops_store
rops_r2:
    ld a,SPR_SHOT_REAR2
rops_store:
    ld (de),a
    ret

render_enemies:
    ; Priority composites own slots 8..19 and their colour tables. Never refresh
    ; generic slot colours before this check: doing so corrupted the sentinel.
    ld a,(MID_ACTIVE)
    or a
    jp nz,render_mid_only
    ld a,(ESC0)
    or a
    jp nz,render_escort_only
    ld a,(ESC1)
    or a
    jp nz,render_escort_only
    ld a,(ESC2)
    or a
    jp nz,render_escort_only
    ld a,(ESC3)
    or a
    jp nz,render_escort_only
    ld a,(ESC4)
    or a
    jp nz,render_escort_only

    xor a
    call get_layout
    push de
    call render_enemy_list

    ; Kraken eye uses SAT slot 16, never part of an enemy slot list.
    ld a,(DEATH_T)
    or a
    jp nz,render_regular_bullets
    ld a,(BOSS_ACTIVE)
    or a
    jp z,render_regular_bullets
    ld a,92
    ld (SATBUF+64),a
    ld a,232
    ld (SATBUF+65),a
    ld a,(BOSS_PAT)
    cp 1
    jp z,render_boss_open
    cp 4
    jp z,render_boss_open
    ld a,(ANIM_T)
    and 4
    jp z,render_boss_eye0
    ld a,SPR_BOSS_EYE1
    jp render_boss_store
render_boss_eye0:
    ld a,SPR_BOSS_EYE0
    jp render_boss_store
render_boss_open:
    ld a,SPR_BOSS_EYE_OPEN
render_boss_store:
    ld (SATBUF+66),a
render_regular_bullets:
    pop hl
    call render_bullet_list
    jp render_commit

; A = 0 normal / 1 Ocular Sentinel / 2 mothership escorts
; -> HL = enemy SAT slot list, DE = enemy-bullet SAT slot list.
get_layout:
    add a,a
    add a,a
    ld e,a
    ld d,0
    ld hl,layout_table_z80
    if TURBO
    ld a,(HYB_CFG)
    and HCFG_ENHANCED
    jp z,get_layout_have
    ld hl,layout_table_r800
get_layout_have:
    endif
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    push de
    ld e,(hl)
    inc hl
    ld d,(hl)
    pop hl
    ret

; Slot lists: count, SAT slots.  Slots 0..1 player, 2..7 player shots,
; 16 Kraken eye, 31 SAT terminator.  Sentinel = 8..19, escorts = 8..17.
layout_table_z80:
    dw lay_z80_normal_en,lay_z80_normal_bul
    dw lay_z80_mid_en,lay_z80_mid_bul
    dw lay_esc_en,lay_z80_normal_bul
lay_z80_normal_en:  db 8, 8,9,10,11,12,13,14,15
lay_z80_normal_bul: db 8, 20,21,22,23,24,25,26,27
; Sentinel: one visible bullet (8 sprites/scanline budget, as BASE12) and the
; Sentinel's own popcorn ID3 / mines ID13 now get three slots instead of none.
lay_z80_mid_en:     db 3, 21,22,23
lay_z80_mid_bul:    db 1, 20
lay_esc_en:         db 2, 18,19
    if TURBO
layout_table_r800:
    dw lay_r800_normal_en,lay_r800_normal_bul
    dw lay_r800_mid_en,lay_r800_mid_bul
    dw lay_esc_en,lay_r800_normal_bul
lay_r800_normal_en:  db 11, 8,9,10,11,12,13,14,15,17,18,19
lay_r800_normal_bul: db 11, 20,21,22,23,24,25,26,27,28,29,30
lay_r800_mid_en:     db 5, 26,27,28,29,30
lay_r800_mid_bul:    db 6, 20,21,22,23,24,25
    endif

; HL = slot list. Draw active enemy records into the listed SAT slots.  When
; RL_ROTATE is set and the list overflows, the next frame starts at the first
; record that did not fit, so every logical enemy is shown (multiplexing).
render_enemy_list:
    ld a,(hl)
    ld (RL_MAX),a
    inc hl
    ld (RL_SLOTS),hl
    xor a
    ld (RENDER_COUNT),a
    ld a,(RL_ROTATE)
    or a
    jp z,rel_start0
    ld a,(EN_ROT)
    cp EN_COUNT
    jp c,rel_start
rel_start0:
    xor a
rel_start:
    ld (RL_IDX),a
    ld l,a
    ld h,0
    ld d,h
    ld e,l
    add hl,hl
    add hl,de
    add hl,hl
    add hl,de             ; idx*7
    ld de,EN_BASE
    add hl,de
    ld b,EN_COUNT
rel_loop:
    push bc
    push hl
    ld a,(hl)
    or a
    jp z,rel_next
    ld (EN_PTR),hl
    inc hl
    inc hl
    inc hl
    ld a,(hl)
    cp 13                 ; hidden ID99 trigger: no graphic, no slot consumed
    jp z,rel_next
    ld a,(RENDER_COUNT)
    ld c,a
    ld a,(RL_MAX)
    cp c
    jp z,rel_overflow
    ; A complete warning is 32 pixels wide and needs two sprite slots.
    ; If only one remains, retry next frame rather than showing half a word.
    ld hl,(EN_PTR)
    inc hl
    inc hl
    inc hl
    ld a,(hl)
    cp 20
    jp z,rel_require_pair
    cp 21
    jp z,rel_require_pair
    cp 22
    jp z,rel_require_pair
    jp rel_slot_ready
rel_require_pair:
    ld a,(RENDER_COUNT)
    inc a
    ld c,a
    ld a,(RL_MAX)
    cp c
    jp z,rel_overflow
    ld a,(RENDER_COUNT)
    ld c,a
rel_slot_ready:
    ld hl,(RL_SLOTS)
    ld e,c
    ld d,0
    add hl,de
    ld a,(hl)
    ld (RL_SLOT),a
    ld hl,(EN_PTR)
    ld a,(hl)
    cp 2
    jp z,rel_death_color
    inc hl
    inc hl
    inc hl
    ld a,(hl)
    jp rel_color_ready
rel_death_color:
    xor a
rel_color_ready:
    ld (TMP_KIND),a
    ld a,(RL_SLOT)
    call slot_color_addr
    ld a,(TMP_KIND)
    call set_enemy_slot_color
    ld a,(RL_SLOT)
    call slot_sat_addr
    ld hl,(EN_PTR)
    call render_enemy
    ld a,(TMP_KIND)
    cp 20
    jp z,rel_second_warning
    cp 21
    jp z,rel_second_warning
    cp 22
    jp z,rel_second_warning
    jp rel_advance_one
rel_second_warning:
    ; Next slot in the existing layout, same X/Y, pattern is right-hand half.
    ld a,(RENDER_COUNT)
    inc a
    ld e,a
    ld d,0
    ld hl,(RL_SLOTS)
    add hl,de
    ld a,(hl)
    ld (RL_SLOT),a
    call slot_color_addr
    ld a,10
    call enemy_color_fill
    ld a,(RL_SLOT)
    call slot_sat_addr
    ld hl,(EN_PTR)
    inc hl
    ld a,(hl)
    add a,16
    ld b,a
    inc hl
    ld a,(hl)
    ld (de),a
    inc de
    ld a,b
    ld (de),a
    inc de
    ld a,(TMP_KIND)
    cp 20
    jp z,rel_right_caution
    ld a,SPR_ARROW_RIGHT
    jp rel_right_store
rel_right_caution:
    ld a,SPR_CAUTION_RIGHT
rel_right_store:
    ld (de),a
    ld a,(RENDER_COUNT)
    inc a
    ld (RENDER_COUNT),a
rel_advance_one:
    ld a,(RENDER_COUNT)
    inc a
    ld (RENDER_COUNT),a
rel_next:
    pop hl
    ld de,EN_REC_SIZE
    add hl,de
    ld a,(RL_IDX)
    inc a
    cp EN_COUNT
    jp c,rel_idx_ok
    xor a
    ld hl,EN_BASE
rel_idx_ok:
    ld (RL_IDX),a
    pop bc
    dec b
    jp nz,rel_loop
    xor a
    ld (EN_ROT),a
    ret
rel_overflow:
    pop hl
    pop bc
    ld a,(RL_IDX)
    ld (EN_ROT),a
    ret

; HL = slot list. Same multiplexer for the 20 logical enemy projectiles.
render_bullet_list:
    ld a,(hl)
    ld (RL_MAX),a
    inc hl
    ld (RL_SLOTS),hl
    xor a
    ld (RENDER_COUNT),a
    ld a,(RL_ROTATE)
    or a
    jp z,rbl_start0
    ld a,(BUL_ROT)
    cp BUL_COUNT
    jp c,rbl_start
rbl_start0:
    xor a
rbl_start:
    ld (RL_IDX),a
    ld l,a
    ld h,0
    ld d,h
    ld e,l
    add hl,hl
    add hl,hl
    add hl,de             ; idx*5
    ld de,BUL_BASE
    add hl,de
    ld b,BUL_COUNT
rbl_loop:
    push bc
    push hl
    ld a,(hl)
    or a
    jp z,rbl_next
    ld (BUL_PTR),hl
    ld a,(RENDER_COUNT)
    ld c,a
    ld a,(RL_MAX)
    cp c
    jp z,rbl_overflow
    ld hl,(RL_SLOTS)
    ld e,c
    ld d,0
    add hl,de
    ld a,(hl)
    ld (RL_SLOT),a
    call slot_color_addr
    ld a,10                ; enemy projectiles: bright yellow
    call enemy_color_fill
    ld a,(RL_SLOT)
    call slot_sat_addr
    ld hl,(BUL_PTR)
    call render_one_bullet
    ld a,(RENDER_COUNT)
    inc a
    ld (RENDER_COUNT),a
rbl_next:
    pop hl
    ld de,BUL_REC_SIZE
    add hl,de
    ld a,(RL_IDX)
    inc a
    cp BUL_COUNT
    jp c,rbl_idx_ok
    xor a
    ld hl,BUL_BASE
rbl_idx_ok:
    ld (RL_IDX),a
    pop bc
    djnz rbl_loop
    xor a
    ld (BUL_ROT),a
    ret
rbl_overflow:
    pop hl
    pop bc
    ld a,(RL_IDX)
    ld (BUL_ROT),a
    ret

render_mid_only:
    call render_midboss
    ld a,1
    call get_layout
    push de
    call render_enemy_list
    pop hl
    call render_bullet_list
    jp render_commit

render_escort_only:
    ld hl,ESC0
    ld de,SATBUF+32
    call render_one_escort
    ld hl,ESC1
    ld de,SATBUF+40
    call render_one_escort
    ld hl,ESC2
    ld de,SATBUF+48
    call render_one_escort
    ld hl,ESC3
    ld de,SATBUF+56
    call render_one_escort
    ld hl,ESC4
    ld de,SATBUF+64
    call render_one_escort
    ld a,2
    call get_layout
    push de
    call render_enemy_list
    pop hl
    call render_bullet_list
    jp render_commit

render_one_escort:
    ld a,(hl)
    or a
    ret z
    inc hl
    ld b,(hl)
    inc hl
    ld c,(hl)
    ld a,c
    ld (de),a
    inc de
    ld a,b
    ld (de),a
    inc de
    ld a,SPR_INTRO_ESCORT_WHITE
    ld (de),a
    inc de
    inc de
    ld a,c
    ld (de),a
    inc de
    ld a,b
    ld (de),a
    inc de
    ld a,SPR_INTRO_ESCORT_ORANGE
    ld (de),a
    ret

; Complete 40x64 Sentinel graphic: 3 x 4 native 16x16 sprites.  Pattern masks
; preserve the silhouette; per-scanline colours are loaded by midboss_start.
render_midboss:
    ld a,(MID_Y)
    ld b,a
    ld a,(MID_X)
    ld c,a
    ; row 0
    ld a,b
    ld (SATBUF+32),a
    ld (SATBUF+36),a
    ld (SATBUF+40),a
    ld a,c
    ld (SATBUF+33),a
    add a,16
    ld (SATBUF+37),a
    add a,16
    ld (SATBUF+41),a
    ld a,SPR_SENTINEL_B0_0
    ld (SATBUF+34),a
    ld a,SPR_SENTINEL_B0_1
    ld (SATBUF+38),a
    ld a,SPR_SENTINEL_B0_2
    ld (SATBUF+42),a
    ; row 1
    ld a,b
    add a,16
    ld (SATBUF+44),a
    ld (SATBUF+48),a
    ld (SATBUF+52),a
    ld a,c
    ld (SATBUF+45),a
    add a,16
    ld (SATBUF+49),a
    add a,16
    ld (SATBUF+53),a
    ld a,SPR_SENTINEL_B1_0
    ld (SATBUF+46),a
    ld a,SPR_SENTINEL_B1_1
    ld (SATBUF+50),a
    ld a,SPR_SENTINEL_B1_2
    ld (SATBUF+54),a
    ; row 2
    ld a,b
    add a,32
    ld (SATBUF+56),a
    ld (SATBUF+60),a
    ld (SATBUF+64),a
    ld a,c
    ld (SATBUF+57),a
    add a,16
    ld (SATBUF+61),a
    add a,16
    ld (SATBUF+65),a
    ld a,SPR_SENTINEL_B2_0
    ld (SATBUF+58),a
    ld a,SPR_SENTINEL_B2_1
    ld (SATBUF+62),a
    ld a,SPR_SENTINEL_B2_2
    ld (SATBUF+66),a
    ; row 3
    ld a,b
    add a,48
    ld (SATBUF+68),a
    ld (SATBUF+72),a
    ld (SATBUF+76),a
    ld a,c
    ld (SATBUF+69),a
    add a,16
    ld (SATBUF+73),a
    add a,16
    ld (SATBUF+77),a
    ld a,SPR_SENTINEL_B3_0
    ld (SATBUF+70),a
    ld a,SPR_SENTINEL_B3_1
    ld (SATBUF+74),a
    ld a,SPR_SENTINEL_B3_2
    ld (SATBUF+78),a
    ret
render_one_bullet:
    ld a,(hl)
    or a
    ret z
    ld (TMP_HP),a                 ; bullet subtype
    inc hl
    ld b,(hl)
    inc hl
    ld c,(hl)
    ld a,c
    ld (de),a
    inc de
    ld a,b
    ld (de),a
    inc de
    ld a,(TMP_HP)
    cp 2
    jp nz,rob_generic
    ; FIX23 bullet354: chr131/132 alternating horizontal double shot.
    ld a,(ANIM_T)
    and 4
    jp z,rob_bar0
    ld a,SPR_CHR132
    jp rob_store
rob_bar0:
    ld a,SPR_CHR131
    jp rob_store
rob_generic:
    ld a,SPR_SHOT_FRONT2
rob_store:
    ld (de),a
    ret

render_commit:
    ld hl,SATBUF
    ld de,0x1E00
    ld bc,128
    call LDIRVM
    ret

set_enemy_slot_color:
    ; A = enemy kind (0 = death marker -> orange explosion), HL = colour slot.
    ; HYBRID: table lookup instead of a 33-way compare chain (same mapping).
    cp 33
    jp c,sesc_lookup
    ld a,8
    jp enemy_color_fill
sesc_lookup:
    push hl
    ld e,a
    ld d,0
    ld hl,enemy_kind_colors
    add hl,de
    ld a,(hl)
    pop hl
    jp enemy_color_fill
enemy_kind_colors:
    db 8,12,15,10,10,10,10,15,6,12,8,8,12,0,7,15,5,5,5,6,10,10,15,12,8,12,15,15,15,8,15,7,8
enemy_color_orange:
    ld a,8
    jp enemy_color_fill
enemy_color_yellow:
    ld a,10
    jp enemy_color_fill
enemy_color_green:
    ld a,12
    jp enemy_color_fill
enemy_color_white:
    ld a,15
    jp enemy_color_fill
enemy_color_red:
    ld a,6
    jp enemy_color_fill
enemy_color_cyan:
    ld a,7
    jp enemy_color_fill
enemy_color_blue:
    ld a,5
    jp enemy_color_fill
enemy_color_black:
    xor a
; A = colour, HL = colour-table address of one SAT slot (0x1C00 + slot*16).
; Mode-2 sprite colour is per SAT slot; skipping unchanged slots removes most of
; the per-frame VRAM traffic of the renderer (both engines).
enemy_color_fill:
    ld c,a
    ld a,h
    and 1
    rlca
    rlca
    rlca
    rlca
    ld b,a
    ld a,l
    rrca
    rrca
    rrca
    rrca
    and 15
    or b
    push hl
    ld e,a
    ld d,0
    ld hl,SLOT_COLOR
    add hl,de
    ld a,(hl)
    cp c
    jp z,ecf_same
    ld (hl),c
    pop hl
    ld a,c
    ld bc,16
    call FILVRM
    ret
ecf_same:
    pop hl
    ret

slot_color_invalidate:
    ld hl,SLOT_COLOR
    ld de,SLOT_COLOR+1
    ld bc,31
    ld a,0xFF
    ld (hl),a
    ldir
    ret

; A = SAT slot -> HL = colour-table address 0x1C00 + slot*16
slot_color_addr:
    ld l,a
    and 0xF0
    rrca
    rrca
    rrca
    rrca
    add a,0x1C
    ld h,a
    ld a,l
    rlca
    rlca
    rlca
    rlca
    and 0xF0
    ld l,a
    ret

; A = SAT slot -> DE = SATBUF + slot*4
slot_sat_addr:
    rlca
    rlca
    and 0x7C
    ld e,a
    ld d,SATBUF>>8
    ret

render_enemy:
    ld a,(hl)
    or a
    ret z
    ld (TMP_HP),a
    inc hl
    ld b,(hl)             ; x
    inc hl
    ld c,(hl)             ; y
    inc hl
    ld a,(hl)
    ld (TMP_KIND),a
    inc hl
    ld a,(hl)
    ld (TMP_LEN),a        ; state / death timer
    inc hl
    inc hl
    ld a,(hl)
    ld (TMP_PARAM),a

    ; Hidden ID99 trigger has collision/hit logic but no graphic in FIX23.
    ld a,(TMP_KIND)
    cp 13
    ret z
    ld a,c
    ld (de),a
    inc de
    ld a,b
    ld (de),a
    inc de

    ld a,(TMP_HP)
    cp 2
    jp z,ren_death
    ld a,(TMP_KIND)
    cp 1
    jp z,ren_chr104
    cp 2
    jp z,ren_chr133
    cp 3
    jp z,ren_wasp
    cp 4
    jp z,ren_wasp
    cp 5
    jp z,ren_wasp
    cp 6
    jp z,ren_wasp
    cp 7
    jp z,ren_chr130
    cp 8
    jp z,ren_type103
    cp 9
    jp z,ren_type101
    cp 12
    jp z,ren_type102
    cp 14
    jp z,ren_type10
    cp 15
    jp z,ren_type11
    cp 16
    jp z,ren_type106
    cp 17
    jp z,ren_type107
    cp 18
    jp z,ren_basic0
    cp 19
    jp z,ren_pop0
    cp 20
    jp z,ren_caution
    cp 21
    jp z,ren_arrow
    cp 22
    jp z,ren_arrow
    cp 23
    jp z,ren_stone
    cp 24
    jp z,ren_boss108
    cp 25
    jp z,ren_boss14
    cp 26
    jp z,ren_boss109
    cp 27
    jp z,ren_boss110
    cp 28
    jp z,ren_mid2_mine
    cp 29
    jp z,ren_basic0
    cp 30
    jp z,ren_pop0
    cp 31
    jp z,ren_mid2_mine
    cp 32
    jp z,ren_basic0
    jp ren_basic0
ren_death:
    ld a,(TMP_LEN)
    cp 2
    jp c,ren_death20
    cp 4
    jp c,ren_death21
    ld a,SPR_EXPLOSION22_ORANGE
    jp ren_store
ren_death20:
    ld a,SPR_EXPLOSION20_ORANGE
    jp ren_store
ren_death21:
    ld a,SPR_EXPLOSION21_ORANGE
    jp ren_store
ren_chr104:
    ld a,SPR_CHR104
    jp ren_store
ren_chr133:
    ld a,SPR_CHR133
    jp ren_store
ren_wasp:
    ld a,SPR_ENEMY_WASP
    jp ren_store
ren_chr130:
    ld a,SPR_CHR130
    jp ren_store
ren_type103:
    ld a,(TMP_PARAM)
    cp 115
    jp z,ren_103_115
    cp 117
    jp z,ren_103_117
    cp 119
    jp z,ren_103_119
    ld a,SPR_CHR113
    jp ren_store
ren_103_115: ld a,SPR_CHR115
    jp ren_store
ren_103_117: ld a,SPR_CHR117
    jp ren_store
ren_103_119: ld a,SPR_CHR119
    jp ren_store
ren_type101:
    ld a,(TMP_LEN)
    cp 24
    jp c,ren_101a
    cp 34
    jp nc,ren_101a
    ld a,SPR_CHR106
    jp ren_store
ren_101a: ld a,SPR_CHR106
    jp ren_store
ren_type102:
    ld a,(TMP_LEN)
    cp 24
    jp c,ren_102a
    cp 34
    jp nc,ren_102a
    ld a,SPR_CHR108
    jp ren_store
ren_102a: ld a,SPR_CHR108
    jp ren_store
ren_type10:
    ld a,(SCROLL_SUB)
    cp 5
    jp c,ren_10a
    ld a,SPR_CHR121
    jp ren_store
ren_10a: ld a,SPR_CHR121
    jp ren_store
ren_type11:
    ld a,(SCROLL_SUB)
    cp 5
    jp c,ren_11a
    ld a,SPR_CHR123
    jp ren_store
ren_11a: ld a,SPR_CHR123
    jp ren_store
ren_type106:
    ld a,(ANIM_T)
    and 4
    jp z,ren_106a
    ld a,SPR_CHR136
    jp ren_store
ren_106a: ld a,SPR_CHR135
    jp ren_store
ren_type107:
    ld a,(ANIM_T)
    and 4
    jp z,ren_107a
    ld a,SPR_CHR138
    jp ren_store
ren_107a: ld a,SPR_CHR137
    jp ren_store
ren_basic0:
    ld a,SPR_ENEMY_BASIC0
    jp ren_store
ren_pop0:
    ld a,SPR_ENEMY_POP0
    jp ren_store
ren_stone:
    ld a,SPR_STONE
    jp ren_store
ren_boss108:
    ld a,SPR_CHR159
    jp ren_store
ren_boss14:
    ld a,SPR_CHR163
    jp ren_store
ren_boss109:
    ld a,SPR_CHR185
    jp ren_store
ren_boss110:
    ld a,SPR_CHR196
    jp ren_store
ren_mid2_mine:
    ld a,SPR_CHR143
    jp ren_store
ren_caution:
    ld a,SPR_CAUTION_LEFT
    jp ren_store
ren_arrow:
    ld a,SPR_ARROW_LEFT
ren_store:
    ld (de),a
    ret

; Draw 32 visible columns.  BASE08 layout: HUD row 0, full 22-row
; playfield rows 1..22, 30 Volca-Stone indicators on row 23.
draw_stage:
    xor a
    ld (DRAW_ROW),a
    ld hl,0x1820
    ld (DRAW_VRAM),hl
draw_stage_loop:
    ld a,(DRAW_ROW)
    cp 22
    jp nc,draw_stage_finish
    ; row-directory entry = 3 * row at ROW_DIR_RAM
    ld e,a
    ld d,0
    ld hl,ROW_DIR_RAM
    add hl,de
    add hl,de
    add hl,de
    ld a,(hl)
    call select_bank
    inc hl
    ld a,(hl)
    ld (BANK_SRC),a
    inc hl
    ld a,(hl)
    ld (BANK_SRC+1),a
    ld hl,(BANK_SRC)
    ld a,(SCROLL_COL)
    ld e,a
    ld a,(SCROLL_COL+1)
    ld d,a
    add hl,de
    ld a,(DRAW_VRAM)
    ld e,a
    ld a,(DRAW_VRAM+1)
    ld d,a
    ld bc,32
    call LDIRVM
    ld hl,(DRAW_VRAM)
    ld de,32
    add hl,de
    ld (DRAW_VRAM),hl
    ld a,(DRAW_ROW)
    inc a
    ld (DRAW_ROW),a
    jp draw_stage_loop
draw_stage_finish:
    call restore_data_bank
    call hud_draw
    call draw_stone_row
    ret

; LIVE HUD: the fixed name row is only a template.  Rebuild both seven-digit
; counters and the two-digit reserve indicator on every logical tick.
; HI is the original default 39600 until persistent highscore is implemented.
hud_draw:
    call restore_data_bank
    ld hl,(HUD_PTR_RAM)
    ld de,HUD_ROW_BUF
    ld bc,32
    ldir
    ld hl,hud_initial_hi
    ld de,HUD_ROW_BUF+3
    call hud_draw_7
    ld hl,SCORE_DIGITS
    ld de,HUD_ROW_BUF+19
    call hud_draw_7
    ld a,(LIVES)
    or a
    jp z,hud_lives_zero
    dec a                        ; original displays reserves (lives - 1)
hud_lives_zero:
    ld b,0
hud_lives_tens:
    cp 10
    jp c,hud_lives_units
    sub 10
    inc b
    jp hud_lives_tens
hud_lives_units:
    ld (HUD_TMP),a
    ld a,b
    call hud_lookup
    ld (HUD_ROW_BUF+30),a
    ld a,(HUD_TMP)
    call hud_lookup
    ld (HUD_ROW_BUF+31),a
    ld hl,HUD_ROW_BUF
    ld de,0x1800
    ld bc,32
    call LDIRVM
    ret

hud_draw_7:
    ld b,7
hud_draw_digit:
    ld a,(hl)
    inc hl
    push hl
    push bc
    call hud_lookup
    pop bc
    pop hl
    ld (de),a
    inc de
    djnz hud_draw_digit
    ret

; A=0..9 => tile index for this stage's SCREEN4 zone0.
hud_lookup:
    ld l,a
    ld h,0
    ld bc,HUD_DIGITS
    add hl,bc
    ld a,(hl)
    ret

hud_initial_hi:
    db 0,0,3,9,6,0,0

; Award 1000 on a real Volca-Stone; the score is a seven-digit decimal counter.
score_add_1000:
    ld hl,SCORE_DIGITS+3
    jp score_carry
score_add_100:
    ld hl,SCORE_DIGITS+4
    jp score_carry

; Stage-1 points come from FIX23 script: 100 default; 105/101/102/106/
; 107 = 300; 125 = 200; 200 = 500; warnings 300/301 = 0.
score_add_enemy:
    ld hl,(EN_PTR)
    ld de,3
    add hl,de
    ld a,(hl)               ; family assigned at stage spawn
    cp 20
    ret z                   ; warning without score
    cp 21
    ret z
    ld b,1                  ; 100
    cp 7
    jp z,score_enemy_300
    cp 9
    jp z,score_enemy_300
    cp 12
    jp z,score_enemy_300
    cp 16
    jp z,score_enemy_300
    cp 17
    jp z,score_enemy_300
    cp 18
    jp z,score_enemy_200
    cp 19
    jp nz,score_enemy_loop
    ld b,5
    jp score_enemy_loop
score_enemy_300:
    ld b,3
    jp score_enemy_loop
score_enemy_200:
    ld b,2
score_enemy_loop:
    push bc
    call score_add_100
    pop bc
    djnz score_enemy_loop
    ret

score_carry:
    ld a,(hl)
    inc a
    cp 10
    jp c,score_store
    xor a
    ld (hl),a
    dec hl
    ld a,h
    cp 0xC0
    jp nz,score_carry
    ld a,l
    cp 0xEF                  ; before first score digit
    ret z
    jp score_carry
score_store:
    ld (hl),a
    call score_check_extend
    ret

; lexicographic BCD compare; earned extends award +1 life then +50000.
score_check_extend:
    ld hl,SCORE_DIGITS
    ld de,EXTEND_DIGITS
    ld b,7
score_cmp_loop:
    ld a,(de)
    cp (hl)
    jp c,score_extend
    jp nz,score_cmp_next
    inc hl
    inc de
    djnz score_cmp_loop
    jp score_extend
score_cmp_next:
    ret
score_extend:
    ld a,(LIVES)
    cp 99
    jp nc,score_extend_update
    inc a
    ld (LIVES),a
score_extend_update:
    ld hl,EXTEND_DIGITS+2
    ld a,(hl)
    add a,5
    cp 10
    jp c,score_extend_store
    sub 10
    ld (hl),a
    dec hl
    ld a,(hl)
    inc a
    cp 10
    jp c,score_extend_store
    xor a
score_extend_store:
    ld (hl),a
    ret

draw_stone_row:
    ld hl,STONE_ROW_BUF
    ld de,0x1AE0
    ld bc,32
    call LDIRVM
    ret



; ---------------- Kraken Stage-1 source event tables ----------------------------
; BOSS_PAT_T is pre-incremented, hence source times are stored +1.
boss_death_events:
    db 16,224,40, 20,200,120, 24,192,56, 28,224,136
    db 32,200,24, 36,216,112, 40,192,64, 44,200,128
    db 48,224,24, 52,192,136, 56,200,32, 60,216,80

boss_spike_events:
    db 1,192,52, 9,188,128, 17,200,84, 25,188,32
    db 41,188,136, 49,192,40, 57,196,100, 65,192,64
    db 81,200,84, 89,188,128, 97,192,32, 105,188,100
    db 121,196,68, 129,200,106, 137,188,36, 145,184,136
boss_tentacle_events:
    ; time+1, kind26(type109)/27(type110), native x,y
    db 5,26,144,160, 17,27,48,24, 29,26,8,160, 41,27,128,24
    db 53,26,160,160, 65,27,16,24, 77,26,80,160, 89,27,144,24

; ---------------- Stage-1 movement tables (FIX23 direction domain 0..63) -------
; Native MSX2 deltas after the HSPDX 640->320 coordinate conversion.
dir_dx6:
    db 0,1,1,2,2,3,3,4,4,5,5,5,6,6,6,6
    db 6,6,6,6,6,5,5,5,4,4,3,3,2,2,1,1
    db 0,255,255,254,254,253,253,252,252,251,251,251,250,250,250,250
    db 250,250,250,250,250,251,251,251,252,252,253,253,254,254,255,255
dir_dy6:
    db 250,250,250,250,250,251,251,251,252,252,253,253,254,254,255,255
    db 0,1,1,2,2,3,3,4,4,5,5,5,6,6,6,6
    db 6,6,6,6,6,5,5,5,4,4,3,3,2,2,1,1
    db 0,255,255,254,254,253,253,252,252,251,251,251,250,250,250,250
dir_dx4:
    db 0,0,1,1,2,2,2,3,3,3,3,4,4,4,4,4
    db 4,4,4,4,4,4,3,3,3,3,2,2,2,1,1,0
    db 0,0,255,255,254,254,254,253,253,253,253,252,252,252,252,252
    db 252,252,252,252,252,252,253,253,253,253,254,254,254,255,255,0
dir_dy4:
    db 252,252,252,252,252,252,253,253,253,253,254,254,254,255,255,0
    db 0,0,1,1,2,2,2,3,3,3,3,4,4,4,4,4
    db 4,4,4,4,4,4,3,3,3,3,2,2,2,1,1,0
    db 0,0,255,255,254,254,254,253,253,253,253,252,252,252,252,252
wave12_native:
    db 0,8,6,4,3,2,1,0,0,255,254,253,252,250,248,248
    db 250,252,253,254,255,0,0,1,2,3,4,6,8

; ---------------- FIXED BANK-0 RESOURCES --------------------------------------
; 32-byte V9938 palette generated from the canonical FIX23 palette.
palette: incbin "../../generated/palette.bin"

game_sat_template:
    db 200,0,0,0
    db 200,0,4,0
    db 200,0,8,0
    db 200,0,12,0
    db 200,0,16,0
    db 200,0,20,0
    db 200,0,24,0
    db 200,0,28,0
    db 200,0,32,0
    db 200,0,36,0
    db 200,0,40,0
    db 200,0,44,0
    db 200,0,48,0
    db 200,0,52,0
    db 200,0,56,0
    db 200,0,60,0
    db 200,0,64,0
    db 200,0,68,0
    db 200,0,72,0
    db 200,0,76,0
    db 200,0,80,0
    db 200,0,84,0
    db 200,0,88,0
    db 200,0,92,0
    db 200,0,96,0
    db 200,0,100,0
    db 200,0,104,0
    db 200,0,108,0
    db 200,0,112,0
    db 200,0,116,0
    db 200,0,120,0
    db 216,0,0,0

    engine_end:
    assert engine_start == ENGINE_ENTRY, "engine entry moved"
    assert engine_end <= 0x8000, "engine bank overflow"
    ds 0x8000-$,0xFF
