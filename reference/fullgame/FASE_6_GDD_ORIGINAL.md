# FASE 6 (FINAL) — "FINAL-AREA UNKNOWN DEPTH" (未知なる深域, *Profundidad desconocida*)

![tarjeta](img/tarjeta_area_final.png)

## Ficha
| Dato | Valor |
|---|---|
| Tiles / mapa / script | g_stg5 · stage6_m (34 col, arena **vacía**) · atributos de F5 · stage6_e (sólo esperas y `-2`) |
| Fondo | Campo estelar g_chara3 **cayendo a 4 px nat/t** (8 px640/t) — descenso al abismo |
| Música | **m_boss3** (canal 101) → **m_stage1** como tema del duelo final (canal 110) |
| Scroll de mapa | Ninguno. `s6_timer` cuenta ticks cuando `boss_mode==0` |
| Vídeo | 12:10 – 13:25 |

Reseña: "El final. Una esfera enorme en el centro y muchas balas. Todos los ataques salvo uno están estrictamente fijados. No hay que alargar el combate: tras cada ciclo el jefe genera un proyectil adicional que rebota por la pantalla. Al final nos dejan volver a ver al viejo amigo y rematarlo. Es completamente inofensivo y suelta enemigos-proyectil destructibles como en el primer encuentro: permite ganar algo de puntos."

## Recorrido ilustrado por secciones

Cada sección: recorte del **mapa anotado** (tiles reales del juego ×2; iconos = sprite y nº de ID de cada enemigo en su punto exacto de aparición calculado desde el script; recuadro verde **VS** = disparador de Volca-Stone; líneas rojas = eventos de scroll/jefe) + fotograma del vídeo de referencia en el mismo punto.

### A · Esfera del abismo (cols 0–34)

Arena vacía ("FINAL-AREA UNKNOWN DEPTH") con el campo estelar cayendo a 4 px nat/t. La **Esfera del abismo** (ID515, 170 impactos, 2045 t) se sitúa en el centro: espiral doble, anillos, emisores cruzados, estrellas que frenan y apuntan y, cada ciclo, una **bola rebotadora** más (máx. 3).

![A_esfera_del_abismo](img/video_A_esfera_del_abismo_12_17.png)
![A_esfera_del_abismo](img/video_A_esfera_del_abismo_12_25.png)
![A_esfera_del_abismo](img/video_A_esfera_del_abismo_12_35.png)
![A_esfera_del_abismo](img/video_A_esfera_del_abismo_12_45.png)

### B · Duelo final centinela (cols 0–34)

Tras la esfera, CAUTION y el **Centinela Ocular** vuelve por última vez (ID517, mortal, 130 impactos) con la música de la Fase 1: "nos dejan rematarlo; casi inofensivo y suelta enemigos-proyectil como en el primer encuentro". Muere en un colapso final (ID518) → MISSION COMPLETE.

![B_duelo_final_centinela](img/video_B_duelo_final_centinela_12_55.png)
![B_duelo_final_centinela](img/video_B_duelo_final_centinela_13_05.png)
![B_duelo_final_centinela](img/video_B_duelo_final_centinela_13_18.png)


## Secuencia de la fase (`label_058`, `label_590`)
| Momento | Evento |
|---|---|
| tick 1 | `boss_count==0` → aparece **ID515** en (456,216) px640, `boss_mode=1` |
| muerte de 515 | `label_566`: t0 para m_boss3, t3 y t9 SE6, **t8 esfera moribunda ID516**, t178 `boss_mode=0`, `boss_count=1` |
| `s6_timer`=180 | CAUTION (ID300) + flecha → (ID301 param 651) en (504,256)/(504,208) |
| `s6_timer`=240 | Empieza **m_stage1** (reprise del tema de la fase 1) y aparece **ID517** en (576,176) |
| muerte de 517 | `label_580`: t8 **colapso ID518** en (517.x+16, 517.y+32); explosiones t20-80; al acabar el colapso `s6_timer=1000` → estrellas (21) + **"MISSION COMPLETE"** parpadeando (20 t ciclo, 10 visibles); **t300 fin → ENDING** |

## JEFE FINAL: ESFERA DEL ABISMO (ID515)

![ID 515](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_515.png)
Sprite chr 711-714 (esfera verde con borde pulsante, ciclo de 44 t: 711 base, 712/713/714 en t 24-43). **HP 1700 (170 impactos), 15.000 pts, 2045 t (61 s).**

| Pat | Duración | Ataque (origen = centro (x+8, y+8)) |
|---|---|---|
| 0 | variable | Avanza −16 px cada 8 t hasta x≤296 (centro de la arena: nat 116,76) |
| 1 | 132 t | **Doble espiral**: cada 4 t (anim8 0/4) dos ID81 (vel 1000) con dirs `t mod 64` y `(t+32) mod 64`, t+=2 por disparo (33 disparos dobles) SE21 |
| 2 | 68 t | **Anillos de 8** ID87 (vel 800): t16 y t48 dirs 4,12,…,60; t32 y t64 dirs 0,8,…,56 |
| 3 | 176 t | **Emisores cruzados** ID82: t16 y t96 dos que viajan arriba/abajo; t56 y t136 dos izquierda/derecha. Cada emisor suelta cada 14 t dos rayos ID83 perpendiculares a su marcha |
| 4 | 104 t | **Estrellas que frenan y apuntan** ID84: t8 dir 22, t16 dir 0, t24 dir 44, t32 dir 10, t48 dir 34, t56 dir 56, t64 dir 26, t72 dir 8; frenan y a los 24 t se lanzan al jugador (el único ataque "no fijo") |
| 5 | 1 t | Si hay < 3, añade una **bola rebotadora ID85** (dir inicial = nº de bola) — máximo 3 |
| 6 | 16 t | Pausa → vuelve a Pat 1 (ciclo ≈497 t) |

**Esfera moribunda (ID516)** en (296,216): durante 160 t; en t 40..100 explosiones ID73 alrededor; sprite 716 (destello blanco) desde t130; **t138 estalla en 16 fragmentos** ID86 (dirs 2,6,…,62), SE6, y activa `stones_glow` (las Volca-Stones del HUD brillan).

## DUELO FINAL: CENTINELA OCULAR (ID517)

![ID 517](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_517.png)
Sprite chr 429 (el Centinela dañado). **HP 1300 (130 impactos), 15.000 pts, 1134 t.**
| Pat | Comportamiento |
|---|---|
| 0 | SE23, entra −16/t hasta x≤272 |
| 1 | 6 t |
| 2 | x+16 en ticks pares hasta 416 |
| 3 (34 t) | **Láseres del casco** ID128 desde (318, y+24) y (318, y+90): aviso 21 t, dañinos t22-25 (cubren sólo de x=318 a la derecha) |
| 4 (132 t) | Vaivén vertical 16 px (anim16 0/4/12) entre y=96 y 256; **popcorn ID3** desde (x+32,y+56) dir 45+rnd(7) cuando t%28 ∈ {2,8,11,20} (SE4) → vuelve a Pat 3 |
| Siempre | Explosiones de daño decorativas ID88 cada 6 t en 8 puntos del casco |

> Fidelidad: el código SÍ tiene láseres dañinos y contacto letal; la reseña lo describe como "inofensivo" porque los láseres sólo cubren la mitad derecha y el popcorn es destructible.

**Colapso final (ID518)**: sprite 720/724 alterno (ojo rojo), en t112-159 pasa por 721→722→723 y desaparece (1000); a los 184 t `s6_timer=1000`.

## Enemigos de esta fase (fichas visuales)

Nº de apariciones en el script de la fase. Comportamiento completo en `01_GLOBAL/10_catalogo_enemigos.md`.

### Generados por código (hijos, proyectiles, jefes y eventos)

**ID 3 · Popcorn del Centinela** — `label_134`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_003.png)

**ID 81 · Bala espiral** — `label_244`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_081.png)

**ID 82 · Emisor cruzado** — `label_245`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_082.png)

**ID 83 · Rayo del emisor** — `label_246`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_083.png)

**ID 84 · Estrella que frena y apunta** — `label_247`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_084.png)

**ID 85 · Bola rebotadora del núcleo** — `label_250`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_085.png)

**ID 86 · Metralla de muerte del núcleo** — `label_256`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_086.png)

**ID 87 · Anillo de balas** — `label_258`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_087.png)

**ID 88 · Explosión de daño continuo** — `label_259`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_088.png)

**ID 128 · Láser del casco (F6)** — `label_305`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_128.png)

**ID 300 · Cartel CAUTION** — `label_339`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_300.png)

**ID 301 · Flecha de aviso** — `label_340`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_301.png)

**ID 515 · JEFE FINAL – Esfera del abismo** — `label_557`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_515.png)

**ID 516 · Esfera moribunda** — `label_569`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_516.png)

**ID 517 · EPÍLOGO F6 – Centinela Ocular (duelo final)** — `label_570`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_517.png)

**ID 518 · Ojo del abismo (colapso final)** — `label_583`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_518.png)

