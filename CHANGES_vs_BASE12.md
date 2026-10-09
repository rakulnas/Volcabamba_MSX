# H01 frente a BASE12

Punto de partida: SOURCE de `VOLCABAMBA_MSX2_NATIVE_BASE12_WORLD1_DEEP_PARITY`
(sus conversores y datos se usan sin cambios; los bancos 1..19 salen idénticos).

## Arquitectura nueva

- BOOT propio en banco 0 (detección MSX1/MSX2/MSX2+/turboR, ID de VDP,
  CHGCPU R800, aviso MSX1, trampolín con verificación de firma).
- Motor movido a módulo con ABI (`VE` + tipo + versión, entrada `4010h`),
  ensamblado dos veces: banco 20 (Z80) y banco 21 (R800).
- Bloque compartido `HYB_*` (máquina, configuración, récords) en `E000h`.
- `tools/z80mini.py`: `-D`, `IF/ELSE/ENDIF`, `ASSERT`, `in a,(n)`, `--sym`,
  comparaciones en expresiones. Sigue ensamblando el `main.asm` de BASE12 byte a byte igual.
- `tools/build_rom.py` enlaza boot + datos compartidos + 2 motores.
- `tools/validate_hybrid.py` (85 comprobaciones) y `tools/emu/run_emu_tests.py`.

## Rendimiento del motor (común a los dos módulos)

Medido en openMSX, C-BIOS MSX2, Fase 1 completa con invencibilidad y disparo continuo:

| | BASE12 | H01 motor Z80 |
|---|---|---|
| Ticks lógicos por segundo (objetivo 33,3) | **~19** (57 %) | **33,29** |
| Segundo más lento | 15 | 32 |
| Fase 1 terminada | no a los 200 s | a los ~173 s |
| Ticks con sprites dibujados | — | 98,5 % |

Causas y arreglos:

1. **Planificador**: contaba vueltas de bucle, no frames reales → ahora usa `JIFFY` con la misma cadencia 2/3 (PAL) y 5/9 (NTSC) y recupera como mucho 2 ticks.
2. **Colisión con mapa**: recorría la fila RLE desde la columna 0 en cada consulta → ventana decodificada de 40 columnas, actualizada al avanzar el scroll.
3. **Disparo contra enemigo**: 40 × 6 pruebas completas por tick → lista compacta de disparos activos + descarte grueso (superconjunto exacto de todas las cajas).
4. **Color por slot**: cadena de 33 comparaciones y escritura de 16 bytes de VRAM por enemigo y frame → tabla + caché por slot.

## Cambios de comportamiento (intencionados)

- **Láser del Centinela Ocular**: BASE12 avanzaba su temporizador dos veces por
  tick (`update_midboss` y `game_tick`). Duraba 13 ticks en vez de 27 y la fase
  letal `chr152` duraba 1 tick en vez de 2. Ahora sigue `case 100` de FIX23.
- **Centinela**: BASE12 no dibujaba ningún enemigo del pool mientras el
  Centinela estaba en pantalla (las palomitas ID3 y las minas ID13 eran
  invisibles pero letales). Ahora: 3 slots en Z80, 5 en R800.
- **Escoltas**: hasta 2 enemigos del pool visibles en los slots 18-19.
- El disparador oculto ID99 ya no gasta un slot de sprite.

## Verificación de que la lógica no ha cambiado

Traza del estado de juego (`C000h-C01Fh`, `C050h-C0D9h`, pools `C200h-C395h`)
en la entrada de cada tick, mismas entradas, Fase 1 completa (5282 ticks):

- BASE12 vs H01 Z80: idéntico salvo `MID_LASER_T` (`C0D7h`), que es el arreglo del láser.
- H01 Z80 vs H01 R800: idéntico.
- Ventana de colisiones vs datos RLE de la ROM: 0 diferencias (Fase 1 en 14 momentos, fases 2..6 en ambos motores).

## Sin cambios

Datos, scripts, IA, daño (10 HP), hitboxes, pools 40/20/3+3, Kraken, piedras,
controles, fondo negro de la Fase 1. Fases 2..6 siguen en estado alpha
(la Fase 6 se comporta igual que en BASE12: no llega a correr ticks de juego).
