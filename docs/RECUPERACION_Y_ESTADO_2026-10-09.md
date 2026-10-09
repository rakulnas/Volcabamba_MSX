# Traspaso completo: estado y límites

Este repositorio debe ser el lugar canónico del port **Volcabamba MSX2 / turboR**. La copia local de trabajo contiene **18 entregables (aprox. 101 MB)**: ROMs H01/H02/FIX01/FIX02/FIX03 y ZIPs de SOURCE de cada revisión. El último SOURCE completo disponible es `VOLCABAMBA_MSX2_TURBOR_H02_FIX03_SOURCE_COMPLETO.zip` (124 archivos; 15.938.904 bytes descomprimidos).

## Material en el SOURCE FIX03
- `src/`: fuente motor Z80 / R800 y módulos compartidos.
- `res/canonical/`: gráficos canónicos.
- `reference/GDD/`: GDD HTML y PDF.
- `reference/md_fix23/`: descompilado original HSP y comparativas MD.
- `reference/fix23_source/`: módulos fuentes Mega Drive FIX23.
- `reference/fullgame/`: niveles, generadores, gráficos y notas originales.
- `build.sh`, `Makefile` y validaciones/reconstrucción.

## Fallos reconocidos por el usuario, **NO RESUELTOS NI VALIDADOS**
- Scroll sigue por bloques de 8 píxeles, con trompicones.
- Nave superpuesta por delante de nodriza; debería salir por detrás.
- Salto y glitches entre despegue y fase.
- Estrellas ausentes en nave, presentes en nodriza.
- Aviso gráfico `CAUTION` antes del midboss ausente o incorrecto.
- Falta confirmación real de funcionamiento de HUD, vidas y trayecto completo.

## Estado de la transferencia
Este documento y otros apuntes están en GitHub. **Los binarios y los ZIPs de SOURCE no se han podido subir en esta operación**: la red del contenedor no resuelve github.com y la conexión GitHub no puede leer archivos binarios del contenedor. Existe un paquete local de traspaso `/mnt/data/VOLCABAMBA_GITHUB_HANDOFF/` que incluye los 18 ficheros, `MANIFEST.json`, SHA256 y `README.md`. Para completar la transferencia, hay que hacer `git add` y `git push` desde un equipo con acceso y autenticación. No presentar el repositorio como completo antes de verificar todos los recursos subidos.

## Reglas
SOURCE → conversores → ensamblado → ROM → validación; nunca parcheo de ROM previa. Conservar H01 y versiones históricas, y señalar claramente versiones experimentales. No publicar una versión como definitiva sin pruebas de emulación y gameplay.
