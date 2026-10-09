/* ================================================================== player label_096..118 */
static void dir106(void)
{
    if (shotMode > 0 || dirbtn) /* B cycles in both modes (requested port control). */
    {
        if (!dirbtn) { dirbtn_latch = 0; return; }
        if (dirbtn_latch) return;
        if (dirMode4 == 0) { shot_dir++; if (shot_dir > 3) shot_dir = 0; }
        else { shot_dir += 2; if (shot_dir > 3) shot_dir = 0; }
        dirbtn_latch = 1;
        se(28);
        return;
    }
    dirbtn_latch = 0;
    if (stick & 16) return;
    if (dirbtn) return;
    if ((stick & 1) || (stick & 4)) shot_dir = 2;
    if ((stick & 2) || (stick & 8)) shot_dir = 0;
    if ((stick & 1) && (stick & 2)) shot_dir = 3;
    if ((stick & 4) && (stick & 8)) shot_dir = 3;
    if ((stick & 2) && (stick & 4)) shot_dir = 1;
    if ((stick & 1) && (stick & 8)) shot_dir = 1;
}

static void enemy_kill364(s16 slot)   /* label_364: explosion sound */
{
    s16 t = en_type[slot], id = 7;
    fx_timer = 10;
    if (t >= 100) id = 8;
    if (t >= 200) id = 6;
    if (t == 10 || t == 11 || t == 99 || t == 1 || t == 34 || t == 36 || t == 37 || t == 43 || t == 48 || t == 49 || t == 55 || t == 68 || t == 75) id = 8;
    if (t == 106 || t == 107 || t == 111 || t == 116 || t == 122) id = 6;
    se(id);
}

static void pickup102(void)
{
    s16 n = es_check(50, 16), slot, x, y;
    if (n < 0) return;
    x = es_getx(n); y = es_gety(n);
    slot = n - 100;
    en_state[slot] = 0;
    es_kill(n);
    score += 1000;
    se(16);
    stone_got[en_param[slot]] = 1;
    es_set(30, x, y + 8, 93);
    stone_popup = 20;
}

static void touch103(void)
{
    s16 n, slot;
    if (!(stick & 16)) return;
    n = es_check(50, 8);
    if (n < 0) return;
    slot = n - 100;
    enemy_kill364(slot);
    en_state[slot] = 1000;
    score += en_score[slot];
}

static void popup105(void)
{
    s16 x, y, c;
    if (stone_popup <= 0) return;
    x = es_getx(30); y = es_gety(30);
    stone_popup--;
    if (stone_popup <= 0) { es_kill(30); stone_popup = 0; return; }
    if (scroll_sub == 0) x -= 16;
    if (x <= 32) { es_kill(30); stone_popup = 0; return; }
    c = 93;
    if ((anim8 & 1) == 0) c = 1000;
    es_set(30, x, y, c);
}

#include "weapons.inc"

static void player096(void)
{
    if (stage == 1 && intro_t <= 94) { dir106(); return; }   /* label_097 */
    if (pl_state >= 1000)                                    /* label_118 */
    {
        if (pl_state == 1000)
        {
            megaqr_pending = score > record_offered;
        lives--;
            if (lives <= 0) AUD_stopMusic();
            se(11);
            deaths++; if (deaths > 9999) deaths = 9999;
        }
        pl_chr = 20;
        if (pl_state >= 1010) pl_chr = 21;
        if (pl_state >= 1020) pl_chr = 22;
        if (pl_state >= 1030) pl_chr = 1000;
        es_set(50, pl_x, pl_y, pl_chr);
        pl_state++;
        popup105();
        if (pl_state <= 1040) return;
        if (lives <= 0) return;
        player_init();
        pl_x = -32; pl_y = 224;
        return;
    }
    pl_chr = 0;
    if (pl_state >= 12)          /* label_098 */
    {
        s16 k = 0;
        if (stick & 1) k += 1;
        if (stick & 2) { k += 2; pl_chr = 1; }
        if (stick & 4) k += 4;
        if (stick & 8) { k += 8; pl_chr = 2; }
        if (k == 1) pl_x -= 8;
        if (k == 2) pl_y -= 8;
        if (k == 4) pl_x += 8;
        if (k == 8) pl_y += 8;
        if (k == 3) { pl_x -= 6; pl_y -= 6; }
        if (k == 9) { pl_x -= 6; pl_y += 6; }
        if (k == 6) { pl_x += 6; pl_y -= 6; }
        if (k == 12) { pl_x += 6; pl_y += 6; }
        if (pl_x < 64) pl_x = 64;
        if (pl_x > 512) pl_x = 512;
        if (pl_y < 64) pl_y = 64; else if (pl_y > 392) pl_y = 392;
        dir106();
        if (!(cheat_invincible != 0 || pl_state < pl_invuln_len || boss_mode >= 2))
        {
            s16 c = (pl_x - 64 + 16) / 16, r = (pl_y - 64 + 16) / 16;
            u8 a;
            if (c > 31) c = 31; else if (c < 0) c = 0;
            if (r > 21) r = 21; else if (r < 0) r = 0;
            a = attr_tab[map_id(scroll_col + c, r)];
            dbg_player_death_cause=0;dbg_player_death_attr=a;
            if (a == 1 || a == 2 || a == 4 || a == 5) {pl_state = 1000;dbg_player_death_cause|=1;}
            if (es_check(50, 32 + 64 + 128) != -1) {pl_state = 1000;dbg_player_death_cause|=2;}
        }
        /* label_100 */
        pickup102();
        touch103();
        popup105();
        if ((stick & 16) && shot_cool == 0) fire109();    /* label_108 */
        {                                                  /* label_112 */
            s16 i;
            for (i = 0; i < 3; i++) if (shot_on[0][i]) shot113(0, i);
            for (i = 0; i < 3; i++) if (shot_on[1][i]) shot113(1, i);
        }
        if (shot_cool > 0) shot_cool--;
    }
    else
    {
        pl_x += 16;
        dir106();
    }
    /* label_101 */
    if (pl_state == 0) se(18);
    if (pl_state < pl_invuln_len)
    {
        if (anim8 & 1) pl_chr = 1000;
        pl_state++;
    }
    if (boss_mode >= 2) { if (anim8 & 1) pl_chr = 1000; }
    es_set(50, pl_x, pl_y, pl_chr);
    flame591();
}

