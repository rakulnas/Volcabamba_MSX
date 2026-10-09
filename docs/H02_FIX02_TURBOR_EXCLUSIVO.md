# H02 FIX02 — Hybrid + turboR exclusivo (2026-10-09)

Dos cartuchos ASCII16 de 512 KiB compilados **desde el mismo código fuente Z80/R800**, sin parchear ROM anterior.

| Salida | Arranque | Banco 20 | Banco 21 | SHA-256 |
|---|---|---|---|---|
| `VOLCABAMBA_MSX2_TURBOR_H02_FIX02_HYBRID.rom` | MSX2 Z80 / turboR R800, detección BIOS | VEZ v1 | VER v1 | `c318eb3180e3fd0c9906505bbc86bf0a08640cf8d903bbbfee7556585029e5af` |
| `VOLCABAMBA_MSX_TURBOR_H02_FIX02_EXCLUSIVA.rom` | Exige MSXVER=3, CHGCPU R800 DRAM, verifica GETCPU=2 | todo FF (no contiene motor Z80) | VER v1 | `60b722cd38394339dbba0066537b14665470e754d9931f64c6a158967142b7fc` |

El arranque exclusivo muestra un aviso si no detecta una turboR válida. Las dos ROMs mantienen los bancos de recursos 1..19 idénticos byte a byte.

**Pruebas realizadas:** 85 validaciones estáticas del cartucho híbrido, 40 regresiones estructurales del frontend, 14 comprobaciones de separación de CPU, compilación y reconstrucción de las dos ROMs desde un ZIP fuente limpio con hash idéntico. No se ha ejecutado un emulador ni probado hardware real en este pase.

**Pendientes visuales anteriores — no resueltos en este cambio:** scroll por tiles de 8 píxeles, continuidad del despegue, superposición de la nave sobre la nodriza, estrellas y cartel CAUTION auténtico. No llamar a este build versión definitiva.

La ROM y el ZIP SOURCE están entregados como adjuntos de la conversación, **todavía no subidos a GitHub**. Para probar turboR en openMSX, usar una configuración Panasonic FS-A1ST o FS-A1GT con BIOS válidas y cartucho ASCII16.
