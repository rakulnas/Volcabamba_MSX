# ENDING (`label_678`–`label_694`)

Tras el colapso del Centinela en la F6 y "MISSION COMPLETE" (![](img/video_13_18.png)), `stage=7` → ending.

## 1. Tally de bonus
| Reconstrucción | Vídeo (bonus transfiriéndose) |
|---|---|
| ![](img/ending_bonus_tally_640.png) | ![](img/video_13_26.png) ![](img/video_13_30.png) |

- Negro 512 ms; se carga m_end (aún no suena).
- `ALL CLEAR BONUS` = **100.000**; `NO MISS BONUS` = **150.000** si `deaths==0` (en toda la partida, incluidos continues); `VOLCA STONE PERFECT BONUS` = **200.000** si las 30 piedras están marcadas.
- Textos g_msx (160,360) 240×16 en (200,112), (0,376) 208×16 en (216,208), (0,392) 400×16 en (120,304); cifras de 6 dígitos (tope 999.999) en y=96/192/288 +48, x=208+64.
- 48 t de pausa, luego se transfiere **1000 puntos por tick** al marcador, primero ALL CLEAR, luego NO MISS, luego STONES (SE5 cada 2 t). El HUD está visible, así que los **extends siguen contando**. Tras vaciar todo, 96 t más.
- Partículas chr 464 desde el centro cada 4 t.
- Máximo teórico del tally: 450.000 → 450 t de transferencia.

## 2. Cinemática final (200 t a 40 ms/t = 8 s)
![](img/ending_cuadro_tierra_640.png)

- Cuadro g_chara2 (48,304) 144×136 en (304,144): la **Tierra envuelta por la criatura verde**; en 2 de cada 24 t se cambia a (456,304) (parpadeo/latido).
- 17 estrellas chr 464 en posiciones fijas (t0-1) + SE17.
- Caza (sprite 1): fase 0 avanza +2 px640/t desde (160,264) hasta x=264; fase 1 (16 t) se transforma chr 466→467→468; fase 2 (24 t) SE18, sale disparado hacia la Tierra (chr 469→472, dx 8→2, dy −2) y desaparece; fase 3: pequeñas explosiones chr 620 en (366,216) (380,204) (394,220) (356,232) (386,186) (368,180) = impacto/entrada en la Tierra.

## 3. "NEXT-AREA EARTH…" (96 t a 32 ms)
![](img/ending_next_area_earth_640.png)
Misma animación de persiana que las tarjetas de área, desde g_chara3 (0,384)/(0,400).

## 4. "To Be Continued"
| Reconstrucción | Vídeo |
|---|---|
| ![](img/ending_to_be_continued_640.png) | ![](img/video_13_34.png) |

640 ms de negro, empieza **m_end**. Recuadro gris (160,120)-(480,328) px640, dibujo de la Tierra infestada g_chara2 (192,352) 80×64 en (176,256), rótulo "To Be Continued" g_chara2 (192,320) 256×32 en (192,184), HUD visible y "PUSH SPACE KEY" parpadeando 16/16. Botón → para música, 128 ms, espera a soltar → DEMO. No hay segunda vuelta (la reseña lo lamenta).

MD: añadir entrada de iniciales/hi-score en SRAM sería una mejora opcional (el original no guarda nada).
