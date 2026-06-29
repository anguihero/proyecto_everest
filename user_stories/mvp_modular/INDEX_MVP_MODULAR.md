# Índice de Historias de Usuario — MVP Modular

**Total:** 50 HU · **Estimación preliminar:** 375 SP  
**Estado:** Implementación parcial auditada el 2026-06-29. El estado verificado,
bugs y plan de intervención están en
[`docs/ESTADO_MVP_2026-06-29.md`](../../docs/ESTADO_MVP_2026-06-29.md).
Este índice conserva el alcance objetivo; no debe interpretarse como porcentaje
de implementación.

> Los SP sirven para comparar complejidad inicial, no constituyen todavía un compromiso de sprint.

## Resumen

| Dominio | IDs | HU | SP | Archivo |
|---|---|---:|---:|---|
| Consola: identidad y acceso | CA | 8 | 42 | `01_CONSOLA_IDENTIDAD_Y_ACCESO.md` |
| Consola: motor | CM | 7 | 52 | `02_CONSOLA_MOTOR_Y_FABRICA.md` |
| Fábrica de casetes | FB | 5 | 31 | `02_CONSOLA_MOTOR_Y_FABRICA.md` |
| Expedición Base | EB | 5 | 42 | `03_CASETE_EXPEDICION_BASE.md` |
| Expedición Cumbre | EC | 8 | 74 | `04_CASETE_EXPEDICION_CUMBRE.md` |
| IA / Sherpa | IA | 4 | 26 | `05_IA_RESULTADOS_GOBIERNO_Y_CALIDAD.md` |
| Resultados | RS | 3 | 18 | `05_IA_RESULTADOS_GOBIERNO_Y_CALIDAD.md` |
| Gobierno y soporte | GO | 5 | 40 | `05_IA_RESULTADOS_GOBIERNO_Y_CALIDAD.md` |
| Calidad | QA | 5 | 50 | `05_IA_RESULTADOS_GOBIERNO_Y_CALIDAD.md` |

## Lista maestra

| ID | Título | Tipo dominante | Prioridad | SP | Dependencias principales |
|---|---|---|:---:|---:|---|
| HU-CA-001 | Autenticación y recuperación segura | Funcional | Must | 5 | Supabase |
| HU-CA-002 | Organización, rol y autorización | Técnica/Seguridad | Must | 8 | DEC-P-03/04 |
| HU-CA-003 | Consentimiento informado | Legal/UX | Must | 5 | Política aprobada |
| HU-CA-004 | Perfil y configuración | Funcional | Must | 3 | CA-001/002 |
| HU-CA-005 | Hub y catálogo personal | Funcional/UX | Must | 5 | CM-001/002 |
| HU-CA-006 | Onboarding inicial | UX | Must | 3 | CA-001 |
| HU-CA-007 | Gestión de usuarios | Administrativa | Must | 8 | CA-002 |
| HU-CA-008 | Asignación y seguimiento | Administrativa | Must | 5 | CA-007, FB-005 |
| HU-CM-001 | Catálogo técnico | Técnica | Must | 5 | FB-001 |
| HU-CM-002 | Asignabilidad y compatibilidad | Técnica | Must | 3 | FB-001/003 |
| HU-CM-003 | Inicio de sesión versionada | Funcional/Técnica | Must | 5 | CA-003, CM-001 |
| HU-CM-004 | Runner genérico | Frontend/UX | Must | 13 | FB-001, CM-003 |
| HU-CM-005 | Autosave y concurrencia | Técnica | Must | 8 | CM-003/004 |
| HU-CM-006 | Scoring y finalización | Backend/Data | Must | 13 | FB-003 |
| HU-CM-007 | Telemetría común | Data | Must | 5 | Política analítica |
| HU-FB-001 | Contrato de casete | Arquitectura | Must | 8 | DEC-T-01 |
| HU-FB-002 | Ciclo de vida y versiones | Técnica/Gobierno | Must | 5 | FB-001 |
| HU-FB-003 | Validación prepublicación | QA/Técnica | Must | 8 | FB-001 |
| HU-FB-004 | Modo de prueba | Funcional | Must | 5 | CM-004, FB-002 |
| HU-FB-005 | Publicación y retiro | Gobierno | Must | 5 | FB-003 |
| HU-EB-001 | Banco de escenarios Base | Contenido | Must | 13 | DEC-P-01/02 |
| HU-EB-002 | Ejecución neutral Base | UX | Must | 5 | EB-001, CM-004 |
| HU-EB-003 | Scoring Base | Data/Psicometría | Must | 8 | EB-001, CM-006 |
| HU-EB-004 | Resultado conductual | UX/Contenido | Must | 8 | EB-003, IA-003 |
| HU-EB-005 | Piloto de ítems | Investigación | Must | 8 | EB-001–004 |
| HU-EC-001 | Narrativa de 10 retos | Contenido/Juego | Must | 13 | Brief aprobado |
| HU-EC-002 | Brief y progreso | UX | Must | 3 | EC-001, CM-004 |
| HU-EC-003 | Estados y consecuencias | Backend/Juego | Must | 13 | EC-001, CM-005 |
| HU-EC-004 | Coaches y fichas | Funcional/Juego | Must | 8 | DEC-P-06 |
| HU-EC-005 | Feedback y contrafactual | UX/Contenido | Must | 8 | EC-003/004 |
| HU-EC-006 | Evidencia VIA | Psicología/Data | Must | 13 | DEC-P-05 |
| HU-EC-007 | Cierre y plan | UX/Contenido | Must | 8 | EC-003/006 |
| HU-EC-008 | Piloto de balance | Investigación | Must | 8 | EC-001–007 |
| HU-IA-001 | Lectura estructurada | IA/Backend | Must | 8 | CM-006 |
| HU-IA-002 | Guardrails | IA/Seguridad | Must | 8 | Políticas aprobadas |
| HU-IA-003 | Fallback | Resiliencia | Must | 5 | IA-001/002 |
| HU-IA-004 | Trazabilidad IA | Gobierno/Técnica | Must | 5 | GO-005 |
| HU-RS-001 | Resultados accesibles | UX/Frontend | Must | 8 | Contrato resultado |
| HU-RS-002 | Separación conceptual | UX/Psicología | Must | 5 | DEC-P-02 |
| HU-RS-003 | Historial personal | Funcional/Datos | Must | 5 | CM-006, CA-002 |
| HU-GO-001 | Derechos del titular | Legal/Funcional | Must | 8 | Política retención |
| HU-GO-002 | Compartición consentida | Privacidad | Must condicionado | 8 | Rol Coach |
| HU-GO-003 | Métricas agregadas | Data/Privacidad | Should | 8 | Umbral aprobado |
| HU-GO-004 | Soporte auditado | Seguridad | Must | 8 | DEC-P-04 |
| HU-GO-005 | Auditoría transversal | Técnica/Gobierno | Must | 8 | Taxonomía |
| HU-QA-001 | Accesibilidad y performance | RNF/UX | Must | 8 | Transversal |
| HU-QA-002 | Revisión de contenido | Calidad | Must | 8 | Matriz revisores |
| HU-QA-003 | Observabilidad y errores | Técnica | Must | 8 | Taxonomía errores |
| HU-QA-004 | Suite de seguridad | QA/Seguridad | Must | 13 | CA-002 |
| HU-QA-005 | Piloto integral | Producto/QA | Must | 13 | EB-005, EC-008 |

## Orden sugerido de refinamiento

### Ola 0 — Decisiones

- DEC-P-01 a DEC-P-06.
- DEC-T-01 y DEC-T-02.
- DEC-L-01.

### Ola 1 — Vertical slice de consola

- HU-FB-001.
- HU-CA-001 a HU-CA-003.
- HU-CM-001, HU-CM-003 a HU-CM-006.
- HU-RS-001.
- HU-QA-001, HU-QA-003 y HU-QA-004.

### Ola 2 — Vertical slice de contenido

- HU-EB-001 a HU-EB-004 con un escenario inicial.
- HU-EC-001 a HU-EC-007 con dos retos conectados.
- HU-IA-001 a HU-IA-003.

### Ola 3 — Fábrica y operación

- HU-FB-002 a HU-FB-005.
- HU-CA-005, HU-CA-007 y HU-CA-008.
- HU-GO-001, HU-GO-004 y HU-GO-005.

### Ola 4 — Piloto y capacidades Should

- HU-EB-005, HU-EC-008 y HU-QA-005.
- HU-GO-002 y HU-GO-003 según el modelo comercial aprobado.

## Candidatas explícitas para después del MVP

- Editor visual completo de casetes.
- Avatar avanzado, XP, medallas y tienda.
- Chat abierto y memoria conversacional.
- Tres rutas por dificultad.
- Modo multijugador o sesión sincrónica.
- SSO, multiidioma y notificaciones.
- PDF/Excel avanzado.
- Generación automática de retos.
- Replays comparativos.
- Facturación y licenciamiento.
