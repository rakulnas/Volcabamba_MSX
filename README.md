# Volcabamba MSX2 / MSX turboR

Proyecto de port nativo Z80 de **Life Fortress Volcabamba**.

## Estado del proyecto (2026-10-08)

**H02 está en preparación; no existe aún ROM H02 compilada y validada en este repositorio.** El repositorio se inicializa para centralizar el proyecto; no contiene todavía el código fuente maestro ni binarios verificados.

### Referencias de autoridad

1. Código original HSP / documentación original del juego.
2. Port Mega Drive FIX23.
3. Volcabamba MSX2 BASE12 WORLD1 DEEP PARITY.
4. Volcabamba MSX2/turboR HYBRID H01 (pendiente de importar y verificar).

### BASE12: información documentada

- Fase 1: secuencia de 184 registros, hasta 40 enemigos y 20 disparos enemigos.
- Centinela doble láser, ID105, piedras ID99→ID199 y patrones del Kraken.
- Compilación Z80 con cartuchos ASCII16 documentada como reproducible.
- Pruebas funcionales en emulador y hardware: pendientes de comprobar aquí.
- Fases 2–6: estado alfa, no equivalente todavía a la fase 1.

### H02: tareas pendientes

- Recuperar y verificar el SOURCE completo H01/BASE12 y los recursos originales.
- Comparación sistemática contra HSP/FIX23; corregir nave nodriza, bloques ID201,
  prioridad gráficos/sprites, animación Kraken y evento t40.
- Mejorar scroll y transferencias VDP, presupuesto de CPU y memoria.
- Configuraciones MSX2 y turboR desde una fuente común.
- Compilación limpia, reproducibilidad hash, test de arranque y juego real.

## Política de builds

**SOURCE → conversión de recursos → ensamblado Z80 → enlazado/bancos → ROM → validación.**

No se parchearán ROM anteriores ni se declararán builds sin compilación verificable.

## Estructura prevista

- `src/`: lógica Z80.
- `assets/`: recursos fuentes y convertidos reproduciblemente.
- `tools/`: conversores y utilidades.
- `build/`: scripts y configuraciones.
- `roms/`: únicamente ROMs verificadas.
- `docs/`: documentación y trazabilidad.

La estructura se irá creando cuando se importen archivos reales, sin placeholders presentados como resultados.
