/* ================================================================== label_039 / label_040 */
static void player_init(void)       /* label_039 */
{
    pl_x = -32; pl_y = 224;
    if (stage == 1) { pl_x = 192; pl_y = 96; }
    pl_state = 0; pl_invuln_len = 64; dirbtn_latch = 1; shot_dir = 2;
    memset(shot_on, 0, sizeof(shot_on));
    shot_cool = 0;
}

static void stage_init(void)        /* label_040 + label_049 (stage 1) */
{
    s16 c, r;
    map_anim16=0;map_anim8=0;fx_timer = 0; se_played = 0; scroll_col = 0; scroll_sub = 0; anim8 = 0; anim16 = 0;
    script_tick4 = 0; scroll_speed = 8; script_end = 0; stone_popup = 0; music_fade = 0; stage_clear = 0;
    boss_mode = 0; boss_death_t = 0; boss_pat = 0; boss_pat_t = 0; boss_timer = 0;     /* label_426 */
    memset(en_state, 0, sizeof(en_state)); memset(en_type, 0, sizeof(en_type));
    memset(en_score, 0, sizeof(en_score)); memset(en_hp, 0, sizeof(en_hp)); memset(en_param, 0, sizeof(en_param));
    script_pos = 0;
    intro_mx = 176; intro_my = 168; intro_t = 0;
    fall_x = 32; fall_y = 264; fall_t = 0; fall_vol = -2000;
    waterfall1_off = 0; waterfall2_off = 0;
    if (stage == 1)
    {
        map_rom = stage1_map_rom; attr_tab = stage1_attr; tile_lut = stage1_tile_lut; script = stage1_script;
        map_cols = STAGE1_COLS; ram_col0 = 340; ram_col1 = 504;
        spr_pc = spr1_pieces; spr_index = spr1_index; spr_gfx = spr1_gfx;
    }
    else if(stage==2)
    {
        map_rom = stage2_map_rom; attr_tab = stage2_attr; tile_lut = stage2_tile_lut; script = stage2_script;
        map_cols = STAGE2_COLS; ram_col0 = 83; ram_col1 = 169;
        spr_pc = spr2_pieces; spr_index = spr2_index; spr_gfx = spr2_gfx;
    }
    else if(stage==3)
    {
        map_rom=stage3_map_rom;attr_tab=stage3_attr;tile_lut=stage3_tile_lut;script=stage3_script;
        map_cols=STAGE3_COLS;ram_col0=0;ram_col1=STAGE3_COLS;
        spr_pc=spr3_pieces;spr_index=spr3_index;spr_gfx=spr3_gfx;
    }
    else if(stage==4)
    {
        map_rom=stage4_map_rom;attr_tab=stage4_attr;tile_lut=stage4_tile_lut;script=stage4_script;
        map_cols=STAGE4_COLS;ram_col0=0;ram_col1=STAGE4_COLS;
        spr_pc=spr4_pieces;spr_index=spr4_index;spr_gfx=spr4_gfx;
    }
    else if(stage==5){
        map_rom=stage5_map_rom;attr_tab=stage5_attr;tile_lut=stage5_tile_lut;script=stage5_script;
        map_cols=STAGE5_COLS;ram_col0=0;ram_col1=STAGE5_COLS;
        spr_pc=spr5_pieces;spr_index=spr5_index;spr_gfx=spr5_gfx;
    }else{
        map_rom=stage6_map_rom;attr_tab=stage6_attr;tile_lut=stage6_tile_lut;script=stage6_script;
        map_cols=STAGE6_COLS;ram_col0=0;ram_col1=STAGE6_COLS;
        spr_pc=spr6_pieces;spr_index=spr6_index;spr_gfx=spr6_gfx;
    }
    stage56_reset();stage4_reset();stage3_reset();dbg_sentinel_bank_conflict=0;dbg_poke_overflow=0;dbg_missing_chr=0;dbg_script_total=dbg_script_dropped=dbg_generated_dropped=dbg_boss_patterns=0;memset(dbg_seen_types,0,sizeof(dbg_seen_types));
    for (c = ram_col0; c < ram_col1; c++) for (r = 0; r < 22; r++) mapram[c - ram_col0][r] = map_rom[c * 22 + r];
    loop_off = 0;
    gate_close_step = 0; gate_open_step = 0; water_y = 80;
    npoke = 0;
    AUD_stopAll();
    if(stage<=2) AUD_playMusic(stage == 1 ? MUS_STAGE1 : MUS_STAGE2); /* F3 theme deferred; original F3 WAV unavailable. */   /* label_068 var_133 = 101 */
}

/* ================================================================== label_119/121 script */
static void spawn121(s16 id, s16 x, s16 y, s16 sc, s16 hp, s16 param)
{
    s16 n;
    dbg_script_total++;
    if (id <= 99) n = es_new(100); else n = es_new(120);
    if (n >= 140) {dbg_script_dropped++;return;}
    if (id == 99 && stone_got[param]) return;
    es_set(n, x, y, 1000);
    n -= 100;
    en_state[n] = 1; en_type[n] = id; en_score[n] = sc; en_hp[n] = hp; en_param[n] = param;
}

static void script119(void)
{
    if (script_end) return;
    while (1)
    {
        s16 t = script[script_pos];
        if (t == -1) { script_pos++; return; }
        if (t == -2) { script_end = 1; return; }
        spawn121(script[script_pos], script[script_pos + 1], script[script_pos + 2],
                 script[script_pos + 3], script[script_pos + 4], script[script_pos + 5]);
        script_pos += 6;
    }
}

