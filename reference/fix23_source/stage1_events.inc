/* ================================================================== label_052/053 scroll */
static void boss427(void)
{
    boss_mode = 1; boss_death_t = 0;
    spawn349(500, 528, 232, 10000, 700, 0);
    boss_timer = 1394;
}

static void scroll053(void)
{
    if (boss_mode > 0) return;
    scroll_sub++;
    if (scroll_sub >= scroll_speed) { scroll_sub = 0; scroll_col++; }
    if (scroll_sub == 0 && scroll_col == 454) music_fade = -1;
    if (scroll_col >= 471) boss427();
}

/* ================================================================== label_082 stars (logic) */
static void stars082(void)
{
    s16 i;
    for (i = 0; i < 18; i++)
    {
        if (star_fast[i] == 0) { if ((anim8 & 1) == 0) star_x[i] -= 2; }
        else star_x[i] -= 2;
        if (star_x[i] < 64) star_x[i] = 574;
    }
}

/* ================================================================== prologue label_593 */
static void prologue593(void)
{
    s16 w = 544 - intro_mx, h = 272 - intro_my, m;
    s16 v = 0;
    bool closed = (intro_t >= 18 && intro_t <= 22) || (intro_t >= 67 && intro_t <= 71);   /* label_594 */
    bool open = (intro_t >= 23 && intro_t <= 66);                                          /* label_595 */
    pl_state = 12;
    /* the docked-ship sprite 35 (chr 24) is set by 594/595 but killed again when intro_t > 62 */
    if (closed) v = (intro_t <= 62) ? 1 : 3;
    if (open) v = (intro_t <= 62) ? 2 : 4;
    if (intro_t <= 130) { hull_req = TRUE; hull_x0 = intro_mx; hull_y0 = intro_my; hull_w = w; hull_h = h; hull_v = v; hull_prio = TRUE; }
    m = intro_t % 6;
    if (intro_t >= 84)
    {
        if (m == 5) { intro_mx -= 16; intro_my += 16; }
        if (intro_mx < 16) intro_mx = 16;
        if (intro_my > 264) intro_my = 264;
    }
    if (intro_t >= 89 && intro_t <= 112 && (anim8 & 1))
    {
        static const s16 offs[6] = {384, 352, 320, 160, 128, 96};
        for (m = 0; m < 6; m++) add_copy(2100, 64 + (w - offs[m]), 64 + h);   /* label_596 */
    }
    if (intro_t == 30) { AUD_playSE(17, 0); se_played = 1; }
    if (intro_t == 89) se(18);
    if (intro_t >= 30 && intro_t < 86)
    {
        pl_y += 2;
        if (intro_t <= 62) es_set(51, pl_x, pl_y + 14, (anim8 & 1) ? 1000 : 4);
        else { es_kill(51); es_kill(35); }
        es_set(50, pl_x, pl_y, 0);
    }
    if (intro_t >= 89 && intro_t < 94)
    {
        if (intro_t <= 90) pl_x += 16; else pl_x += 8;
        if (intro_t <= 90) es_set(51, pl_x - 32, pl_y, 3); else es_kill(51);
        es_set(50, pl_x, pl_y, 0);
    }
    intro_t++;
}

/* ================================================================== nodriza derribada label_597/598/599 */
static void fall597(void)
{
    s16 m = fall_t % 6, w, h;
    if (m == 0 || m == 3) fall_x += 16;
    if (m == 2) { fall_y -= 16; if (fall_y < 0) fall_y = 0; }
    w = 544 - fall_x;
    if (w > 16)
    {
        h = 272 - fall_y;
        hull_req = TRUE; hull_x0 = fall_x; hull_y0 = fall_y; hull_w = w; hull_h = h; hull_v = 0; hull_prio = FALSE;
        {
            static const s16 tt[10] = {2, 8, 16, 18, 24, 32, 36, 42, 50, 58};
            static const s16 tx[10] = {384, 240, 120, 80, 300, 200, 232, 180, 128, 64};
            static const s16 ty[10] = {64, 80, 64, 112, 120, 180, 80, 64, 192, 128};
            s16 i;
            for (i = 0; i < 10; i++) if (fall_t == tt[i])
            {
                s16 n = es_new(35);
                es_set(n, tx[i], ty[i], 600);
                es_flag(n, 32768 + 32);
            }
        }
        fall_t++;
    }
}

static void fallsnd599(void)
{
    if (scroll_col < 119) { fall_vol += 70; if (fall_vol > -300) fall_vol = -300; }
    if (scroll_col > 130) { fall_vol -= 50; if (fall_vol < -9000) fall_vol = -9000; }
    if (scroll_col >= 119 && scroll_col <= 130) fall_vol = -300;
    if (anim8 == 0 || anim8 == 4) se_vol(19, fall_vol);
}

/* escort ships label_601 */
static void escort601(s16 y)
{
    s16 n = es_new(60);
    es_set(n, 32, y, 23);
    es_adir(n, 16, 1600);
}

/* waterfalls label_602/603/604 */
static void fall604(s16 x)
{
    spawn349(201, x, -32, 0, 1, 0);
    se(20);
}
static void cascade602(void)
{
    if (waterfall1_off > 0 || scroll_sub != 0) return;
    if (scroll_col >= 343 && scroll_col <= 371 && ((scroll_col - 343) & 1) == 0)
        fall604(544 - 32 * ((scroll_col - 343) >> 1));
}
static void cascade603(void)
{
    if (waterfall2_off > 0 || scroll_sub != 4) return;
    if (scroll_col >= 351 && scroll_col <= 379 && ((scroll_col - 351) & 1) == 0)
        fall604(544 - 32 * ((scroll_col - 351) >> 1));
}
static void switch605(void)    /* label_605: cascade 1 plug */
{
    s16 c;
    waterfall1_off = 1;
    for (c = 0; c < 5; c++) poke(372 + c, 0, 189);
}
static void switch606(void)    /* label_606: cascade 2 plug */
{
    s16 c;
    waterfall2_off = 1;
    for (c = 0; c < 5; c++) poke(381 + c, 0, 189);
}

/* ================================================================== boss death label_444/445/446 */
static void pokes_str(s16 col, s16 row, const u16* ids, s16 n)
{
    s16 i;
    for (i = 0; i < n; i++) poke(col, row + i, ids[i]);
}
static void boss445(void)
{
    static const u16 a[2] = {600, 610}, b[2] = {601, 611};
    AUD_stopMusic();
    es_kill(35);
    pokes_str(471 + 29, 10, a, 2);
    pokes_str(471 + 30, 10, b, 2);
}
static void boss446(void)
{
    static const u16 c25a[3] = {763, 1, 1};
    static const u16 c25b[3] = {1, 1, 853};
    static const u16 c26[14] = {764, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 854};
    static const u16 c27[10] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
    static const u16 c28[10] = {766, 776, 786, 1, 1, 1, 1, 836, 846, 856};
    static const u16 c29[10] = {767, 777, 787, 797, 807, 817, 827, 837, 847, 857};
    static const u16 c30[10] = {768, 778, 788, 798, 808, 818, 828, 838, 848, 858};
    static const u16 c31[10] = {769, 779, 789, 799, 809, 819, 829, 839, 849, 859};
    pokes_str(471 + 25, 3, c25a, 3);
    pokes_str(471 + 25, 16, c25b, 3);
    pokes_str(471 + 26, 4, c26, 14);
    pokes_str(471 + 27, 6, c27, 10);
    pokes_str(471 + 28, 6, c28, 10);
    pokes_str(471 + 29, 6, c29, 10);
    pokes_str(471 + 30, 6, c30, 10);
    pokes_str(471 + 31, 6, c31, 10);
}
static void boss444(void)
{
    static const s16 bt[12] = {16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60};
    static const s16 bx[12] = {512, 464, 448, 512, 464, 496, 448, 464, 512, 448, 464, 496};
    static const s16 by[12] = {128, 288, 160, 320, 96, 272, 176, 304, 96, 320, 112, 208};
    s16 i;
    if (boss_death_t == 0) boss445();
    for (i = 0; i < 12; i++) if (boss_death_t == bt[i]) spawn349(302, bx[i], by[i], 0, 1, 0);
    if (boss_death_t == 40) boss446();
    if (boss_death_t == 120) stage_clear = 1;
    boss_death_t++;
}

/* ================================================================== label_585 F1 events */
static void events585(void)
{
    if (intro_t <= 124) prologue593();
    if (scroll_col == 0 && scroll_sub == 2) escort601(192);
    if (scroll_col == 1 && scroll_sub == 0) escort601(280);
    if (scroll_col == 1 && scroll_sub == 4) escort601(232);
    if (scroll_col == 3 && scroll_sub == 2) escort601(200);
    if (scroll_col == 3 && scroll_sub == 6) escort601(280);
    if (scroll_col >= 119 && scroll_col <= 130) fall597();
    if (scroll_col >= 116 && scroll_col <= 133) fallsnd599();
    if (scroll_col >= 343 && scroll_col <= 371) cascade602();
    if (scroll_col >= 351 && scroll_col <= 379) cascade603();
    if (boss_mode >= 2) boss444();
}

