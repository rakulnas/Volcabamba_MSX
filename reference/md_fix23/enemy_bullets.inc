/* ================================================================== enemy bullets label_352/354 */
static void bullet352(s16 x, s16 y, s16 ox, s16 oy)
{
    s16 n = es_new(0), cx, cy;
    u8 a;
    if (n >= 20) return;
    cx = (x + 4 + ox - 64) / 16;
    cy = (y + 4 + oy - 64) / 16;
    if (cx > 31 || cx < 0 || cy > 21 || cy < 0) return;
    a = attr_tab[map_id(scroll_col + cx, cy)];
    if (a == 1 || a == 4) return;
    es_set(n, x + ox, y + oy, 500);
    es_aim(n, pl_x + 12, pl_y + 12, (stage <= 4) ? 400 : 600);
    es_type(n, 64);
}
static void bullet354(s16 x, s16 y)
{
    s16 n = es_new(0);
    if (n >= 20) return;
    es_set(n, x - 8, y + 8, 131);
    es_adir(n, 48, 1000);
    es_type(n, 64);
    se(3);
    n = es_new(0);
    if (n >= 20) return;
    es_set(n, x - 8, y + 32, 131);
    es_adir(n, 48, 1000);
    es_type(n, 64);
}

/* label_358: enemy bullets vs map */
static void bullets358(void)
{
    s16 from = 0;
    while (1)
    {
        s16 n = es_find(64, from), x, y, c, off = 4, cx, cy;
        u8 a;
        if (n < 0) return;
        x = es_getx(n); y = es_gety(n); c = es[n].chr;
        if (x < 56 || x > 576 || y < 40 || y > 416) { es_kill(n); goto next; }
        if (c == 146 || c == 147) off = 10;
        else if (c == 225) off = 12;
        else if (c == 245 || c == 246 || c == 252 || c == 253 || c == 302 || c == 303) goto next;
        cx = (x + off - 64) / 16; cy = (y + off - 64) / 16;
        if (cx < 0) cx = 0; else if (cx > 31) cx = 31;
        if (cy < 0) cy = 0; else if (cy > 21) cy = 21;
        a = attr_tab[map_id(scroll_col + cx, cy)];
        if (a == 1 || a == 4) es_kill(n);
    next:
        from = n + 1;
        if (from >= 20) return;
    }
}

