# FASE 5 — AREA-5 "YieNCA" (イェンカ, *Yienca*)

![mapa completo anotado](img/fase5_mapa_anotado.png)

*Versión limpia `fase5_mapa_x2.png`, colisión `fase5_colision.png`.*

## Ficha
| Dato | Valor |
|---|---|
| Tiles / mapa / script | g_stg5 · stage5_m (424 col) · stage5_e (210 spawns) |
| Fondo | Campo estelar g_chara3 con **scroll vertical** (0,5 nat/t hacia abajo) |
| Música | m_stage5 → m_boss2 |
| Scroll | 8 t/col hacia delante hasta col **390** (mid-jefe, parada) → **scroll inverso** hasta col **279** (jefe). Fade en col 310 durante el retroceso |
| Disparo del jugador | En F5 los tiles de **attr 3** también detienen los disparos |
| Balas enemigas | vel 600 (más rápidas) |
| Volca-Stones | 24 (126), 25 (150), 26 (263), 27 (268), 28 (379), **29 (386, sólo accesible en el retroceso)** |
| Vídeo | 9:15 – 12:08 |

Reseña: "Como la 4, problemática. Mucha dinámica, algunos enemigos sueltan balas vengativas y del techo gotea ácido. En este laberinto de rocas en movimiento es muy fácil quedar aplastado; conviene memorizar el orden de aparición. Por fin nos dejan pelear con el viejo amigo, que pasa de fase inmortal a mortal a mitad de fase: muy peligroso en ambas formas. El jefe pre-final: hay que atacar al fantasma; la cabeza dispara proyectiles apuntados por boca y frente. No es peligroso."

## Recorrido ilustrado por secciones

Cada sección: recorte del **mapa anotado** (tiles reales del juego ×2; iconos = sprite y nº de ID de cada enemigo en su punto exacto de aparición calculado desde el script; recuadro verde **VS** = disparador de Volca-Stone; líneas rojas = eventos de scroll/jefe) + fotograma del vídeo de referencia en el mismo punto.

### A · Llegada y acido (cols 0–110)

Cavernas de roca multicolor sobre fondo estrellado que **cae verticalmente** (Plane B). **Emisores de ácido** invisibles ID66 dejan caer gotas ID67 del techo. **Columnas oculares** ID209 (16 impactos) y **orbes circulantes** ID68 que al morir disparan una **bala vengativa**. Vuelven las avispas en arco (ahora disparan: fase ≥5).

![A_llegada_y_acido](img/mapa_A_llegada_y_acido.png)
![A_llegada_y_acido](img/video_A_llegada_y_acido_9_22.png)
![A_llegada_y_acido](img/video_A_llegada_y_acido_9_30.png)

### B · Celdas de acido (cols 105–165)

Rejilla de 12 celdas de roca flotantes (cols 108-150) con **rocas rodantes** ID210 invulnerables que se desplazan de 16 en 16 por los pasillos: "en este laberinto de rocas en movimiento es muy fácil quedar aplastado". Volca-Stones 24 y 25.

![B_celdas_de_acido](img/mapa_B_celdas_de_acido.png)
![B_celdas_de_acido](img/video_B_celdas_de_acido_9_45.png)

### C · Centinela f5 (cols 160–260)

Col 161 CAUTION ←, col 165 **Centinela Ocular #4** (ID253) entra por la izquierda: láseres cortos ID71 y proyectiles grandes ID69. Luego **rebotadores destructibles** ID75 y avispas.

![C_centinela_F5](img/mapa_C_centinela_F5.png)
![C_centinela_F5](img/video_C_centinela_F5_10_05.png)

### D · Cara de yienca 1er paso (cols 255–320)

Primer paso junto a la gran **cara de piedra de Yienca** (tiles, cols 280-288, suelo). **Satélites lanzados** ID72 en tandas de 4-6 y **lanzaplacas** ID211.

![D_cara_de_yienca_1er_paso](img/mapa_D_cara_de_yienca_1er_paso.png)
![D_cara_de_yienca_1er_paso](img/video_D_cara_de_yienca_1er_paso_10_22.png)

### E · Laberinto de rocas (cols 310–380)

Las **rocas que encajan** ID126 caen y se convierten en terreno (escriben tiles 124-139) formando un laberinto dinámico; ondulantes ID12 y rocas de ida y vuelta ID212. Volca-Stone 28.

![E_laberinto_de_rocas](img/mapa_E_laberinto_de_rocas.png)
![E_laberinto_de_rocas](img/video_E_laberinto_de_rocas_10_40.png)

### F · Centinela transformacion y midjefe (cols 370–424)

Col 376: el **Centinela Ocular #5** (ID254) entra por la izquierda, se transforma (chr 425→426) y deja sus restos en el mapa; col 390 scroll parado y nace su **forma mortal** (ID512, 120 impactos, 5000 pts, 1770 t): muro de láseres, cargas apuntadas, lanzas, láseres dobles y rocas rodantes. "Muy peligroso en ambas formas."

![F_centinela_transformacion_y_midjefe](img/mapa_F_centinela_transformacion_y_midjefe.png)
![F_centinela_transformacion_y_midjefe](img/video_F_centinela_transformacion_y_midjefe_10_52.png)
![F_centinela_transformacion_y_midjefe](img/video_F_centinela_transformacion_y_midjefe_11_05.png)

### G · Retroceso (cols 279–390)

Tras el mid-jefe el **scroll se invierte** (el mapa retrocede de la col 390 a la 279): los enemigos entran por la izquierda (ondulantes ID12 param 1, **ojos concéntricos** ID214), y la Volca-Stone 29 —oculta a la izquierda antes del mid-jefe— entra en pantalla sólo ahora.

![G_retroceso](img/mapa_G_retroceso.png)
![G_retroceso](img/video_G_retroceso_11_28.png)
![G_retroceso](img/video_G_retroceso_11_35.png)

### H · Jefe espectro (cols 270–300)

Al volver a la col 279 la cara de Yienca queda en el borde izquierdo: **Espectro de Yienca** (ID513) teletransportándose por 8 posiciones mientras la cara dispara por boca y frente. Ver ficha.

![H_jefe_espectro](img/mapa_H_jefe_espectro.png)
![H_jefe_espectro](img/video_H_jefe_espectro_11_52.png)
![H_jefe_espectro](img/video_H_jefe_espectro_12_02.png)


## Eventos programados (`label_589`)
| Momento | Evento |
|---|---|
| col 278 (adelante) | Compuerta de piedra se abre: tiles cols 281-282 / 285-286 fila 11 → 074-077, SE25 |
| col 281 (adelante) | → 084-087 |
| col 390 | `boss_mode=1` (parada) — el Centinela #5 ya está en pantalla |
| muerte mid-jefe 512 | Secuencia `label_546` → a los 126 t: `reverse_scroll=1`, `boss_mode=0` |
| col 310 (retroceso) | Fade de música |
| col ≤279 (retroceso) | JEFE 513 |

## Mid-jefe: CENTINELA OCULAR #4 (ID253) — col 165, desde la izquierda

![ID 253](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_253.png)
Inmortal. 1) SE23, x+16/t hasta 480; 2) 4 t; 3) x−16 en ticks pares (12 t) hasta 448; 4) **168 t**: vaivén vertical 16 px cada 2 t (64..288); cada 16 t (t%16==2) 2 **proyectiles grandes ID69** desde (x−16,y+8) y (x−16,y+88) SE15, y cada 32 t además un **láser corto ID71** desde (x,y+60) SE13; 8) tras 4 t, x+16 cada 2 t hasta 480; 9) 10 t; 10) sale por la izquierda −16/t disparando ID71 (param 1, hacia la derecha) cada 8 t mientras 64<x<320.

## Mid-jefe: CENTINELA OCULAR #5 (ID254) → forma mortal (ID512)

![ID 512](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_512.png)
**ID254** (col 376, desde x=−16): 1) avanza +16 en `anim8` 0/4 hasta 480; mientras 48<x<384, cada 16 t 2 **rayos verticales ID74** (arriba desde (x+40,y+16), abajo desde (x+40,y+68)) SE3. 2) 24 t de **transformación**: t8 SE15, se desplaza (−24,−16) y sprite 425; t16 SE15 sprite 426. 3) SE15 y deja su **cascarón en el mapa** (tiles 173-269, cols 414-421 filas 6-15). 4) desaparece y nace **ID512**.

**ID512 — forma mortal** (chr 427/428, en (496,208)). **HP 1200 (120 impactos), 5000 pts, 1770 t.** Ciclo de patrones 0→1→2→3→4→5→6→0:
| Pat | Duración | Ataque |
|---|---|---|
| 0 y 2 | 64 t | **Muro de láseres**: 12 láseres cortos ID71 (−12 px640/t) en t 8..52 cada 4 desde x≈500, y = 236,136,288,336,184,236,336,136,272,200,320,144 (SE13) |
| 1 | 96 t | **Hexágono de cargas**: en t 0,24,48,72, seis ID76 (crecen 13 t y salen apuntadas a vel 1400) en (504,144)(464,176)(544,176)(504,304)(464,272)(544,272) |
| 3 y 6 | 184 t | t0 lanza ID127 hacia arriba desde (512,176); t84 hacia abajo desde (512,272) (SE2); **cortina de rayos ID77**: desde el techo (y=40) en x 384,96,224,288,480,128,352,192,448,64,256,416,160,320 (t20..72 cada 4, SE4) y desde el suelo (y=416) en x 224,384,128,288,480,352,192,64,448,96,256,416,320,160 (t104..156) |
| 4 | 160 t | Láseres dobles de pantalla ID100 en (64,196)/(64,270) en t 0,40,80,120 + cargas ID76 en t 10,30,50,70,90,110 |
| 5 | 135 t | **Rocas rodantes** ID213 (invulnerables) desde x=0 en y 304,176,112,240 (t 0,20,40,60) que avanzan y dan la vuelta en x=416/400 |

Muerte (`label_546`): explosiones t4-44; **t32**: se vacía su cascarón y se abre el paso (cols 414-421 filas 3-18 → 000 con bordes 800-809) y aparece el **Centinela en llamas** ID255 en (480,176) que suelta 8 explosiones ID73 y se retira a la derecha; **t126 empieza el retroceso**.

## JEFE: ESPECTRO DE YIENCA (ID513)

![ID 513](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_513.png)
La **cara de piedra de Yienca** (tiles, cols 279-288 del suelo) queda en el borde izquierdo al terminar el retroceso. El fantasma (chr 708/709, 710 = semi-materializado) es el blanco. **HP 600 (60 impactos), 10.000 pts, 1160 t.**

**Teletransporte** (ciclo de 72 t, 8 posiciones px640 en orden): (248,192) → (208,112) → (496,288) → (320,272) → (240,160) → (496,112) → (384,224) → (240,304) → repetir.
| t en el ciclo | Estado |
|---|---|
| 0-10 | Invisible, sin colisión |
| 11-32 | Materializándose: chr 710 parpadeando, **sin tipo** (invulnerable) |
| 33-61 | **Visible y vulnerable** (708/709, tipo 32) |
| 62-71 | Desvaneciéndose (710) |

**La cara dispara** (desde que `boss_timer` ≤ 1140, es decir, tras 20 t): desde la **boca** (128,298) ID80 lento (chr 448, vel 500) en t 0,8,16,24 del ciclo; desde la **frente** (128,192) ID80 rápido (chr 450, vel 800) en t 40 y 48. SE15.

Muerte (`label_552`): para música; t3 SE6; explosiones alrededor de la cara t20-80; **t68 la cara se agrieta** (tiles 140-169 en cols 279-288); t69 aparece el **ojo de piedra** ID514 en (120,176) que late (711-714) con SE27; **t250 fin de fase**.

## Enemigos de esta fase (fichas visuales)

Nº de apariciones en el script de la fase. Comportamiento completo en `01_GLOBAL/10_catalogo_enemigos.md`.

**ID 5 · Avispa en arco antihorario** — ×6 — `label_136`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_005.png)

**ID 6 · Avispa en arco horario** — ×6 — `label_137`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_006.png)

**ID 7 · Avispa en arco antihorario (variante)** — ×8 — `label_136`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_007.png)

**ID 8 · Avispa en arco horario (variante)** — ×8 — `label_137`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_008.png)

**ID 12 · Tótem de calaveras ondulante** — ×20 — `label_141`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_012.png)

**ID 66 · Emisor de ácido (invisible)** — ×21 — `label_227`  

**ID 68 · Orbe circulante vengativo** — ×24 — `label_230`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_068.png)

**ID 72 · Satélite lanzado** — ×38 — `label_234`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_072.png)

**ID 75 · Rebotador destructible** — ×10 — `label_238`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_075.png)

**ID 99 · Disparador de Volca-Stone (oculto)** — ×6 — `label_344`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_099.png)

**ID 126 · Roca que encaja** — ×22 — `label_303`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_126.png)

**ID 209 · Columna ocular oscilante** — ×4 — `label_327`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_209.png)

**ID 210 · Roca rodante** — ×18 — `label_328`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_210.png)

**ID 211 · Lanzaplacas** — ×4 — `label_330`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_211.png)

**ID 212 · Roca de ida y vuelta (izquierda)** — ×3 — `label_331`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_212.png)

**ID 213 · Roca de ida y vuelta (derecha)** — ×2 — `label_333`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_213.png)

**ID 214 · Ojo concéntrico (torreta sección inversa)** — ×4 — `label_335`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_214.png)

**ID 253 · Centinela Ocular – encuentro 1 F5** — ×1 — `label_403`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_253.png)

**ID 254 · Centinela Ocular – encuentro 2 F5 (transformación)** — ×1 — `label_414`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_254.png)

**ID 300 · Cartel CAUTION** — ×2 — `label_339`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_300.png)

**ID 301 · Flecha de aviso** — ×2 — `label_340`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_301.png)

### Generados por código (hijos, proyectiles, jefes y eventos)

**ID 65 · Bala diagonal de la columna** — `label_226`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_065.png)

**ID 67 · Gota de ácido** — `label_228`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_067.png)

**ID 69 · Proyectil grande apuntado** — `label_231`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_069.png)

**ID 71 · Láser corto horizontal** — `label_233`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_071.png)

**ID 73 · Explosión decorativa** — `label_235`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_073.png)

**ID 74 · Rayo vertical del mid-jefe F5** — `label_237`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_074.png)

**ID 76 · Carga apuntada** — `label_239`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_076.png)

**ID 77 · Rayo vertical** — `label_240`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_077.png)

**ID 78 · Bala del torreta inversa** — `label_241`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_078.png)

**ID 80 · Bala apuntada lenta/rápida** — `label_243`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_080.png)

**ID 127 · Lanza vertical larga** — `label_304`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_127.png)

**ID 255 · Centinela en llamas (tras mid-jefe F5)** — `label_423`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_255.png)

**ID 512 · Mid-jefe F5 – Centinela Ocular (forma mortal)** — `label_539`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_512.png)

**ID 513 · JEFE F5 – Espectro de Yienca** — `label_548`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_513.png)

**ID 514 · Ojo de la cara de piedra** — `label_556`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_514.png)

**ID 199 · Volca-Stone (recogible)** — `label_345`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_199.png)


## Oleadas
[`fase5_oleadas.md`](fase5_oleadas.md) · [`fase5_oleadas.csv`](fase5_oleadas.csv). Tras la línea `PAUSA_MIDBOSS_Y_REVERSA` la columna de scroll **disminuye** (retroceso); los ticks no incluyen la duración del mid-jefe.
