/* ================================================================== one logic tick (label_051 body) */
static void game_tick(void)
{
    ncopy = 0;
    hull_req = FALSE;
    if (stage == 1) scroll053(); else if(stage==2) scroll054(); else if(stage==3) scroll055();else if(stage==4)scroll056();else if(stage==5)scroll057();else scroll058();     /* label_052 */
    if (stage == 1) stars082();                         /* label_071 (stars: stage 1 only) */
    if (stage == 1) events585(); else if(stage==2) events586(); else if(stage==3) events587();else if(stage==4)events588();else if(stage==5)events589();else events590();      /* label_584 */
    if(stage>=5)background_tick();
    player096();                 /* label_096 */
    if (boss_mode == 0 && script_tick4 == 0) script119();
    enemies122();
    bullets358();
    timeover_vis = (boss_mode >= 2 && boss_death_t < 64 && (boss_death_t % 16) < 10 && boss_timer <= 0);   /* label_081 */
    hud093();
    es_draw();
    /* label_051 epilogue */
    if (music_fade < 0 && lives > 0)          /* label_064 */
    {
        AUD_setMusicVolume(music_fade);
        music_fade -= 40;
        if (music_fade <= -2300) { music_fade = 0; AUD_stopMusic(); AUD_playMusic(MUS_BOSS); }
    }
    se_played = 0;
    if (fx_timer > 0) fx_timer--;
    map_anim8=anim8;
    anim8++; if (anim8 >= 8) anim8 = 0;
    map_anim16=anim16;
    anim16++; if (anim16 >= 16) anim16 = 0;
    if (boss_mode == 0) { script_tick4++; if (script_tick4 >= 4) script_tick4 = 0; }
}

static u16 read_stick(u16 joy)
{
    u16 s = 0;
    if (joy & BUTTON_LEFT) s |= 1;
    if (joy & BUTTON_UP) s |= 2;
    if (joy & BUTTON_RIGHT) s |= 4;
    if (joy & BUTTON_DOWN) s |= 8;
    if (joy & BUTTON_A) s |= 16;
    return s;
}

static const u8 ntscWait[5] = {2, 2, 2, 2, 1};   /* 5 ticks / 9 VBlanks = 33.3 Hz */

static void wait_frames(u16 n) { while (n--) SYS_doVBlankProcess(); }

static void black_screen(u16 frames)
{
    VDP_clearPlane(BG_A, TRUE); VDP_clearPlane(BG_B, TRUE);
    VDP_setSpriteFull(0, -32, -32, SPRITE_SIZE(1, 1), 0, 0); VDP_updateSprites(1, DMA_QUEUE);
    wait_frames(frames);
}

/* label_673..676: GAME OVER / CONTINUE. returns TRUE if continue */
static bool game_over(void)
{
    u16 t;
    AUD_stopAll();
    black_screen(SYS_isPAL() ? 10 : 12);
    while (PAD_read() & (BUTTON_A | BUTTON_B | BUTTON_C | BUTTON_START)) SYS_doVBlankProcess();
    AUD_playMusic(MUS_OVER);
    for (t = 0; t < 190; t++)
    {
        u16 f, joy;
        sat_count = 0;
        put_gfx(2102, 32 + 92, 24 + 56, TRUE);
        put_gfx(2103, 32 + 68, 24 + 88, TRUE);
        if (sat_count) VDP_setSpriteLink(sat_count - 1, 0);
        else { VDP_setSpriteFull(0, -32, -32, SPRITE_SIZE(1, 1), 0, 0); sat_count = 1; }
        VDP_updateSprites(sat_count, DMA_QUEUE);
        joy = PAD_read();
        if (joy & (BUTTON_A | BUTTON_B | BUTTON_C | BUTTON_START))
        {
            AUD_stopAll();
            black_screen(SYS_isPAL() ? 25 : 30);
            return TRUE;
        }
        f = SYS_isPAL() ? ((t & 1) ? 1 : 2) : ntscWait[t % 5];
        wait_frames(f);
    }
    AUD_stopAll();
    FRONTEND_requestAttract();
    return FALSE;
}

static bool paused;

void GAME_run(void)
{
    u16 prevJoy = 0;
    s16 i;
    static const s16 sx[21] = {472,152,328,224,544,188,176,400,288,128,504,240,352,176,480,64,288,416,152,288,472};
    AUD_init();
    /* label_037 new game */
    record_offered = hiscore; megaqr_pending = FALSE;
    stage = 1; score = 0; lives = start_lives; next_extend = 20000; deaths = 0;
#ifndef VOLCA_TEST
    cheat_invincible = debugMode ? 1 : 0;                  /* title DEBUG (C) */
#endif
    if (debugMode) stage = debugStage;
#ifdef VOLCA_START_STAGE
    stage = VOLCA_START_STAGE;   /* test builds only: start directly at a later stage */
#endif
    memset(stone_got, 0, sizeof(stone_got));
    for (i = 0; i < 21; i++) star_x[i] = sx[i];
    {
        bool card = (stage != 1);   /* stage 1 card is shown by main() before GAME_run */
restart:
    megaqr_pending=FALSE;
    es_clear();
    player_init();
    stage_init();            /* label_040/049: music starts here, then label_670 card */
    if (card)
    {
        VDP_setScrollingMode(HSCROLL_PLANE, VSCROLL_PLANE);
        VDP_setHorizontalScroll(BG_A, 0); VDP_setHorizontalScroll(BG_B, 0);
        VDP_setSpriteFull(0, -32, -32, SPRITE_SIZE(1, 1), 0, 0); VDP_updateSprites(1, DMA_QUEUE);
        if (stage == 1) showArea1Card(); else if(stage==2) showArea2Card(); else if(stage==3) showArea3Card();else if(stage==4)showArea4Card();else if(stage==5)showArea5Card();else showArea6Card();
    }
    card = TRUE;
    gfx_init();
    draw_all_columns();
    update_scroll();
    paused = FALSE;
    {
        u32 vbase = vtimer, done = 0;
        while (TRUE)
        {
            u16 joy = PAD_read();
            u16 pressed = joy & ~prevJoy;
            u32 due;
            u8 ran = 0;
            prevJoy = joy;
            if (pressed & BUTTON_C)
            {
                cheat_invincible ^= 1;
                AUD_playSE(12, 0);
            }
            if (pressed & BUTTON_START)
            {
                u32 pauseStart = vtimer;
                s16 action;
                paused = TRUE;
                action = runPauseMenu(stage, cheat_invincible != 0);
                paused = FALSE;
                if (action < 0) { AUD_stopAll(); black_screen(1); return; }
                if (action > 0)
                {
                    stage = action;
                    prevJoy = 0;
                    goto restart;
                }
                draw_all_columns(); render_all(); /* Overlay only: gameplay VRAM/SAT stay intact. */
                vbase += vtimer - pauseStart;
                prevJoy = PAD_read();
                joy = 0; pressed = 0;
            }
            if (!paused)
            {
                /* original Time Manager: 30 ms per tick. NTSC: 5 ticks / 9 VBlanks, PAL: 2 ticks / 3 VBlanks.
                   Ticks are scheduled from the VBlank counter so a slow tick never slows the game down. */
                u32 el = vtimer - vbase;
                due = SYS_isPAL() ? (el * 2) / 3 : (el * 5) / 9;
                while (done < due && ran < 4)
                {
                    stick = read_stick(joy);
                    dirbtn = (joy & BUTTON_B) ? 1 : 0;
                    game_tick();
                    done++; ran++;
                    if (stage_clear > 0 || pl_state >= 1070 || (megaqr_pending && pl_state >= 1035)) break;
                }
                /* Preserve pending logical ticks; rendering load must not discard gameplay time. */
                if (ran) render_all();
                if (megaqr_pending && pl_state >= 1035)
                {
                    u32 recordStart=vtimer;
                    record_offered=score;megaqr_pending=FALSE;paused=TRUE;
                    if(runMegaQRRecord((u32)score,vtimer))
                    {
                        paused=FALSE;AUD_stopAll();black_screen(1);return;
                    }
                    paused=FALSE;draw_hud_static();hud_force=TRUE;draw_all_columns();render_all();
                    vbase+=vtimer-recordStart;prevJoy=PAD_read();
                }
                if (stage_clear > 0)                    /* label_672 */
                {
                    es_clear(); render_sprites();
                    black_screen(SYS_isPAL() ? 10 : 12);   /* asleep 200 */
                    stage++;
                    if (stage <= 6) goto restart;          /* label_697 -> label_039/040 */
                    AUD_stopAll();
                    ending_run();return;                /* label_678..694 */
                }
                if (pl_state >= 1070)
                {
                    if (game_over())
                    {
                        score = 0; lives = start_lives; next_extend = 20000;   /* label_038 */
                        memset(stone_got, 0, sizeof(stone_got));
                        goto restart;                   /* label_697 -> label_040 -> label_670 (same stage) */
                    }
                    return;
                }
            }
            SYS_doVBlankProcess();
        }
    }
    }
}
