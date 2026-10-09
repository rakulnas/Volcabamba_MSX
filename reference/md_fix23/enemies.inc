/* ================================================================== enemies label_122/123 */
static bool off346(s16 n, s16 slot, s16 x, s16 y)
{
    if (x >= 32 && x <= 592 && y >= 32 && y <= 432) return FALSE;
    es_kill(n); en_state[slot] = 0; return TRUE;
}
static bool off347(s16 n, s16 slot, s16 x, s16 y)
{
    if (x >= 32 && x <= 608 && y <= 432) return FALSE;
    es_kill(n); en_state[slot] = 0; return TRUE;
}
static bool off348(s16 n, s16 slot, s16 x, s16 y)
{
    if (x >= -64 && x <= 592 && y >= -64 && y <= 432) return FALSE;
    es_kill(n); en_state[slot] = 0; return TRUE;
}
static u8 tile351(s16 x, s16 y, s16 ox, s16 oy)
{
    return view_attr((x - 64 + ox) / 16, (y - 64 + oy) / 16);
}

/* label_365: explosion of slot i (en_state > 999) */
static void death365(s16 i)
{
    s16 n = i + 100, x = es_getx(n), y = es_gety(n), t = en_type[i], typ = es[n].type, c;
    if (scroll_sub == 0)
    {
        if (t == 1 || t == 36 || t == 37 || t == 48 || t == 49 || (t >= 64 && t <= 68) || (t >= 101 && t <= 103) ||
            t == 106 || t == 107 || t == 112 || t == 114 || t == 116 || t == 119 || t == 121 || t == 122 || t == 125 ||
            (t >= 202 && t <= 204) || (t >= 206 && t <= 210)) x -= 16;
        else if (t == 214) x += 16;
        else if (t == 99) x -= 16;
    }
    if (en_state[i] == 1000)       /* label_366 */
    {
        if (t == 3) { x -= 8; y -= 8; }
        else if (t == 200) { y += 8; }
        else if (t == 101 || t == 102) { x += 8; y += 8; }
        else if (t == 105) { y += 8; }
        else if (t == 12) { x -= 4; y += 8; }
        else if (t == 106) { x -= 4; y += 8; switch605(); }
        else if (t == 107) { x -= 4; y += 8; switch606(); }
        else if (t == 64) { x -= 6; y -= 6; }
        else if (t == 111) { y += 8; }
        else if (t == 202) { y -= 16; }
        else if (t == 79) { x -= 8; y -= 8; }
        else if (t == 500) { boss_mode = 2; x -= 24; y -= 24; }
        else if (t == 506) { boss_mode = 2; x += 16; y += 16; }
        else if (t == 507) { boss_mode=2;x-=16;y-=24; }
        else if (t == 25 || t == 203) { x-=8;y-=8; }
        else if (t == 116) { x+=8;y+=8; }
        else if (typ == 8) spawn349(199, x, y, 0, 1, en_param[i]);
    }
    c = (en_state[i] - 1000) / 2 + 510;
    if (t >= 200) c += 20;
    if ((t < 200 && c >= 514) || (t >= 200 && c >= 534)) { en_state[i] = 0; es_kill(n); return; }
    es_set(n, x, y, c);
    en_state[i]++;
}

static void enemy_update(s16 i)    /* label_123 */
{
    s16 n = i + 100, x, y, t, c, k;
    if(en_type[i]>=0 && en_type[i]<600)dbg_seen_types[en_type[i]]=1;
    if(stage>=5 && stage56_enemy(i))return;
    if(stage==4 && stage4_enemy(i))return;
    if (en_state[i] > 999) { death365(i); return; }
    if(stage==3 && stage3_enemy(i))return;
    x = es_getx(n); y = es_gety(n); t = en_type[i];
    switch (t)
    {
    case 2:                                         /* label_133 */
        if (off346(n, i, x, y)) return;
        if (en_param[i] == 5) x -= 8;
        if (en_param[i] == 4) { x -= 4; en_param[i] = 5; }
        if (en_param[i] == 3) { x -= 4; en_param[i] = 4; }
        if (en_param[i] == 2) { x -= 2; en_param[i] = 3; }
        if (en_param[i] == 1) { x -= 2; en_param[i] = 2; }
        if (en_param[i] == 0) { x -= 2; en_param[i] = 1; }
        es_set(n, x, y, anim8 >= 4 ? 505 : 504); es_type(n, 128);
        return;
    case 3:                                         /* label_134 */
        if (off346(n, i, x, y)) return;
        es_set(n, x, y, anim8 >= 4 ? 103 : 102); es_type(n, 32);
        if (en_state[i] == 1) es_adir(n, en_param[i], 800);
        en_state[i] = 1;
        return;
    case 4:                                         /* label_135 */
        if (off346(n, i, x, y)) return;
        if ((anim8 & 1) == 0) x -= 16;
        es_set(n, x, y, en_param[i]); es_type(n, 32);
        return;
    case 5: case 7:                                 /* label_136 */
        if (off346(n, i, x, y)) return;
        k = (t == 7) ? 22 : 20;
        en_state[i]++;
        if (en_state[i] >= k)
        {
            en_param[i]++;
            if (en_param[i] >= 64) en_param[i] = 0;
            if (en_param[i] == 29) en_param[i] = 28;
            en_state[i] = k - 1;
        }
        es_set(n, x, y, 105); es_adir(n, en_param[i], 1200); es_type(n, 32);
        if (stage <= 4 || en_state[i] != 5) return;
        bullet352(x, y, 12, 12);
        return;
    case 6: case 8:                                 /* label_137 */
        if (off346(n, i, x, y)) return;
        k = (t == 8) ? 22 : 26;
        en_state[i]++;
        if (en_state[i] >= k)
        {
            en_param[i]--;
            if (en_param[i] < 0) en_param[i] = 63;
            if (en_param[i] == 3) en_param[i] = 4;
            en_state[i] = k - 1;
        }
        es_set(n, x, y, 105); es_adir(n, en_param[i], 1200); es_type(n, 32);
        if (stage <= 4 || en_state[i] != 5) return;
        bullet352(x, y, 12, 12);
        return;
    case 9:                                         /* label_138 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        en_state[i]++;
        c = 110;
        if (en_state[i] >= 8) c = 111;
        if (en_state[i] >= 16) c = 112;
        if (en_param[i] == 0) y -= 8; else y += 8;
        es_set(n, x, y, c); es_type(n, 128);
        k = tile351(x, y, 16, 16);
        if (k == 1 || k == 4) { es_kill(n); en_state[i] = 0; }
        return;
    case 10: case 11:                               /* label_139 / label_140 */
        if (off346(n, i, x, y)) return;
        c = (t == 10) ? 121 : 123;
        if (scroll_sub > scroll_speed / 2) c++;
        es_set(n, x, y, c); es_adir(n, en_param[i], 800); es_type(n, 32);
        k = tile351(x, y, 16, 16);
        if (k == 1 || k == 4) { es_kill(n); en_state[i] = 0; }
        return;
    case 12:                                        /* label_141 */
    {
        static const s8 wave[29] = {0, 16, 12, 8, 6, 4, 2, 0, 0, -2, -4, -6, -8, -12, -16, -16, -12, -8, -6, -4, -2, 0, 0, 2, 4, 6, 8, 12, 16};
        if (off346(n, i, x, y)) return;
        if (en_state[i] >= 1 && en_state[i] <= 28) y += wave[en_state[i]];
        if (en_param[i] == 0) { x -= 6; es_set(n, x, y, 133); }
        if (en_param[i] == 1) { x += 6; es_set(n, x, y, 179); }
        es_type(n, 32);
        en_state[i]++;
        if (en_state[i] > 28) en_state[i] = 1;
        return;                                     /* stage 1: never fires */
    }
    case 13:                                        /* label_142 */
        if (off346(n, i, x, y)) return;
        if (en_state[i] >= 23) return;
        if (en_state[i] == 22) { es_set(n, x, y, 144); es_type(n, 128); es_aim(n, pl_x, pl_y, 800); en_state[i]++; return; }
        if (en_state[i] >= 6)
        {
            c = 144;
            if (anim8 == 2 || anim8 == 3 || anim8 == 6 || anim8 == 7) c = 145;
            es_set(n, x, y, c); es_type(n, 128); en_state[i]++; return;
        }
        x += 8; es_set(n, x, y, 143); en_state[i]++;
        return;
    case 14:                                        /* label_146 */
        if (off346(n, i, x, y)) return;
        c = 163;
        if (anim8 == 2 || anim8 == 3 || anim8 == 6 || anim8 == 7) c = 164;
        k = en_param[i];
        if (k < 4) c = 160;
        else if (k < 8) c = 161;
        else if (k < 12) c = 162;
        else if (k < 18) { }
        else if (k < 19) { x -= 2; se(3); }
        else if (k < 20) x -= 8;
        else x -= 12;
        es_set(n, x, y, c);
        if (en_param[i] >= 18) es_type(n, 128);
        en_param[i]++;
        return;
    case 15:                                        /* label_148 */
        if (off346(n, i, x, y)) return;
        if (en_state[i] == 1) { x -= 4; y += 10; c = 165; }
        else { x -= 4; y -= 10; c = 166; }
        es_set(n, x, y, c); es_type(n, 32);
        if (en_state[i] == 2) return;
        k = tile351(x, y, 16, 32);
        if (k == 1 || k == 4) en_state[i] = 2;
        return;
    case 16:                                        /* label_149 */
    {
        s16 st = en_state[i];
        if (st > 44) return;
        if (off346(n, i, x, y)) return;
        if (st == 1) y += (en_param[i] == 0) ? 12 : -12;
        if (st == 2) y += (en_param[i] == 0) ? 8 : -8;
        if (st == 3) y += (en_param[i] == 0) ? 4 : -4;
        if (st == 4) y += (en_param[i] == 0) ? 2 : -2;
        c = 173;
        if (st >= 24) c = 144;
        if (st >= 5 && st <= 23 && (anim8 == 2 || anim8 == 3 || anim8 == 6 || anim8 == 7)) c = 144;
        es_set(n, x, y, c);
        if (st >= 6) es_type(n, 128);
        if (st >= 24) es_aim(n, pl_x, pl_y, 700);
        en_state[i]++;
        return;
    }
    case 17: case 18:                               /* label_150/151 , label_153/154 */
        if (off346(n, i, x, y)) return;
        if (en_state[i] < 2)
        {
            if (scroll_sub == 0) x -= 16;
            c = (t == 17) ? 207 : 211;
            if (x <= 120 && (anim8 & 1)) c++;
            es_set(n, x, y, c);
            if (x <= 80) { en_state[i] = 2; se(2); }
            return;
        }
        k = en_param[i] / 10;
        if (t == 17) y -= k; else y += k;
        en_param[i] -= 6;
        if (en_param[i] <= -160) en_param[i] = -160;
        if (en_state[i] <= 8) x += 8;
        else if (en_state[i] <= 12) x += 6;
        else x += 4;
        c = (t == 17) ? 209 : 213;
        if (en_param[i] <= 0) c++;
        es_set(n, x, y, c); es_type(n, 32);
        en_state[i]++;
        return;
    case 21:                                        /* label_160 */
        if (off346(n, i, x, y)) return;
        if (en_param[i] == 5) x -= 10;
        if (en_param[i] == 4) { x -= 8; en_param[i] = 5; }
        if (en_param[i] == 3) { x -= 4; en_param[i] = 4; }
        if (en_param[i] == 2) { x -= 4; en_param[i] = 3; }
        if (en_param[i] == 1) { x -= 2; en_param[i] = 2; }
        if (en_param[i] == 0) { x -= 2; en_param[i] = 1; }
        es_set(n, x, y, anim8 >= 4 ? 505 : 504); es_type(n, 128);
        return;
    case 22:                                        /* label_161 */
        if (off346(n, i, x, y)) return;
        x += 12;
        es_set(n, x, y, anim8 >= 4 ? 176 : 175); es_type(n, 128);
        if (en_state[i] == 1) { se(15); en_state[i] = 2; }
        return;
    case 23:                                        /* label_162 */
        if (off346(n, i, x, y)) return;
        x -= 10;
        if (en_param[i] == 0) { y -= 4; c = 215; } else { y += 4; c = 217; }
        if (anim8 == 2 || anim8 == 3 || anim8 == 6 || anim8 == 7) c++;
        es_set(n, x, y, c); es_type(n, 128);
        return;
    case 24:                                        /* label_163 */
        if (off346(n, i, x, y)) return;
        x -= 6;
        if (en_param[i] == 0) y -= 6; else y += 6;
        c = 144;
        if (anim8 == 2 || anim8 == 3 || anim8 == 6 || anim8 == 7) c = 145;
        es_set(n, x, y, c); es_type(n, 128);
        if (en_state[i] > 1) en_state[i]--;
        if (en_state[i] > 1) return;
        k = tile351(x, y, 16, 16);
        if (k == 1 || k == 4)
        {
            en_param[i] = (en_param[i] == 0) ? 1 : 0;
            en_state[i] = 8;
            se(4);
        }
        return;
    case 79:                                        /* label_242 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        if ((anim8 & 1) == 0)
        {
            k = en_param[i];
            if (k >= 1 && k <= 8) en_param[i]--;
            if (k >= 24 && k <= 31) en_param[i]++;
            if (k >= 33 && k <= 40) en_param[i]--;
            if (k >= 56 && k <= 63) en_param[i]++;
            if (en_param[i] >= 64) en_param[i] = 0;
        }
        es_set(n, x, y, anim8 >= 4 ? 447 : 446); es_type(n, 32);
        es_adir(n, en_param[i], 500);
        return;
    case 64:                                        /* label_225 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        if (en_param[i] == 0) y -= 6; else y += 6;
        if (en_param[i] == 0 && y <= 160) { es_kill(n); en_state[i] = 0; return; }
        if (en_param[i] == 1 && y >= 296) { es_kill(n); en_state[i] = 0; return; }
        c = 423; if (anim8 == 2 || anim8 == 3 || anim8 == 6 || anim8 == 7) c++;
        es_set(n, x, y, c); es_type(n, 32);
        return;
    case 99:                                        /* label_344 */
        if (scroll_sub == 0) x += reverse_scroll?16:-16;
        if (off346(n, i, x, y)) return;
        es_set(n, x, y, 1001); es_type(n, 8);
        return;
    case 100:                                       /* label_261 */
        en_state[i]++;
        if (en_state[i] < 22)
        {
            es_set(n, x, y, (anim8 & 1) ? 151 : 1000);
            return;
        }
        if (en_state[i] < 24)
        {
            if (en_state[i] == 22) { fx_timer = 8; se(13); }
            es_set(n, x, y, 152); es_type(n, 128);
            return;
        }
        if (en_state[i] < 26) { es_set(n, x, y, 153); return; }
        if (en_state[i] < 28) { es_set(n, x, y, 154); return; }
        es_kill(n); en_state[i] = 0;
        return;
    case 101: case 102:                             /* label_266 / label_268 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        c = (t == 101) ? 106 : 108;
        en_param[i]++;
        if (en_param[i] >= 80) en_param[i] = 0;
        k = en_param[i];
        if (x > 80)
        {
            if (k >= 24 && k <= 33) c++;
            if (k == 34 || k == 42 || k == 50)
            {
                if (t == 101) spawn349(9, x + 8, y - 12, 0, 1, 0);
                else spawn349(9, x + 8, y + 30, 0, 1, 1);
                se(4);
            }
        }
        es_set(n, x, y, c); es_type(n, 32);
        return;
    case 103:                                       /* label_270 (F1: cycle 500, never fires; F2: cycle 144, fires at 20) */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        c = en_param[i];
        if (scroll_sub > scroll_speed / 2) c++;
        es_set(n, x, y, c); es_type(n, 32);
        en_state[i]++;
        if (stage == 1 && en_state[i] > 500) en_state[i] = 1;
        if (stage == 2 && en_state[i] > 144) en_state[i] = 1;
        if (stage == 1) return;
        if (x <= 112) return;
        if (en_state[i] != 20) return;
        {
            s16 ox = 12, oy = 12;
            if (en_param[i] == 113 && pl_y < y) { oy -= 4; bullet352(x, y, ox, oy); }
            if (en_param[i] == 115 && pl_y > y) { oy += 4; bullet352(x, y, ox, oy); }
            if (en_param[i] == 117 && pl_x > x) { ox += 4; bullet352(x, y, ox, oy); }
            if (en_param[i] == 119 && pl_x < x) { ox -= 4; bullet352(x, y, ox, oy); }
        }
        return;
    case 105:                                       /* label_272 */
        if (off346(n, i, x, y)) return;
        if ((anim8 & 1) == 0)
        {
            if (en_state[i] == 1) x -= 16;
            if (en_state[i] >= 20) x += 16;
            if (en_state[i] == 1 && x <= en_param[i]) en_state[i] = 2;
            if (en_state[i] >= 2) en_state[i]++;
            if (en_state[i] == 6) bullet354(x, y);
            if (en_state[i] == 9) bullet354(x, y);
        }
        es_set(n, x, y, 130); es_type(n, 32);
        return;
    case 106: case 107:                             /* label_273 / label_274 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        c = (t == 106) ? 135 : 137;
        if (scroll_sub > scroll_speed / 2) c++;
        es_set(n, x, y, c); es_type(n, 32);
        return;
    case 108:                                       /* label_275 */
        if (off346(n, i, x, y)) return;
        x -= 16;
        es_set(n, x, y, 159); es_type(n, 128);
        return;
    case 109: case 110:                             /* label_276 / label_278 */
    {
        s16 p = en_param[i];
        if (p == 42) { es_kill(n); en_state[i] = 0; return; }
        if (t == 109)
        {
            if (p < 3) c = 185;
            else if (p == 3) { c = 186; y -= 16; }
            else if (p < 16) c = 186;
            else if (p <= 24) { c = 187 + (p - 16); y -= 16; if (p == 16) se(21); }
            else if (p < 32) c = 195;
            else { c = 194 - (p - 32); y += 16; }
        }
        else
        {
            if (p < 3) c = 196;
            else if (p < 16) c = 197;
            else if (p <= 24) { c = 198 + (p - 16); if (p == 16) se(21); }
            else if (p < 32) c = 206;
            else c = 205 - (p - 32);
        }
        es_set(n, x, y, c);
        if (p >= 16) es_type(n, 128);
        en_param[i]++;
        return;
    }
    case 111:                                       /* label_280/281/282 */
        if (off346(n, i, x, y)) return;
        k = en_param[i];
        if (k < 8) x -= 16;
        else if (k < 120)
        {
            if (anim8 == 4)                         /* label_282 */
            {
                s16 b = es_new(0);
                if (b < 20)
                {
                    es_set(b, x, y + 20, 500);
                    es_adir(b, 40 + (random() % 17), 600);
                    es_type(b, 64);
                }
            }
        }
        else if (k < 144) { }
        else x -= 16;
        es_set(n, x, y, 167); es_type(n, 32);
        en_param[i]++;
        return;
    case 112:                                       /* label_283 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        k = en_state[i];
        if (k == 1 || k == 18) y += 8;
        if (k == 2 || k == 17) y += 4;
        if (k == 3 || k == 16) y += 2;
        if (k == 7 || k == 12) y -= 2;
        if (k == 8 || k == 11) y -= 4;
        if (k == 9 || k == 10) y -= 8;
        en_state[i]++;
        if (en_state[i] >= 19) en_state[i] = 1;
        es_set(n, x, y, 112); es_type(n, 32);
        return;
    case 113:                                       /* label_284 */
        if (off346(n, i, x, y)) return;
        x -= 16;
        es_set(n, x, y, 178); es_type(n, 128);
        if (en_state[i] == 1) { se(13); en_state[i] = 2; }
        return;
    case 125:                                       /* label_301 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        en_state[i]++;
        if (en_state[i] > 56) en_state[i] = 1;
        c = en_param[i];
        if (x > 200 && en_state[i] >= 24 && en_state[i] <= 35) c += 2;
        es_set(n, x, y, c); es_type(n, 32);
        if (en_state[i] != 36 || x <= 200) return;
        if (en_param[i] == 378) spawn349(64, x + 6, y - 4, 50, 1, 0);
        else spawn349(64, x + 6, y + 16, 50, 1, 1);
        se(4);
        return;
    case 199:                                       /* label_345 */
        if (scroll_sub == 0 && en_state[i] > 1) x += reverse_scroll?16:-16;
        if (off346(n, i, x, y)) return;
        c = 90; if (en_state[i] >= 32) c = 91;
        es_set(n, x, y, c); es_type(n, 16);
        en_state[i]++;
        if (en_state[i] > 33) en_state[i] = 2;
        return;
    case 200:                                       /* label_310 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        if (anim8 == 2 || anim8 == 6)
        {
            en_param[i]++;
            if (en_param[i] >= 18) en_param[i] = 2;
            k = en_param[i];
            if (k >= 2 && k <= 4) y += 16;
            if (k >= 7 && k <= 12) y -= 16;
            if (k >= 15 && k <= 17) y += 16;
        }
        es_set(n, x, y, 150); es_type(n, 32);
        if ((anim8 == 2 || anim8 == 6) && (en_param[i] == 5 || en_param[i] == 13) && x > pl_x)
        {
            spawn349(2, x - 24, y + 44, 0, 1, 0);
            se(15);
        }
        return;
    case 201:                                       /* label_311 */
        if (scroll_sub == 0) x -= 16;
        if (off347(n, i, x, y)) return;
        y += 12;
        es_set(n, x, y, 134); es_type(n, 128);
        return;
    case 202:                                       /* label_312 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        es_set(n, x, y, en_param[i]); es_type(n, 32);
        en_state[i]++;
        if (en_state[i] > 160) en_state[i] = 160;
        if (x <= 96) return;
        if (en_state[i] != 42) return;
        if (en_param[i] == 170)
        {
            spawn349(79, x + 2, y, 50, 1, 39);
            spawn349(79, x + 46, y, 50, 1, 25);
        }
        else
        {
            spawn349(79, x + 2, y + 14, 50, 1, 57);
            spawn349(79, x + 46, y + 14, 50, 1, 7);
        }
        se(2);
        return;
    case 250:                                       /* label_374 Centinela Ocular #1 */
    {
        s16 st = en_state[i];
        if (st == 1)                                /* label_375 */
        {
            if (en_param[i] == 0) { se(23); en_param[i] = 1; }
            x -= 16;
            if (x <= 272) { en_state[i]++; en_param[i] = 0; }
            es_set(n, x, y, 180); es_type(n, 32);
        }
        else if (st == 2)                           /* label_376 */
        {
            en_param[i]++;
            if (en_param[i] >= 6) { en_state[i]++; en_param[i] = 0; }
            es_set(n, x, y, 180); es_type(n, 32);
        }
        else if (st == 3)                           /* label_377 */
        {
            if ((anim8 & 1) == 0)
            {
                x += 16; if (x > 448) x = 448;
                en_param[i]++;
                if (en_param[i] >= 11) { en_param[i] = 0; en_state[i]++; }
            }
            es_set(n, x, y, 180); es_type(n, 32);
        }
        else if (st == 4 || st == 6 || st == 8 || st == 10)   /* label_378 */
        {
            if (en_param[i] == 0)
            {
                spawn349(100, 64, y + 24, 0, 1, 0);
                spawn349(100, 64, y + 90, 0, 1, 0);
            }
            c = 180;
            if (st >= 10 && en_param[i] >= 16) c = 235;
            es_set(n, x, y, c); es_type(n, 32);
            en_param[i]++;
            if (en_param[i] >= 32) { en_param[i] = 0; en_state[i]++; }
        }
        else if (st == 5 || st == 7 || st == 9)     /* label_379 */
        {
            k = en_param[i];
            if ((anim8 & 1) == 0)
            {
                if (k >= 0 && k <= 3) y -= 16;
                if (k >= 4 && k <= 11) y += 16;
                if (k >= 12 && k <= 19) y -= 16;
                if (k >= 20 && k <= 27) y += 16;
                if (k >= 28 && k <= 31) y -= 16;
                en_param[i]++;
            }
            if (en_param[i] >= 32) { en_state[i]++; en_param[i] = 0; }
            es_set(n, x, y, 180); es_type(n, 32);
            if (k <= 20 && (anim8 == 2 || anim8 == 6))
            {
                spawn349(3, x + 32, y + 56, 10, 1, 45 + (random() % 7));
                se(4);
            }
        }
        else if (st == 11)                          /* label_380 */
        {
            if (en_param[i] >= 4 && en_param[i] <= 6) y += 16;
            if (en_param[i] >= 18) y -= 16;
            en_param[i]++;
            if (y <= -32) { es_kill(n); en_state[i] = 0; return; }
            es_set(n, x, y, 235); es_type(n, 32);
        }
        return;
    }
    case 251:                                       /* label_381 Centinela Ocular #2 */
    {
        s16 st = en_state[i];
        if (st >= 32)                               /* label_387 */
        {
            if (scroll_sub == 0 || scroll_sub == 4) x -= 16;
            if (x <= 0) { es_kill(n); en_state[i] = 0; return; }
            es_set(n, x, y, 180); es_type(n, 32);
            if (x > 128)
            {
                if (st == 40) { spawn349(13, x + 48, y + 24, 0, 1, 0); se(2); }
                if (st == 60) { spawn349(13, x + 48, y + 72, 0, 1, 1); se(2); }
            }
            en_state[i]++;
            if (en_state[i] >= 72) en_state[i] = 32;
        }
        else if (st >= 13) { en_state[i]++; es_set(n, x, y, 180); es_type(n, 32); }        /* label_386 */
        else if (st == 12)                                                                   /* label_385 */
        {
            y -= 16; if (y <= 176) en_state[i]++;
            es_set(n, x, y, 180); es_type(n, 32);
        }
        else if (st >= 3) { en_state[i]++; es_set(n, x, y, 180); es_type(n, 32); }         /* label_384 */
        else if (st == 2)                                                                    /* label_383 */
        {
            y += 16; if (y >= 208) en_state[i]++;
            es_set(n, x, y, 180); es_type(n, 32);
        }
        else if (st == 1)                                                                    /* label_382 */
        {
            s16 cc;
            en_state[i]++;
            y += 16;
            es_set(n, x, y, 180); es_type(n, 32);
            se(6);
            es_set(35, x - 24, 64, 139); es_flag(35, 1024 + 12); es_adir(35, 49, 200); es_gravity(35, 0, 120);
            es_set(36, x + 8, 62, 139);  es_flag(36, 1024 + 12); es_adir(36, 59, 440); es_gravity(36, 0, 120);
            es_set(37, x + 48, 78, 139); es_flag(37, 1024 + 12); es_adir(37, 3, 460);  es_gravity(37, 0, 120);
            es_set(38, x + 64, 64, 139); es_flag(38, 1024 + 12); es_adir(38, 8, 320);  es_gravity(38, 0, 120);
            for (cc = 0; cc < 7; cc++) { poke(343 + cc, 0, 1); poke(343 + cc, 1, 1); }
        }
        return;
    }
    case 300:                                       /* label_339 */
        if (en_param[i] == 653 && scroll_sub == 0) x -= 16;
        k = en_state[i];
        if (k == 1 || k == 9 || k == 17 || k == 25) se(14);
        c = 650;
        if ((k >= 5 && k <= 8) || (k >= 13 && k <= 16) || (k >= 21 && k <= 24)) c = 1000;
        if (k >= 29) { es_kill(n); en_state[i] = 0; return; }
        es_set(n, x, y, c);
        en_state[i]++;
        return;
    case 301:                                       /* label_340 */
        if (en_param[i] == 653 && scroll_sub == 0) x -= 16;
        k = en_state[i];
        c = en_param[i];
        if ((k >= 5 && k <= 8) || (k >= 13 && k <= 16) || (k >= 21 && k <= 24)) c = 1000;
        if (k >= 29) { es_kill(n); en_state[i] = 0; return; }
        es_set(n, x, y, c);
        en_state[i]++;
        return;
    case 302:                                       /* label_341 */
        if (en_state[i] == 1) se(6);
        k = en_state[i];
        if (k <= 2) c = 530; else if (k <= 4) c = 531; else if (k <= 6) c = 532; else if (k <= 8) c = 533;
        else { es_kill(n); en_state[i] = 0; return; }
        es_set(n, x, y, c);
        en_state[i]++;
        return;
    case 303:                                       /* label_343 */
        if (scroll_sub == 0) x -= 16;
        if (off346(n, i, x, y)) return;
        c = 234; if (anim8 >= 4) c = 1000;
        es_set(n, x, y, c);
        if (waterfall1_off > 0) { es_kill(n); en_state[i] = 0; }
        return;
#include "bosses.inc"
    default:
        return;
    }
}

static void enemies122(void)
{
    s16 i;
    for (i = 0; i < 40; i++) if (en_state[i] > 0) enemy_update(i);
}

