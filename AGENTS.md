# Continuidad del proyecto Volcabamba MSX2 / turboR

- Fuentes de verdad: original HSP y GDD, fuente Mega Drive FIX23, port SOURCE H02 FIX03.
- **NO** tratar FIX03 como una versión definitiva. El usuario ha comprobado scroll a saltos de 8 píxeles, fallos de profundidad y transición de nodriza, estrellas y CAUTION.
- Antes de modificar: compilar el SOURCE nativo Z80/R800 desde cero y guardar SHA-256. No parchear ROMs anteriores.
- Entregar dos builds: híbrida MSX2/turboR (detección CPU) y exclusiva turboR (motor R800), cada una con SOURCE completo.
- No dar por corregido scroll real al píxel con un simple ajuste de VDP si persisten saltos al actualizar tiles o se desplaza el HUD.
- Comprobar eventos y patrones contra el HSP original y FIX23. Verificar visualmente intro, despegue, fase 1, CAUTION, Centinelas, Kraken, HUD y vidas.
- No eliminar snapshots/ROMs históricos ni confundir pruebas estructurales con pruebas jugables.
- El repositorio debe conservar código, recursos gráficos, documentación, GDD, generadores y música **cuando exista**; música independiente no localizada por ahora.
- Confirmar archivos en GitHub y commit remoto antes de decir que el material se ha subido.