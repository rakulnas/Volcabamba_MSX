# Arquitectura — VOLCABAMBA_MSX2_TURBOR_HYBRID

## 1. Mapa de la ROM (ASCII16, 32 bancos de 16 KiB)

| Banco | Contenido | Origen |
|---|---|---|
| 0 | **BOOT**: cabecera `AB`, detección, aviso MSX1, trampolín | `src/boot/boot.asm` |
| 1 | COMMON compartido: título, intro, sprites, paleta, final | `tools/pack_full_game.py` |
| 2..19 | Fases 1..6 compartidas (gfx / dataA / dataB por fase) | `tools/pack_*.py` |
| 20 | **ENGINE_Z80** (MSX2 / MSX2+) | `engine.asm` con `-D TURBO=0` |
| 21 | **ENGINE_R800** (turboR) | `engine.asm` con `-D TURBO=1` |
| 22..31 | libres (0xFF) | — |

Página 1 (`4000h-7FFFh`, registro `6000h`) = BOOT al encender, motor después.
Página 2 (`8000h-BFFFh`, registro `7000h`) = bancos de datos, igual que BASE12.

## 2. BOOT

1. `MSXVER` (`002Dh`) = 0 → `INITXT` + aviso **MSX2 OR HIGHER REQUIRED** (bucle `halt`).
2. Bloque compartido `HYB_*` en `E000h`: si la firma `VHYB` es válida se
   conserva (reset en caliente), si no se inicializa.
3. ID de VDP leyendo `S#1` (0 = V9938, 2 = V9958) y restaurando `R#15 = 0`.
4. Teclas de prueba N / R / F (ver README).
5. `MSXVER >= 3` → turboR: comprueba que `0180h` y `0183h` son `JP`, llama
   `CHGCPU` con `A = 82h` (R800 DRAM + LED) y guarda `GETCPU` en `HYB_CPU`.
6. Copia un trampolín de 48 bytes a `E040h`, que conmuta la página 1 al banco
   del motor, **verifica la firma** (`VE`, tipo `Z`/`R`, ABI 1) y salta a
   `4010h`. Si la firma no cuadra vuelve al banco 0 y muestra `ENGINE BANK ERROR`.

## 3. ABI de módulo de motor

```
4000h  "VE"         firma
4002h  'Z' | 'R'    tipo
4003h  1            versión ABI
4004h  word         tamaño del motor
4010h               entrada (DI)
```

El motor nunca escribe en `6000h` (no cambia su propia página); la validación
lo comprueba sobre el binario.

## 4. Contrato de RAM compartido (`src/shared/hybrid.inc`)

| Dirección | Campo |
|---|---|
| `E000h` | firma `VHYB` |
| `E004h` | `HYB_MSXVER` 1/2/3 |
| `E005h` | `HYB_VDP_ID` 0 = V9938, 2 = V9958 |
| `E006h` | `HYB_CPU` 0 Z80, 1 R800 ROM, 2 R800 DRAM |
| `E007h` | `HYB_ENGINE` `Z`/`R` |
| `E008h` | `HYB_FORCE` override de test |
| `E009h` | `HYB_CFG` bit0 = mejoras opcionales del motor R800 |
| `E00Ah` | contador de arranques |
| `E010h` | récord: fase más alta alcanzada |
| `E011h` | récord: máximo de Volca-Stones a la vez |
| `E012h` | récord: partidas completadas |
| `E040h` | trampolín BOOT → motor |

Configuración y récords son **los mismos para las dos rutas** porque el
formato está en un único include y los dos motores salen del mismo fuente.
Sobreviven a un reset en caliente, **no** a apagar: ASCII16 no tiene SRAM.
Para guardado real habría que pasar a un mapper con SRAM (p. ej. ASCII16 + 8 KiB SRAM).

Los motores usan `C000h-C7FFh` (como BASE12) y `D000h-D6FFh` (ventana de colisiones).

## 5. Un fuente, dos motores

Todo lo que es juego — orden del tick, IA, scripts, colisiones, daño,
tiempos — se ensambla igual para los dos. `IF TURBO` sólo aparece en:

- la cabecera del módulo (tipo `Z`/`R`);
- `RL_ROTATE` (multiplexado por rotación) al arrancar el motor;
- `get_layout` / `layout_table_r800` (qué slots SAT usa cada lista).

Prueba en emulador: estado de juego idéntico tick a tick entre los dos motores
durante toda la Fase 1 (`determinism_z80_vs_r800_engine`).

## 6. Motor de sprites por listas (ambos motores)

`render_enemy_list` y `render_bullet_list` dibujan los 40 enemigos lógicos y
las 20 balas en una lista de slots SAT que depende del momento:

| Momento | Z80: enemigos / balas | R800: enemigos / balas |
|---|---|---|
| Normal | 8 (8-15) / 8 (20-27) | 11 (8-15,17-19) / 11 (20-30) |
| Centinela (ocupa 8-19) | 3 (21-23) / 1 (20) | 5 (26-30) / 6 (20-25) |
| Escoltas (ocupan 8-17) | 2 (18-19) / 8 | 2 (18-19) / 11 |

En el motor R800, cuando una lista se desborda, el frame siguiente empieza por
el primer registro que no cupo: todos los enemigos aparecen (parpadeo clásico)
y el límite de 8 sprites por línea se reparte entre frames.

El color de sprite modo 2 es por slot: `enemy_color_fill` guarda en
`SLOT_COLOR` el último color escrito en cada slot y sólo toca la VRAM cuando
cambia. Cualquier carga masiva de colores invalida esa caché.

## 7. Planificador en tiempo real

BASE12 contaba vueltas de bucle, no frames reales: si un tick tardaba más de un
frame, el juego entero iba más lento (medido: ~19 ticks/s en vez de 33,3).
Ahora `sched_frames` lee `JIFFY`, aplica exactamente la misma cadencia
(PAL 2 de cada 3 frames, NTSC 5 de cada 9) y acumula como mucho 2 ticks
pendientes. Un tick de recuperación no dibuja sprites (`SKIP_RENDER`); la
lógica nunca se salta.

## 8. Ventana de colisiones

`collision_at` recorría la fila RLE desde la columna 0 en cada consulta
(decenas de consultas por tick). Ahora hay una ventana anular de 22 filas × 64
columnas en `D000h` con las columnas `SCROLL_COL .. SCROLL_COL+39` ya
decodificadas: un cursor RLE por fila avanza una columna cada vez que avanza
el scroll. Fuera de la ventana se usa la ruta RLE original. Verificada contra
los datos de la ROM en las seis fases (0 diferencias).

## 9. turboR

El motor R800 hace exactamente la misma lógica a la misma cadencia (33,3 Hz,
como el original); el R800 da margen para dibujar más sprites y, más adelante,
para efectos, más balas visibles o lo que se quiera activar con `HYB_CFG`.
Los accesos a VDP siguen pasando por las rutinas BIOS; además, en modo R800 el
S1990 del turboR separa automáticamente los OUT al VDP (~54 ciclos a 7,16 MHz),
así que el código de VDP pensado para Z80 sigue siendo seguro.
