# Backlog MVP Modular — Everest Experience

**Estado:** Borrador para refinamiento y aprobación  
**Fuente:** `05_context/CONTEXTO_IDEACION_MVP_MODULAR.md`  
**Fecha:** 2026-06-28

Este paquete convierte el contexto de “consola + fábrica de casetes” en requerimientos e historias de usuario trazables. Se mantiene separado del backlog legado porque ese backlog todavía presupone 20 preguntas DISC, tres rutas, chat abierto, avatar avanzado y otras funcionalidades fuera del MVP actual.

## Estructura

| Archivo | Contenido |
|---|---|
| `MASTER_REQUERIMIENTOS_MVP.md` | Requerimientos funcionales, técnicos, UX, seguridad, datos, IA y trazabilidad |
| `01_CONSOLA_IDENTIDAD_Y_ACCESO.md` | Identidad, roles, consentimiento, perfil, Hub y administración |
| `02_CONSOLA_MOTOR_Y_FABRICA.md` | Contrato de casete, catálogo, runner, persistencia, scoring, publicación y telemetría |
| `03_CASETE_EXPEDICION_BASE.md` | Contenido, ejecución, resultado y validación de la exploración conductual |
| `04_CASETE_EXPEDICION_CUMBRE.md` | Empresa, retos, coaches, consecuencias, VIA y cierre |
| `05_IA_RESULTADOS_GOBIERNO_Y_CALIDAD.md` | Sherpa, guardrails, visualización, privacidad, soporte, accesibilidad y QA |

## Convención de IDs

- `HU-CA-*`: consola, acceso e identidad.
- `HU-CM-*`: consola, motor modular.
- `HU-FB-*`: fábrica de casetes.
- `HU-EB-*`: casete Expedición Base.
- `HU-EC-*`: casete Expedición Cumbre.
- `HU-IA-*`: IA y Sherpa.
- `HU-RS-*`: resultados.
- `HU-GO-*`: gobierno, privacidad y soporte.
- `HU-QA-*`: calidad, accesibilidad y observabilidad.

## Lectura de cada historia

Cada HU contiene:

- tipo: funcional, UX, técnica o habilitadora;
- historia y valor;
- requerimientos trazados;
- criterios Gherkin;
- especificación UX;
- consideraciones técnicas y de datos;
- seguridad y privacidad;
- dependencias;
- Definition of Done.

Las estimaciones y asignaciones de sprint son preliminares. Deben refinarse después de aprobar las decisiones bloqueantes del maestro.

