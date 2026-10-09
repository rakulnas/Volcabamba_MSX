# VOLCABAMBA_MSX2_TURBOR_HYBRID — H01

Un solo cartucho `.rom` (512 KiB, mapper **ASCII16**) que decide solo en qué
máquina está y arranca el motor adecuado:

| Máquina | Lo que pasa |
|---|---|
| MSX1 | Pantalla `MSX2 OR HIGHER REQUIRED` (no se cuelga) |
| MSX2 / MSX2+ | Motor **Z80** (banco 20): versión fiel optimizada |
| MSX turboR | CPU → **R800 DRAM** (LED turbo encendido) + motor **R800** (banco 21) |

El jugador no elige nada. Mapas, gráficos, scripts de oleadas, tablas, textos y
datos de juego son **los mismos bancos** para las dos rutas (bancos 1..19). Lo
único duplicado es el runtime, y ni siquiera a mano: los dos motores salen del
**mismo fuente** (`src/engine/engine.asm`) ensamblado con `TURBO=0` y `TURBO=1`.

```
BOOT (banco 0) → MSXVER → ID de VDP (V9938/V9958) → ¿turboR? → CHGCPU R800
     → trampolín en RAM → banco 20 (Z80) o 21 (R800) → juego
```

## Compilar

Requisitos: `python3` y `Pillow` (`pip install pillow`). Nada más.

```sh
./build.sh          # o: make
```

Salida: `out/VOLCABAMBA_MSX2_TURBOR_HYBRID.rom` + símbolos de los tres
módulos + `validation/`. La build borra `out/ generated/ validation/` y lo
regenera todo desde SOURCE: conversores de recursos → ensamblador Z80 (boot +
2 motores) → enlazado ASCII16 → validación estática. No lee, ni usa ni
parchea ninguna ROM/BIN anterior. Dos builds limpias dan la misma ROM byte a byte.

## Probar en emulador (opcional, no forma parte de la build)

```sh
python3 tools/emu/run_emu_tests.py          # ~20 s con openMSX + C-BIOS
python3 tools/emu/run_emu_tests.py --quick  # sólo pruebas de arranque
```

En macOS usa el openMSX instalado (`/Applications/openMSX.app` o
`OPENMSX=/ruta/openmsx`). Escribe `validation/EMULATOR_REPORT.json`.
Carga manual: `openmsx -machine C-BIOS_MSX2 -cart out/VOLCABAMBA_MSX2_TURBOR_HYBRID.rom -romtype ASCII16`.

## Controles (sin cambios)

- Cursores / joystick: mover
- Z / Botón 1: disparar
- X / Botón 2: cambiar dirección de disparo
- SPACE: START / pausa / continuar
- C: invencibilidad (debug)

## Teclas de prueba al arrancar (mantener pulsada durante el boot)

Sólo para test; el jugador normal no las necesita.

- **N**: fuerza el motor Z80 (en turboR la CPU se queda en Z80 → experiencia MSX2 exacta).
- **R**: fuerza el módulo R800 sin cambiar de CPU (permite probar el motor turboR en MSX2/emuladores sin BIOS turboR).
- **F**: motor R800 con los límites de sprites de MSX2 (desactiva las mejoras opcionales).

## Estado

- Arranque MSX1/MSX2/MSX2+ y rama turboR: **PASS** en openMSX/C-BIOS (la rama turboR con un arnés que simula la BIOS turboR; C-BIOS no tiene turboR).
- Fase 1 completa en MSX2 a **33,3 ticks/s** (BASE12 iba a ~19 = 57 % de velocidad).
- Estado de juego idéntico tick a tick a BASE12 durante toda la Fase 1 (5282 ticks), salvo el láser del Centinela, corregido a propósito.
- Motor Z80 y motor R800: estado de juego idéntico tick a tick (5282 ticks).
- **Pendiente de Felipe**: hardware real MSX2 y, sobre todo, **turboR real** (aquí no se puede emular el R800).
- Fases 2..6 siguen siendo la integración alpha heredada de BASE12.

Ver `ARCHITECTURE.md` y `CHANGES_vs_BASE12.md`.
