# Estado auditado del respaldo — 11/10/2026

El repositorio tiene conexión **operativa** y permisos de escritura verificados. Posee el motor Z80/R800, herramientas de construcción, referencias HSP/FIX23, 25 PNG y las **dos ROMs H02 FIX03 actuales**. La ROM híbrida tiene SHA-256 `8148b4c0406e836024acf14de8c7a7bf9c3e491d6b3d18878fed13a86fdd6053` y turboR `94c6fa97c5e31828a5c0a4b6bfa2f24810f93b5c3eb5f599b478c6e617ca5cab`. Sus objetos Git coinciden con la ROM compilada desde SOURCE local completo.

**No está completo**: faltan 18 PNG canónicos, 9 ZIP históricos, 9 ROMs históricas, los dos GDD PDF/HTML y manifiestos de respaldo. Ver [issue #1](https://github.com/rakulnas/Volcabamba_MSX/issues/1) con lista cerrable.

**Tests hechos**:
- ZIP local de 155 archivos validado contra sus 153 entradas de SHA-256 (se excluyen los dos archivos de autoinventario); ZIP validado íntegramente.
- Compilación local nativa `bash build.sh`: PASS 85 validaciones, 40 tests de HUD y frontend, 14 para turboR y test FIX03; ambas ROMs idénticas a las publicadas.
- Reproducción de ausencia de assets en un clon incompleto: `FileNotFoundError: res/canonical/stage1_map.png`.
- Las ejecuciones de GitHub Actions siguen rojas. CI ahora muestra expresamente los 18 gráficos ausentes. No equivale a una prueba jugable en emulador.
- El script de importación se ha probado en un **repositorio Git local de ensayo**, con subida, clon limpio, verificación SHA de **63 recursos/ROMs/históricos/GDD** y compilación byte a byte de ambas ROMs. **No significa** que se haya subido el respaldo entero a GitHub público.

**Paquete maestro corregido**: `VOLCABAMBA_GITHUB_BACKUP_VERIFICADO_2026-10-11.zip` (155 archivos), SHA-256 `9e2072e857b0fcbfa56be5e1ca49343efe4d81ea361d072082ad2f7be172e2cb`. Se entrega en la conversación, no está alojado aún en el remoto. Contiene el nuevo `PUBLICAR_EN_GITHUB.command` que **no sobreescribe ningún archivo existente** en GitHub, añade los faltantes y verifica el resultado con un clon limpio.

**Para declarar copia independiente completa**, ejecutar script desde el paquete maestro en un equipo con conexión y credenciales GitHub, obtener workflow PASS en GitHub y confirmar las 9 ROMs históricas, 9 ZIP, 43 gráficos y el GDD. La música independiente no está localizada. La fidelidad jugable FIX03 (scroll al píxel, nodriza, CAUTION) sigue pendiente.
