# VOLCABAMBA MSX2 / turboR — H02 FIX01

## Corregido en SOURCE Z80 / R800

1. La nave del prólogo se sitúa en `INTRO_X=96`, `INTRO_Y=48`, centrada respecto a la compuerta del recurso canónico de la nodriza (`mother_open.png`, compuerta x81..127, y64..73 en pantalla de 256x192). La transición de posición a `PLAYER_X/Y` sigue siendo directa.
2. Se restaura el último fotograma de salida de la nodriza, `mother_depart_7.png`, en t=123..124, antes de reconstruir el escenario. Se mantiene el calendario total del prólogo de 125 ticks.
3. HUD de la fila superior dinámico: HI 0039600 inicial, SCORE 0000000 con créditos de enemigos de la Fase 1 y Volca-Stones, vidas de reserva en las dos columnas finales. Las cifras usan tiles reales construidos por el conversor a partir de `original_font.png`. La Fase 4 reserva espacio para los diez glifos.
4. Las vidas se inicializan a 3, se descuentan una vez por muerte, permiten `GAME OVER` y reinicio de la fase actual (puntuación, piedras, reservas y umbral de extend restaurados), sin saltos indebidos de pila.
5. Extends en 20.000 y cada 50.000 puntos. Puntuación por grupos de enemigos de Fase 1 según los valores del script FIX23 (100, 200, 300 o 500), y 1000 por Volca-Stone recogida. La puntuación de fases 2..6 aún requiere homologación completa con HSP.

## Build reproducible

- `./build.sh` compila la variante conservadora `SMOOTH_SCROLL=0` (recomendada para probar este FIX01, HUD fijo).
- `SMOOTH_SCROLL=1 ./build.sh` compila la variante de desplazamiento fino experimental.
- Herramientas: Python 3 y Pillow. La build regenera recursos, ensamblador Z80, banco Z80, banco R800 y enlaza el cartucho ASCII16 512 KiB sin ROM anterior.
- Salida: `out/VOLCABAMBA_MSX2_TURBOR_HYBRID_H02.rom`.

## Evidencia y límites

- `tools/validate_hybrid.py`: 85 verificaciones estáticas de la ROM.
- `tools/test_frontend_fix01.py`: 40 verificaciones estructurales del frontend y metadatos de las seis fases.
- Sin prueba de ejecución en openMSX/C-BIOS ni hardware real: este informe **no** certifica que la transición sea visualmente perfecta o que las rutinas funcionen correctamente durante una partida real.
- En `SMOOTH_SCROLL=1`, el ajuste R#18 del V9938 puede desplazar también el HUD, y el V9958 necesita inspección de márgenes: esa variante sigue siendo **experimental**.
- La alta fidelidad de las fases 2..6 permanece pendiente de comparación completa con HSP y FIX23.

**Nunca** parchear/reescribir la ROM H01 como sustituto de compilar el SOURCE.
