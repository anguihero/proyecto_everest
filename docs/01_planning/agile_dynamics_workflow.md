# 5. Dinámicas de Trabajo Ágil y Gestión de Backlog Técnico

Este documento formaliza los rituales metodológicos adoptados por el equipo para el control de avance del proyecto, asegurando visibilidad constante para el Product Owner y flexibilidad para el equipo de ingeniería.

## 🔄 Rituales del Sprint (Ciclo de 2 Semanas)

El proyecto se gestionará bajo un marco ágil adaptado que consta de los siguientes pilares de sincronización:

```
[Sprint Planning] ──> [Daily Scrum 15 min] ──> [Sprint Review / Delivery]
 (Inicio Ciclo)         (Día a Día Técnico)          (Fin de Ciclo / Demo)
```

1.  **Sprint Planning (Inicio de Ciclo):**
    * *Participantes:* Andrés, Diego, Óscar.
    * *Objetivo:* Seleccionar las historias prioritarias del backlog general, definir el *Sprint Goal* y desglosar las tareas técnicas. Óscar define el *qué*, Andrés y Diego definen el *cómo* y el *cuánto*.
2.  **Daily Scrum Técnico (15 minutos - Días Laborales):**
    * *Participantes:* Andrés y Diego. (Óscar puede asistir de manera opcional en calidad de oyente).
    * *Objetivo:* Sesión síncrona corta enfocada en responder tres ejes:
        1.  ¿Qué construí el día de ayer útil para el sprint?
        2.  ¿En qué voy a trabajar el día de hoy?
        3.  ¿Existe algún impedimento o bloqueo técnico (bloqueos en APIs, Supabase, assets visuales)?
3.  **Sprint Review e Incremento (Fin de Ciclo):**
    * *Participantes:* Andrés, Diego, Óscar.
    * *Objetivo:* Demostración funcional del software operable. No se presentan diapositivas, se valida el incremento real sobre el entorno de desarrollo o staging frente a los criterios de aceptación.

---

## 📋 Estados del Tablero Kanban / Backlog

Las actividades técnicas se clasifican de forma estricta en los siguientes cuatro estados operacionales:

* **🎯 TO DO (Por Hacer):** Tareas priorizadas para el sprint en curso que cuentan con una especificación técnica clara (Spec-Driven). Ningún desarrollador inicia una tarea si no está en este estado con criterios definidos.
* **⚙️ DOING (En Proceso):** Tareas bajo desarrollo activo por parte de Andrés o Diego. Límite máximo de tareas en paralelo (WIP Limit) = 2 por persona para evitar la dispersión de esfuerzos.
* **⏸️ PAUSED (Pausado / Bloqueado):** Tareas detenidas debido a dependencias externas (ej. falta de definición psicométrica por el PO o demoras en la entrega de assets gráficos). Requiere atención inmediata en la Daily.
* **✅ DONE (Terminado):** Tareas que cumplen con la **Definición de Terminado (DoD)**: Código integrado en la rama principal, sin errores de tipado, políticas RLS validadas y aprobado visualmente por diseño.