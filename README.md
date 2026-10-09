# Volcabamba MSX2 / turboR — repositorio canónico

Port nativo para MSX2 y MSX turboR, basado en el juego original HSP y la comparación con la fuente Mega Drive FIX23.

## Estado real — 9 de octubre de 2026

**H02 FIX03 es experimental**, NO definitivo. Se han compilado correctamente las ROMs híbrida y exclusiva turboR desde SOURCE, pero el scroll todavía va a saltos por tiles de 8 píxeles y la secuencia de salida de la nodriza sigue necesitando correcciones (profundidad de la nave, estrellas, transición). El cartel CAUTION se ha modificado en código pero no está validado visualmente.

**Importante:** los ZIPs y los archivos binarios completos todavía no están en este repositorio remoto. Están organizados en el paquete `VOLCABAMBA_GITHUB_REPOSITORIO_LISTO.zip` entregado en la conversación de ChatGPT; contiene 154 archivos, 107.363.251 bytes y SHA-256 `f32c0d45b6f46f4ffe282d2eb78b8fffb4b8622d2d1161fe1036b07168241377`.

## Cómo completar la importación de todo el material

1. Descargar y descomprimir `VOLCABAMBA_GITHUB_REPOSITORIO_LISTO.zip`.
2. En macOS o Linux, desde la carpeta descomprimida, ejecutar: `bash PUBLICAR_EN_GITHUB.command`.
3. El script clona este repositorio, conserva su documentación existente, añade **SOURCE, res/canonical, reference/GDD, reference/md_fix23, history/archives, roms/historic, validadores y hashes**, crea un commit y lo publica mediante `git push`.
4. Verificar en GitHub que aparecen los directorios anteriores y que la compilación nativa produce ROMs con las huellas indicadas más abajo.

Hashes esperados, build FIX03 conservadora:
- Híbrida: `8148b4c0406e836024acf14de8c7a7bf9c3e491d6b3d18878fed13a86fdd6053`.
- turboR exclusiva: `94c6fa97c5e31828a5c0a4b6bfa2f24810f93b5c3eb5f599b478c6e617ca5cab`.

La compilación requiere Python 3 y Pillow, y se realiza con `bash build.sh` tras la importación.

## Pendientes

- Scroll **verdaderamente por píxel** sin mover HUD ni producir bloqueos VRAM.
- Secuencia continua nodriza → salida → fase, con la nave oculta tras el casco.
- Fondo de estrellas original y aviso CAUTION validado en emulador.
- Verificar vidas/HUD, formaciones y jefes frente a HSP/FIX23, también fases 2–6.
- Emulación y hardware MSX2/turboR reales.

No se han identificado archivos musicales independientes en el SOURCE recuperado. No afirmar que la música está archivada ni que existe licencia pública para recursos originales sin verificarlo.

Documentación detallada: [recuperación](docs/RECUPERACION_Y_ESTADO_2026-10-09.md), [H02 FIX02](docs/H02_FIX02_TURBOR_EXCLUSIVO.md), [H02 FIX01](docs/H02_FIX01_FRONTEND_FIDELITY.md).
