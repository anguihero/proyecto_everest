# Intervención — Resultados auditables y radar DISC

**Estado:** Desplegada y validada en staging.  
**Migración:** `20260629000012_auditable_results.sql`  
**Fecha:** 2026-06-29

## Entregado

- gráfico radar SVG accesible para D, I, S y C;
- escala radial dinámica: 0 hasta el 110% del valor DISC máximo;
- distribución textual conservada como alternativa accesible;
- promedio de tiempo por pregunta;
- cantidad de respuestas con tiempo frente al total;
- referencia corta auditable `EV-XXXXXXXXXXXX`;
- IDs de resultado, sesión, usuario, experiencia y versión en el contrato;
- versiones de experiencia, schema y scoring;
- fingerprint MD5 determinístico de las respuestas ordenadas;
- botón para copiar el UUID completo del resultado.

## Relación auditable

```text
result_id
  → score_results.session_id
  → experience_sessions.user_id
  → experience_sessions.experience_version_id
  → experience_versions.experience_id
```

Las respuestas permanecen relacionadas mediante `session_answers.session_id` y
la evidencia mediante `result_evidence.score_result_id`. Esto permite localizar
los insumos originales y ejecutar posteriormente un proceso controlado de
recalculo sin confundirlo con el resultado histórico.

## Compatibilidad histórica

Los resultados creados antes del registro de `response_time_secs` tienen
`timed_answers = 0`. La UI muestra “No disponible”; no se infieren tiempos desde
timestamps porque produciría una métrica engañosa.

## Evidencia

- migración local/remota alineada en `20260629000012`;
- RPC validada con un resultado v1 de 3 respuestas;
- RPC validada con un resultado v2 de 20 respuestas;
- referencias, UUID, usuario, versiones y fingerprint presentes;
- 11/11 pruebas unitarias aprobadas;
- E2E del resultado real aprobado: radar, métrica, referencia y versión visibles.

## Pendiente separado

La regeneración no debe sobrescribir `score_results`. Debe implementarse como
una operación administrativa auditada que:

1. reciba `result_id`;
2. use la versión y reglas originales;
3. compare el fingerprint de entradas;
4. genere una nueva revisión enlazada al resultado original;
5. conserve actor, fecha, motivo y diferencias.
