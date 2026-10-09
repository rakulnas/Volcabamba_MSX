# FASE 4 — AREA-4 "VOLCABAMBA" (ヴォルカバンバ中枢, *Núcleo de Volcabamba*)

![mapa completo anotado](img/fase4_mapa_anotado.png)

*Versión limpia `fase4_mapa_x2.png`, colisión `fase4_colision.png`.*

## Ficha
| Dato | Valor |
|---|---|
| Tiles / mapa / script | g_stg4 · stage4_m (525 col) · stage4_e (165 spawns) |
| Música | m_stage4 → m_boss |
| Scroll | 8 t/col, **se detiene 3 veces** (arenas de mid-jefe en cols 27, 150, 281). Fade col 464, jefe col **491** |
| Tiles animados | IDs ≥ 850: +10 cuando `anim8≥4` (parpadeo de luces) y durante la muerte del jefe |
| Enemigos disparan | Sí; cañones 103 cada 56 t con sprites de F4 (336-343) |
| Volca-Stones | 18 (col 11,5, arriba del todo al empezar), 19 (200), 20 (225), 21 (319,5), 22 (374,5), 23 (483,5) |
| Vídeo | 6:18 – 9:12 |

Reseña: "Lugar extremadamente peligroso. Tres mid-jefes, y mortales: esta vez hay que pelear de verdad. Muchos pasos estrechos donde te disparan activamente, y un micro-mid-jefe opcional. Pasillo estrecho con enemigos de la fase 1, pero esta vez disparando, y proyectiles apuntados que atraviesan paredes. A mitad de fase se puede matar al barco antes amigo convertido en horror. El jefe recuerda al primero pero más difícil: láser recto rápido por el centro, ataques de área y popcorn arriba-abajo de dos tipos. Cuidado: los jefes tienen temporizador."

## Recorrido ilustrado por secciones

Cada sección: recorte del **mapa anotado** (tiles reales del juego ×2; iconos = sprite y nº de ID de cada enemigo en su punto exacto de aparición calculado desde el script; recuadro verde **VS** = disparador de Volca-Stone; líneas rojas = eventos de scroll/jefe) + fotograma del vídeo de referencia en el mismo punto.

### A · Arena1 pod octogonal (cols 0–62)

Interior de Volcabamba: tuberías rojas y agua azul. 4 **guardianes flotantes** ID43. En col 27 el scroll se para, **se cierra una compuerta detrás** (tiles 002 = attr 2 letal) y aparece el **mid-jefe 1: Pod octogonal** (ID508, 40 impactos, 3000 pts, 770 t) que rebota por la arena disparando parejas ID38 en cada rebote. Al morir se abre la compuerta delantera (col 58).

![A_arena1_pod_octogonal](img/mapa_A_arena1_pod_octogonal.png)
![A_arena1_pod_octogonal](img/video_A_arena1_pod_octogonal_6_25.png)
![A_arena1_pod_octogonal](img/video_A_arena1_pod_octogonal_6_35.png)

### B · Barredores y naves patrulla (cols 40–150)

Oleadas de **barredores sinusoidales** ID39/51 alternados, **rodillos interceptores** ID40 que llegan por detrás, **caedores/subidores** ID41/42 y **naves patrulla** ID205 (96×64 px640) que van y vienen disparando balas atraviesa-muros. Luego **zigzags** ID47 y boyas-torreta ID36/37.

![B_barredores_y_naves_patrulla](img/mapa_B_barredores_y_naves_patrulla.png)
![B_barredores_y_naves_patrulla](img/video_B_barredores_y_naves_patrulla_6_50.png)
![B_barredores_y_naves_patrulla](img/video_B_barredores_y_naves_patrulla_7_05.png)

### C · Arena2 acorazado (cols 145–185)

Col 150: segunda arena. **Mid-jefe 2: Acorazado rojo** (ID509, 48 impactos) — embestidas horizontales de lado a lado, y fase de vaivén vertical con balas rojas ID44 cada 16 t y **bumeranes** ID45. Al salir, calaveras-cañón ID119 y generadores de escombros ID120.

![C_arena2_acorazado](img/mapa_C_arena2_acorazado.png)
![C_arena2_acorazado](img/video_C_arena2_acorazado_7_15.png)

### D · Restos de la flota (cols 185–280)

Las naves hermanas de la flota aliada aparecen **incrustadas en el mapa** como tiles (cols 200-280): la base de Volcabamba ha absorbido la flota. **Torreta abanico** ID206 (28 impactos, 1500 pts) que dispara abanicos hacia atrás; al destruirla se abre un pasaje (tiles col 262).

![D_restos_de_la_flota](img/mapa_D_restos_de_la_flota.png)
![D_restos_de_la_flota](img/video_D_restos_de_la_flota_7_28.png)
![D_restos_de_la_flota](img/video_D_restos_de_la_flota_7_40.png)

### E · Arena3 nave hermana (cols 278–318)

Col 281: tercera arena. **Mid-jefe 3: la nave hermana infectada** (ID510, 42 impactos) — la reseña: "se puede matar al barco antes amigo convertido en horror". Lluvia de gotas ID55 desde arriba, parejas ID56 y tridentes ID57 mientras se desplaza de lado a lado.

![E_arena3_nave_hermana](img/mapa_E_arena3_nave_hermana.png)
![E_arena3_nave_hermana](img/video_E_arena3_nave_hermana_7_55.png)

### F · Laberinto de bloques (cols 318–470)

Laberinto de bloques de circuito rojo (cols 350-485). **Boyas lanzadoras** ID48/49, **pods de 4 direcciones** ID207 y la mayor concentración de **cañones fijos** ID103 que aquí disparan cada 56 t (sprites 336-343), + **emboscadores** ID54 que entran por detrás. 3 **obstáculos destructibles** ID122 (20 impactos) al final.

![F_laberinto_de_bloques](img/mapa_F_laberinto_de_bloques.png)
![F_laberinto_de_bloques](img/video_F_laberinto_de_bloques_8_15.png)
![F_laberinto_de_bloques](img/video_F_laberinto_de_bloques_8_30.png)
![F_laberinto_de_bloques](img/video_F_laberinto_de_bloques_8_45.png)

### G · Jefe nucleo (cols 470–525)

Cámara del **Núcleo de Volcabamba** (ID511, 130 impactos, 1400 t): paredes que laten, rayos en abanico, peces saltarines, láser central ultrarrápido y lanzas verticales. Ver ficha.

![G_jefe_nucleo](img/mapa_G_jefe_nucleo.png)
![G_jefe_nucleo](img/video_G_jefe_nucleo_8_57.png)
![G_jefe_nucleo](img/video_G_jefe_nucleo_9_05.png)


## Arenas de mid-jefe (`label_621`–`label_632`) — mecánica común
Al llegar el scroll a la col de arena (27 / 150 / 281): `boss_mode=1` (scroll y script parados).
| t (contador de arena) | Acción |
|---|---|
| 16 | Compuerta trasera paso 1 (col N filas 8-13: `002,000,000,000,000,002`), SE24 y **aparece el mid-jefe** |
| 20 | Paso 2 `002,002,000,000,002,002` |
| 24 | Cerrada `002×6` — tile 002 tiene **attr 2 (letal al tocarlo)** |
| (mid-jefe muere) | `boss_count++`, contador a 0 |
| 4 | SE6 |
| 20 | Compuerta delantera (col N+31) `003,003,000,000,003,003` SE24 |
| 24 | `003,000,000,000,000,003` |
| 28 | Abierta `000×6` |
| 40 | `boss_mode=0` → continúa el scroll |
Si se agota el temporizador del mid-jefe, explota igual (TIME OVER) y la arena se abre.

## Mid-jefe 1: POD OCTOGONAL (ID508) — col 27

![ID 508](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_508.png)
Sprite chr 300 (80×80 px640 = 40×40 nat, 95%) en (416,192). **HP 400 (40 impactos), 3000 pts, 770 t.**
- Pat 0 (32 t): aparece parpadeando (300 / invisible cada 2 t).
- Pat 1: rebota en diagonal 16 px cada 2 t dentro de x 80..480, y 96..304 ("salvapantallas DVD"). En cada rebote contra pared SE15 y dispara **2 balas ID38** (chr 274, vel 600) hacia el interior: pared inferior → dirs 40 y 24 desde (x+4,y+72)/(x+44,y+72); superior → 56 y 8 desde y−24; derecha → 40 y 56 desde (x+72, y+4/y+44); izquierda → 24 y 8 desde x−24. Al dar en una esquina invierte ambos ejes sin disparar.

## Mid-jefe 2: ACORAZADO ROJO (ID509) — col 150

![ID 509](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_509.png)
Sprite chr 304 (80×80) en (448,192). **HP 480 (48 impactos), 3000 pts, 798 t.**
- Pat 0 (32 t): aparición parpadeante.
- Pat 1 (68 t): **embestida**: t0-1 x+16; t8 SE25; t8-32 x−16/t (cruza la arena hacia la izquierda); t38-60 x+16/t (vuelve).
- Pat 2 (188 t): sube/baja 16 px cada 2 t entre y=96 y 304; cada 16 t (t≤150) **bala roja ID44** apuntada vel 800 desde (x+32,y+28) SE4; cada 42 t (t%42==16) 2 **bumeranes ID45** desde (x+8,y−8) y (x+8,y+64) SE3. → Pat 1.

## Mid-jefe 3: NAVE HERMANA INFECTADA (ID510) — col 281

![ID 510](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_510.png)
Sprite chr 329 (96×64) en (272,96). **HP 420 (42 impactos), 3000 pts, 778 t.** Es una de las naves de la flota aliada absorbida.
- Pat 0 (32 t): aparición.
- Siempre (pat ≥1): cada 16 t cae una **gota destructible ID55** en x = rnd(15)·32+80, y=32 (vel 600, explota al llegar a y 368).
- Pat 1 (32 t): 6 parejas de **gotas indestructibles ID56** desde (x+20,y+48) y (x+62,y+48) en t 4,8,…,24 (SE4).
- Pat 2 (104 t): se desplaza horizontalmente 16 px/t entre x=80 y 464 (SE15 al girar); cada 24 t (t%24==8) **tridente ID57**: tres balas desde (x+8±16,y+32) dir 58, (x+32±16,y+48) dir 0, (x+56±16,y+32) dir 6 (vel 800, SE3). → Pat 1.

## JEFE: NÚCLEO DE VOLCABAMBA (ID511) — col 491

![ID 511](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_511.png)
Sprite chr 706 (abierto) / 707 (cerrado) en (480,208). Las paredes laten (superposición g_chara2 (0,304) 48×128 en (496,112) y (496,240), fases 0 y 3 de cada 16 t). **HP 1300 (130 impactos), 10.000 pts, 1400 t.**

| Pat | Duración | Comportamiento |
|---|---|---|
| 0 | 70 t | t0-49 cerrado; **t50** se abre la cámara (tiles cols 517-521 filas 9-12 → vacío) SE15; t55 SE15 y sube 8 px |
| — | (pats 1, 2, 4) | Movimiento: cada 8 t (anim8==0) 16 px vertical entre y=128 y 272 |
| 1 | 80 t | **Abanico barredor**: rayo ID59 (vel 1200, SE21) desde (x+24,y+24) cada 4 t (t8..72) con dirs 48,44,40,36,32,36,40,44,48,52,56,60,0,60,56,52,48 (barre de izquierda→arriba→izquierda→abajo→izquierda) |
| 2 | 160 t | **Peces saltarines**: ID61 desde abajo (y=416) en x 416,240,96,336,144,288,384,64 y ID62 desde arriba (y=32) en x 64,288,144,384,240,112,416,320, en t 4,14,24,34,74,84,94,104 (los de t34 y t104 no disparan) |
| 3 | 144 t | Quieto. Dos abanicos ID59: superior desde (x+24,y−8) dirs 48→32→48 cada 8 t (t8..136) e inferior desde (x+24,y+56) dirs 48→0→48 (t12..140). t48: destello ID124 en (x−32,y+8). **t90-112: láser central ultrarrápido** = chorro de ID208 (−32 px640/t) cada tick, SE25 en t90 |
| 4 | 160 t | **Lanzas verticales ID63**: desde arriba en x 272,352,80,400,160,288,432,128 (t0..112 cada 16) y desde abajo en x 432,128,208,320,112,352,64,240 (t8..120) |
| → | | vuelve a Pat 1 (ciclo 544 t) |

Muerte (`label_537`): para música; al morir genera la **carcasa ID123** (micro-explosiones ID58 en 10 puntos durante 96 t); explosiones ID302 t14-58; las tuberías revientan: tiles de techo (fila 0) y suelo (fila 21) cambian a 076/077/066/067 con cascotes ID60 en cols 499, 511, 495, 513, 491, 521, 506 (techo) y 493, 515, 508, 503, 504 (suelo) en t 28-136; **t154 fin de fase**.

## Enemigos de esta fase (fichas visuales)

Nº de apariciones en el script de la fase. Comportamiento completo en `01_GLOBAL/10_catalogo_enemigos.md`.

**ID 36 · Boya torreta (dispara si estás a la izquierda)** — ×2 — `label_182`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_036.png)

**ID 37 · Boya torreta (dispara si estás a la derecha)** — ×2 — `label_183`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_037.png)

**ID 39 · Barredor sinusoidal** — ×9 — `label_185`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_039.png)

**ID 40 · Rodillo interceptor desde atrás** — ×12 — `label_187`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_040.png)

**ID 41 · Caedor del techo** — ×4 — `label_190`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_041.png)

**ID 42 · Subidor del suelo** — ×4 — `label_195`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_042.png)

**ID 43 · Guardián flotante** — ×12 — `label_200`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_043.png)

**ID 47 · Zigzag** — ×36 — `label_204`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_047.png)

**ID 48 · Boya lanzadora izquierda** — ×2 — `label_205`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_048.png)

**ID 49 · Boya lanzadora derecha** — ×2 — `label_206`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_049.png)

**ID 51 · Barredor sinusoidal tirador** — ×9 — `label_185`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_051.png)

**ID 54 · Emboscador que apunta** — ×8 — `label_210`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_054.png)

**ID 99 · Disparador de Volca-Stone (oculto)** — ×6 — `label_344`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_099.png)

**ID 103 · Cañón fijo orientado** — ×26 — `label_270`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_103.png)

**ID 119 · Calavera-cañón de techo/suelo F4** — ×13 — `label_294`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_119.png)

**ID 120 · Generador de escombros** — ×2 — `label_295`  

**ID 122 · Obstáculo destructible** — ×3 — `label_297`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_122.png)

**ID 205 · Nave patrulla** — ×6 — `label_321`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_205.png)

**ID 206 · Torreta abanico** — ×1 — `label_322`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_206.png)

**ID 207 · Pod de 4 direcciones** — ×6 — `label_325`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_207.png)

### Generados por código (hijos, proyectiles, jefes y eventos)

**ID 38 · Bala direccional del mid-jefe 1 F4** — `label_184`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_038.png)

**ID 44 · Bala roja del jefe 4** — `label_201`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_044.png)

**ID 45 · Bumerán** — `label_202`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_045.png)

**ID 46 · Bala de abanico** — `label_203`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_046.png)

**ID 50 · Bala horizontal** — `label_207`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_050.png)

**ID 52 · Proyectil 4 direcciones** — `label_208`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_052.png)

**ID 55 · Gota de lluvia destructible** — `label_214`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_055.png)

**ID 56 · Gota indestructible** — `label_215`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_056.png)

**ID 57 · Tridente** — `label_216`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_057.png)

**ID 58 · Micro-explosión** — `label_217`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_058.png)

**ID 59 · Rayo radial** — `label_219`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_059.png)

**ID 60 · Cascote del mid-jefe** — `label_220`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_060.png)

**ID 61 · Pez saltarín de fondo** — `label_222`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_061.png)

**ID 62 · Pez saltarín de techo** — `label_223`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_062.png)

**ID 63 · Lanza vertical** — `label_224`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_063.png)

**ID 121 · Escombro que cae** — `label_296`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_121.png)

**ID 123 · Carcasa del jefe 4** — `label_298`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_123.png)

**ID 124 · Destello de aparición** — `label_300`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_124.png)

**ID 208 · Lanza horizontal ultra rápida** — `label_326`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_208.png)

**ID 508 · Mid-jefe F4 nº1 – Pod octogonal** — `label_494`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_508.png)

**ID 509 · Mid-jefe F4 nº2 – Acorazado rojo** — `label_512`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_509.png)

**ID 510 · Mid-jefe F4 nº3 (nave hermana infectada)** — `label_519`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_510.png)

**ID 511 · JEFE F4 – Núcleo de Volcabamba** — `label_527`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_511.png)

**ID 199 · Volca-Stone (recogible)** — `label_345`  
![](../15_ASSETS_REFERENCIA/fichas_enemigos/enemigo_199.png)


## Oleadas
[`fase4_oleadas.md`](fase4_oleadas.md) · [`fase4_oleadas.csv`](fase4_oleadas.csv). Los ticks no incluyen la duración de las 3 arenas.
