# H02 FIX01 — Volcabamba MSX2 / turboR

Estado: ROM y SOURCE compilados, **validación funcional en emulador/hardware pendiente**.

Correcciones sobre SOURCE nativo de H02:
- Reubicar fighter de introducción a x96/y48, alineado a la escotilla del PNG canónico (zona x81..127, y64..73).
- Mostrar último fotograma original `mother_depart_7` en ticks 123–124 antes de cargar escenario.
- HUD numérico vivo (HI 39600, puntuación dinámica, 2 cifras de reservas), glifos fuentes originales regenerados para cada etapa.
- Vidas iniciales 3; decremento una vez por muerte; al agotarse, GAME OVER; al continuar, misma fase, vidas y score reseteados.
- Puntuación fase 1: variantes 100/200/300/500 de enemigos; piedra +1000, extends desde 20000 y después cada 50000.
- Reserva de patrones SCREEN4 para los 10 dígitos también en fase 4.

Build: `./build.sh` seguro (SMOOTH_SCROLL=0), `SMOOTH_SCROLL=1 ./build.sh` experimental (puede desplazar el HUD en V9938).

Evidencia:
- ROM segura 512 KiB SHA-256 `c0c436e4707b052b5488f2ba9d23828b6237053718c2f17ca7e4ffce0fda08af`.
- ROM smooth preview SHA-256 `825cf20c9e05a131e512be37c9b1fd7324bd645a04c950f2b1061262bc5c8532`.
- 85 validaciones estáticas + 40 validaciones de frontend, build desde ZIP limpio idéntica byte a byte.
- El SOURCE y las ROM son entregables de conversación; **no se han subido al repositorio GitHub**.

Limitaciones: sin validación visual abierta de MSX2/turboR; scroll fino puede mover HUD; fases 2–6 mantienen paridad parcial. No declarar definitivo.