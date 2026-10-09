    case 500:                                       /* label_438 Kraken */
        boss_timer--;
        if (boss_timer <= 0) { en_state[i] = 1000; se(6); return; }
        if (boss_pat == 0 || boss_pat == 3)         /* label_439 */
        {
            es_set(35, 512, 224, 155 + ((boss_pat_t / 2) % 4));
            boss_pat_t++;
            if (boss_pat_t >= 25) { boss_pat++; boss_pat_t = 0; es_kill(35); }
        }
        else if (boss_pat == 1 || boss_pat == 4)    /* label_440 */
        {
            if (boss_pat_t == 0 || boss_pat_t == 4 || boss_pat_t == 8 || boss_pat_t == 12)
            {
                se(15);
                spawn349(108, 496, 224, 10, 1, 0);
            }
            boss_pat_t++;
            if (boss_pat_t >= 16) { boss_pat++; boss_pat_t = 0; }
        }
        else if (boss_pat == 2)                     /* label_441 */
        {
            static const s16 pt[16] = {0, 8, 16, 24, 40, 48, 56, 64, 80, 88, 96, 104, 120, 128, 136, 144};
            static const s16 px[16] = {448, 440, 464, 440, 440, 448, 456, 448, 464, 440, 448, 440, 456, 464, 440, 432};
            static const s16 py[16] = {152, 304, 216, 112, 320, 128, 248, 176, 216, 304, 112, 248, 184, 260, 120, 320};
            for (k = 0; k < 16; k++) if (boss_pat_t == pt[k]) spawn349(14, px[k], py[k], 10, 1, 0);
            boss_pat_t++;
            if (boss_pat_t >= 160) { boss_pat = 3; boss_pat_t = 0; }
        }
        else if (boss_pat == 5)                     /* label_442 */
        {
            static const s16 tt[8] = {4, 16, 28, 40, 52, 64, 76, 88};
            static const s16 tid[8] = {109, 110, 109, 110, 109, 110, 109, 110};
            static const s16 tx[8] = {352, 160, 80, 320, 384, 96, 224, 352};
            static const s16 ty[8] = {368, 96, 368, 96, 368, 96, 368, 96};
            for (k = 0; k < 8; k++) if (boss_pat_t == tt[k]) spawn349(tid[k], tx[k], ty[k], 10, 1, 0);
            boss_pat_t++;
            if (boss_pat_t >= 96) { boss_pat = 0; boss_pat_t = 0; }
        }
        c = 700; if (anim8 >= 4) c = 701;           /* label_443 */
        if (boss_pat == 1 || boss_pat == 4) c = 702;
        es_set(n, x, y, c); es_type(n, 32);
        return;
    case 501:                                       /* label_447 */
    {
        s16 st = en_state[i];
        bool even = (anim8 & 1) == 0;
        if (off346(n, i, x, y)) return;
        if (st == 1)                                /* label_448 */
        {
            if (anim8 == 0 || anim8 == 4) x -= 16;
            if (x <= 448) en_state[i]++;
        }
        else if (st == 2 || st == 8)                /* label_452 */
        {
            en_param[i]++;
            if (en_param[i] >= 8) { en_state[i]++; en_param[i] = 0; }
        }
        else if (st == 3 || st == 5 || st == 4 || st == 6)   /* label_449 / label_450 */
        {
            bool up = (st == 3 || st == 5);
            if (even) y += up ? -16 : 16;
            if (en_param[i] == 0)
            {
                spawn349(21, x - 24, y - 16, 0, 1, 0);
                spawn349(21, x - 24, y + 88, 0, 1, 0);
                se(15);
            }
            en_param[i]++;
            if (en_param[i] > 7) en_param[i] = 0;
            if (up && y <= 112) en_state[i]++;
            if (!up && y >= 272) en_state[i]++;
        }
        else if (st == 7)                           /* label_451 */
        {
            if (even) y -= 16;
            if (y <= 192) { en_state[i]++; en_param[i] = 0; }
        }
        else if (st == 9)                           /* label_453 */
        {
            if (even) x += 16;
        }
        es_set(n, x, y, 703); es_type(n, 32);      /* label_454 */
        return;
    }
    case 502:                                       /* label_455/456 */
        if (off346(n, i, x, y)) return;
        if ((anim8 & 1) == 0) x -= 16;
        if (!(x >= 512 || x <= 64) && en_param[i] == 4)
        {
            spawn349(16, x + 24, y + 72, 100, 1, 0);
            se(3);
        }
        en_param[i]++;
        if (en_param[i] >= 12) en_param[i] = 0;
        es_set(n, x, y, 703); es_type(n, 32);
        return;
    case 503:                                       /* label_457/458 */
        if (off348(n, i, x, y)) return;
        if ((anim8 & 1) == 0) x += 16;
        if (!(x >= 512 || x <= 64) && en_param[i] == 8)
        {
            spawn349(16, x + 24, y - 8, 100, 1, 1);
            se(3);
        }
        en_param[i]++;
        if (en_param[i] >= 12) en_param[i] = 0;
        es_set(n, x, y, 703); es_type(n, 32);
        return;
    case 504:                                       /* label_459 */
        if (off346(n, i, x, y)) return;
        k = en_param[i];
        if (k <= 16 && (anim8 & 1) == 0) x -= 16;
        if (k >= 62 && k <= 65) y -= 16;
        if (k >= 98 && k <= 104) y += 16;
        if (k >= 134 && k <= 140) y -= 16;
        if (k >= 170 && k <= 173) y += 16;
        if (k >= 242 && k <= 245) y += 16;
        if (k >= 278 && k <= 281) y -= 16;
        if (k >= 344 && k <= 346) x += 16;
        if (k >= 352) x -= 16;
        es_set(n, x, y, 703); es_type(n, 32);
        en_param[i]++;
        if (en_param[i] <= 32 || en_param[i] >= 316) return;
        en_state[i]++;
        if (en_state[i] > 32) en_state[i] = 1;
        if (en_state[i] == 2 || en_state[i] == 18)
        {
            spawn349(23, x, y + 4, 0, 1, 0);
            spawn349(23, x, y + 60, 0, 1, 1);
            se(15);
        }
        return;
    case 505:                                       /* label_460/461 */
        if (off348(n, i, x, y)) return;
        if (anim8 == 0 || anim8 == 4) x += 16;
        if (!(x >= 464 || x <= 72) && en_param[i] == 8)
        {
            s16 yy = y, pp = 0;
            if (en_state[i] == 1) { yy = y + 4; pp = 0; }
            if (en_state[i] == 2) { yy = y + 60; pp = 1; }
            spawn349(24, x, yy, 100, 1, pp);
            se(15);
            en_state[i] = (en_state[i] == 1) ? 2 : 1;
        }
        en_param[i]++;
        if (en_param[i] >= 12) en_param[i] = 0;
        es_set(n, x, y, 703); es_type(n, 32);
        return;
    case 506:                                       /* label_462..469 */
        boss_timer--;
        if (boss_timer <= 0) { en_state[i] = 1000; se(6); return; }
        if (boss_pat == 0)                          /* label_463 */
        {
            x -= 16;
            if (x <= 448) boss_pat = 1;
        }
        else if (boss_pat == 1)                     /* label_464 */
        {
            boss_pat_t++;
            if (boss_pat_t >= 14) { boss_pat++; boss_pat_t = 0; }
        }
        else if (boss_pat == 2)                     /* label_465 */
        {
            if (boss_pat_t == 0 || boss_pat_t == 8 || boss_pat_t == 16 || boss_pat_t == 24)
                spawn349(113, x - 32, y + 32, 100, 1, 0);
            boss_pat_t++;
            if (boss_pat_t >= 40) { boss_pat++; boss_pat_t = 0; }
        }
        else if (boss_pat == 3)                     /* label_466/467 */
        {
            s16 yy = -1, pp = 0;
            boss_pat_t++;
            if (boss_pat_t >= 162) { boss_pat = 1; boss_pat_t = 0; }
            else
            {
                k = boss_pat_t;
                if (k == 1 || k == 37 || k == 73 || k == 109) { yy = y + 4; pp = 0; }
                if (k == 19 || k == 55 || k == 91 || k == 127) { yy = y + 60; pp = 1; }
                if (yy >= 0) { spawn349(24, x, yy, 100, 1, pp); se(15); }
            }
        }
        if (boss_pat > 2 && (anim8 & 1) == 0)       /* label_468 */
        {
            if (en_state[i] == 1)
            {
                y += 16;
                if (y >= 224) en_state[i] = 2;
            }
            else if (en_state[i] == 2)
            {
                y -= 16;
                if (y <= 160) en_state[i] = 1;
            }
        }
        es_set(n, x, y, 704); es_type(n, 32);      /* label_469 */
        return;
