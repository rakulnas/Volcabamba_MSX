# FASE 3 — AREA-3 "GUSCOL" (獣都グスコル, *Guscol, la ciudad-bestia*)

![mapa completo anotado](img/fase3_mapa_anotado.png)

*Versión limpia `fase3_mapa_x2.png`, colisión `fase3_colision.png`.*

## Ficha
| Dato | Valor |
|---|---|
| Tiles / mapa / script | g_stg3 · stage3_m (514 col) · stage3_e (145 spawns) · **s_hebi.dat** (trayectoria de la serpiente, 1314 puntos) |
| Música | m_stage3 → m_boss |
| Scroll | 8 t/col. Fade col **464**, jefe col **481** (tick 3847) |
| Tiles animados | IDs ≥ 830: +0/+3/+6/+3 cada 4 t (`anim16`) — orla/lluvia |
| Enemigos disparan | Sí (fase 2-4: ondulantes, máscaras) |
| Volca-Stones | 12 (col 70), 13 (129), 14 (238), 15 (289,5), 16 (333), 17 (354) |
| Vídeo | 4:08 – 6:17 |

Reseña: "La primera mitad se pasa abrazado al mid-jefe serpiente. Vuela por una ruta estricta… Las cabezas sólo son vulnerables con la boca abierta, como los moai de Gradius. A mitad de fase, al primer mid-jefe lo mata el segundo mid-jefe de la fase 1: muy peligroso, sobre todo sus láseres. La segunda mitad en ruinas: los cubos verdes se convierten en enemigos, atacan una sola vez. Con este jefe cuidado: no hay que disparar a la boca, sino a los brotes de arriba y abajo; se abren en un orden determinado soltando proyectiles destructibles, mientras la cabeza suelta 2 proyectiles apuntados que rebotan en la pared y vuelven a apuntar."

> Nota de fidelidad: en el código, las máscaras ID114 son siempre tipo 32 (vulnerables); la "boca abierta" es sólo su animación (chr 236/237 alternos cada 4 t). Si se quiere el comportamiento "sólo con la boca abierta" de la reseña, sería una mejora, no el original.

## Recorrido ilustrado por secciones

Cada sección: recorte del **mapa anotado** (tiles reales del juego ×2; iconos = sprite y nº de ID de cada enemigo en su punto exacto de aparición calculado desde el script; recuadro verde **VS** = disparador de Volca-Stone; líneas rojas = eventos de scroll/jefe) + fotograma del vídeo de referencia en el mismo punto.

### A · Mascaras y plantas (cols 0–70)

Jungla de la ciudad-bestia: lluvia y vegetación roja/verde. **Máscaras moai** ID114 en techo y suelo (boca que se abre/cierra, disparo apuntado cada 136 t) y **plantas** ID203/204 que sólo se dañan con **disparo vertical** (los horizontales se anulan) y escupen semillas parabólicas ID28/29.

![A_mascaras_y_plantas](img/mapa_A_mascaras_y_plantas.png)
![A_mascaras_y_plantas](img/video_A_mascaras_y_plantas_4_12.png)

### B · Serpiente (cols 60–160)

Desde el primer tick, la **serpiente** (cabeza ID26 + 6 segmentos ID27, invulnerable, +5 pts/impacto) recorre la trayectoria grabada `s_hebi.dat` (1314 puntos, 1 por tick) enroscándose por la pantalla: es la primera mitad de la fase "abrazado al mid-jefe serpiente". Moai en el techo (tiles). Volca-Stones 12 y 13.

![B_serpiente](img/mapa_B_serpiente.png)
![B_serpiente](img/video_B_serpiente_4_25.png)
![B_serpiente](img/video_B_serpiente_4_40.png)
![B_serpiente](img/video_B_serpiente_4_47.png)

### C · Centinela mata serpiente (cols 150–230)

Col 154 CAUTION + flecha ←, col 158 el **Centinela Ocular** (ID252) entra **por la izquierda** a 16 px640/t y al pasar x=176 mata a la serpiente (col 159: los segmentos salen despedidos). Después láseres ID115, cápsulas divisoras ID32 (se parten en 3 al llegar al borde derecho) y balas atraviesa-muros ID252. La reseña: "muy peligroso, sobre todo los láseres".

![C_centinela_mata_serpiente](img/mapa_C_centinela_mata_serpiente.png)
![C_centinela_mata_serpiente](img/video_C_centinela_mata_serpiente_5_04.png)

### D · Pasillo rojo peces (cols 230–300)

Pasillo con techo y suelo de coral rojo (cols 255-290). 8 **peces esqueleto** ID34 (6 impactos, 300 pts) que **aceleran cuanto más daño reciben** (de −2 a −12 px640/t); sólo disparan si están intactos. Volca-Stone 15.

![D_pasillo_rojo_peces](img/mapa_D_pasillo_rojo_peces.png)
![D_pasillo_rojo_peces](img/video_D_pasillo_rojo_peces_5_13.png)

### E · Cubos verdes (cols 265–350)

Ruinas de cubos verdes. Los **cubos transformables** ID116 aparecen como bloque, se abren, **escriben terreno** (3×3 tiles) y se convierten en ojo vulnerable que dispara UNA bala que atraviesa muros. "Muchos, pero sólo atacan una vez." **Esporas buscadoras** ID25 re-apuntan cada 18 t. Volca-Stones 16 y 17.

![E_cubos_verdes](img/mapa_E_cubos_verdes.png)
![E_cubos_verdes](img/video_E_cubos_verdes_5_21.png)

### F · Bloques moviles patrulleros (cols 350–470)

**Bloques móviles** ID117 invulnerables (96×48 px640) que suben/bajan 32 px640 por columna aplastando pasillos, y **globos oculares patrulleros** ID118 en tríos (izquierda/derecha) que lanzan balas atraviesa-muros ID31.

![F_bloques_moviles_patrulleros](img/mapa_F_bloques_moviles_patrulleros.png)
![F_bloques_moviles_patrulleros](img/video_F_bloques_moviles_patrulleros_5_45.png)

### G · Jefe rostro guscol (cols 470–514)

El **Rostro de Guscol**: una cara gigante de tiles (cols 505-512) con boca que se abre y 6 **protuberancias** (nidos) arriba/abajo que se abren por turnos: son el punto débil. Ver ficha.

![G_jefe_rostro_guscol](img/mapa_G_jefe_rostro_guscol.png)
![G_jefe_rostro_guscol](img/video_G_jefe_rostro_guscol_6_05.png)
![G_jefe_rostro_guscol](img/video_G_jefe_rostro_guscol_6_10.png)


## Evento: LA SERPIENTE (ID26 cabeza + 6× ID27)

![ID 26](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_026.png)
![ID 27](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_027.png)
Creada en el tick 1 de la fase (`label_616`, sub 1) en slots fijos 120-126:
- Cabeza en índice de trayectoria 37; segmentos en 30, 24, 18, 12, 6, 0 (desfase de 6 ticks = la cola sigue a la cabeza).
- Cada tick avanza 1 punto: `x = hebi_x*2+64`, `y = hebi_y*2+48` (px640; los datos de `s_hebi.dat` ya están en **coordenadas nativas** de pantalla — ¡se pueden usar tal cual en MD restando 0 en x/−8 en y!). La cabeza se dibuja con offset (−8,−8).
- Invulnerable (HP 9999, 100 pts no se cobran). Contacto letal.
- Col 159 (`scroll_ofs ≥ 14151`): muere: cabeza sprite 240 sale dir 9 vel 2000; segmentos sprite 241 salen en dirs 12/14/16/18/20/23 vel 2000-2200 (dispersión en abanico), flag de cuenta atrás 10.

## Mid-jefe: CENTINELA OCULAR (ID252) — col 158, desde la izquierda (−32,176)

![ID 252](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_252.png)
| Estado | Comportamiento |
|---|---|
| 1 | x+16/t hasta x≥480 (SE6 al pasar por x=176: momento en que mata a la serpiente) |
| 2 | 7 t quieto |
| 3 | x−16 en ticks pares hasta 448 |
| 4 y 6 (109 t) | **Láseres ID115** dobles (aviso 13 t) desde (64, y+24) y (64, y+90) en t 0, 30, 60, 90. En los tramos t 19-29, 49-59, 79-89 y ≥109 (fuera de los láseres) se mueve 16 px cada 2 t verticalmente entre y=64 y 288 |
| 5 y 7 (150 t) | Vaivén vertical continuo (16 px cada 2 t, 64..288); para t<120, cada 10 t (t%10==8) **cápsula divisora ID32** desde (x+56, y+56), SE15 |
| 4-7 (todo) | Cada 33 t **bala atraviesa-muros** (chr 252, `label_355`) desde (x+32, y+56), apuntada vel 600 |
| 8 | 4 t quieto, luego x+16 en ticks pares hasta 480 |
| 9 | 10 t |
| 10 | Sale por la izquierda −16/t |

## JEFE: ROSTRO DE GUSCOL (ID507)

![ID 507](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_507.png)
El rostro es **mapa**: cara rosa en cols 505-512 y 6 **nidos/protuberancias** (4×2 tiles) en el techo (cols 482-485, 490-493, 498-501, filas 2-3) y el suelo (cols 486-489, 494-497, 502-505, filas 18-19). El sprite 507 (chr 705, 32×16 px640, hitbox 90%, invisible) es sólo la **caja de impacto** que se coloca sobre el nido abierto.

| Dato | Valor |
|---|---|
| HP | 400 (**40 impactos**) |
| Puntos | 10.000 |
| Temporizador | **1308 t** |

**Nidos** (`boss_pat` 1→6, cada uno 73 t, luego vuelve a 1):
| Pat | Nido | Caja de impacto (px640) | Proyectiles |
|---|---|---|---|
| 1 | techo col 490 | (224,112) | ID29 (caen en arco) |
| 2 | suelo col 502 | (416,352) | ID28 (suben en arco) |
| 3 | suelo col 486 | (160,352) | ID28 |
| 4 | techo col 498 | (352,112) | ID29 |
| 5 | techo col 482 | (96,112) | ID29 |
| 6 | suelo col 494 | (288,352) | ID28 |

Dentro de cada Pat: t0-4 nido semiabierto (tiles 534/544 o 530/540), **t5-64 abierto** (554/564 o 550/560) — caja activa (tipo 32) — escupe semillas en t 10, 18, 26, 34 (param rnd 5 → deriva lateral, SE4), t65-69 cerrándose, t70-72 cerrado (401/411 o 341/351, caja sin tipo). Pat 0 inicial: 8 t de espera.

**Boca** (`label_617`, en paralelo, según `boss_timer % 120`): ==90 abre la boca (tiles 602-689 en cols 505-512), ==40 la cierra (692-779); en 80 y 60 dispara el **proyectil rebotador ID35** desde (484,268): crece 10 t, va apuntado a 400; al tocar el borde de la caja 48..560×48..400 se re-apunta al jugador a vel 1000 (rebote), SE5.

Muerte (`label_490`): para música; nidos a tiles muertos (774-797 / 770-793); explosiones ID302 en 12 puntos t20-64; **t128 fin de fase**.

## Enemigos de esta fase (fichas visuales)

Nº de apariciones en el script de la fase. Comportamiento completo en `01_GLOBAL/10_catalogo_enemigos.md`.

**ID 12 · Tótem de calaveras ondulante** — ×6 — `label_141`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_012.png)

**ID 25 · Espora buscadora** — ×22 — `label_164`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_025.png)

**ID 34 · Pez esqueleto acelerador** — ×8 — `label_176`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_034.png)

**ID 99 · Disparador de Volca-Stone (oculto)** — ×6 — `label_344`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_099.png)

**ID 114 · Máscara moai** — ×21 — `label_285`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_114.png)

**ID 116 · Cubo verde transformable** — ×21 — `label_291`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_116.png)

**ID 117 · Bloque móvil** — ×28 — `label_292`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_117.png)

**ID 118 · Globo ocular patrullero** — ×24 — `label_293`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_118.png)

**ID 203 · Planta superior** — ×3 — `label_313`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_203.png)

**ID 204 · Planta inferior** — ×3 — `label_317`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_204.png)

**ID 252 · Centinela Ocular – encuentro F3** — ×1 — `label_389`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_252.png)

**ID 300 · Cartel CAUTION** — ×1 — `label_339`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_300.png)

**ID 301 · Flecha de aviso** — ×1 — `label_340`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_301.png)

### Generados por código (hijos, proyectiles, jefes y eventos)

**ID 26 · Cabeza de la serpiente** — `label_166`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_026.png)

**ID 27 · Cuerpo de la serpiente** — `label_167`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_027.png)

**ID 28 · Burbuja/semilla parabólica (arriba)** — `label_168`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_028.png)

**ID 29 · Burbuja/semilla parabólica (abajo)** — `label_170`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_029.png)

**ID 31 · Bala atraviesa-muros** — `label_173`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_031.png)

**ID 32 · Cápsula divisora** — `label_174`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_032.png)

**ID 33 · Fragmento de cápsula** — `label_175`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_033.png)

**ID 35 · Proyectil rebotador de la cara (F3)** — `label_178`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_035.png)

**ID 115 · Láser horizontal corto** — `label_286`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_115.png)

**ID 507 · JEFE F3 – Rostro de Guscol (núcleo)** — `label_472`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_507.png)

**ID 199 · Volca-Stone (recogible)** — `label_345`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_199.png)


## Oleadas
[`fase3_oleadas.md`](fase3_oleadas.md) · [`fase3_oleadas.csv`](fase3_oleadas.csv)
