# Volcabamba MSX2 / turboR — H02 (8 octubre 2026)

## Estado
H01 permanece congelada e intacta. H02 se compila desde SOURCE nativo en dos configuraciones, ambas de 512 KiB / ASCII16:
- **H02_FIDELITY**: mismas rutinas de presentación visual de H01; corrige borrado del pool de 40 enemigos en Kraken (el motor escribía 05h en vez de cero) y respawn de fases 2–6 usando START_X/START_Y.
- **H02_SCROLL_PREVIEW**: añade desplazamiento horizontal de 1 píxel por tick lógico durante los 8 pasos de cada tile. V9938: display adjust R#18; V9958: scroll R#26/R#27. No cambia la velocidad lógica, la agenda de enemigos ni los gráficos.

## Verificaciones hechas
- SOURCE → ensamblador Z80 para bancos 20 y 21 → enlazado ASCII16 → ROM.
- 85 pruebas estáticas de validate_hybrid.py: PASS para ambas ROM.
- 19 bancos de datos originales (1 a 19) idénticos byte a byte frente a H01.
- ROM de 524.288 bytes en ambas configuraciones.
- Hash H02_FIDELITY: `69198d23468e1d0d53844900751d6ccfe8c36607c08bcb4d804436987fd259d6`.
- Hash H02_SCROLL_PREVIEW: `ec851dfea2361221f1c482a90fb1993b781079557efaf049d79883b6fa2e7d6a`.

## Precauciones
La variante SCROLL_PREVIEW **NO** está visualmente validada. En V9938 el registro R#18 desplaza también bordes/HUD y puede alterar la posición aparente de sprites; en V9958 deben revisarse márgenes y wrap de columnas. Requiere corrección por zonas, posible split de raster y pruebas de hardware antes de ser definitiva.

Las fases 2–6 continúan con fidelidad parcial heredada de H01/BASE12. No se declara H02 definitiva.

## Compilación reproducible
El código fuente completo se conserva en el paquete de entrega H02 SOURCE generado en la conversación. Parámetros soportados por `build.sh`:
```sh
SMOOTH_SCROLL=1 ./build.sh
SMOOTH_SCROLL=0 ./build.sh
```
**Este repositorio aún no contiene los ZIP, ROM ni SOURCE H02:** esta nota documenta el progreso verificable hasta incorporarlos.