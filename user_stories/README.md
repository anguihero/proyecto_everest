# 📚 Sistema de Gestión de Historias de Usuario - Everest Experience

Este directorio contiene todas las historias de usuario (User Stories) del proyecto Everest Experience, organizadas según su estado en el flujo de trabajo Kanban.

---

## 📂 Estructura de Carpetas

```
user_stories/
├── README.md                    # Este archivo
├── INDEX.md                     # Índice maestro de todas las HU
│
├── templates/                   # Plantillas y ejemplos
│   ├── TEMPLATE.md             # Plantilla vacía para nuevas HU
│   └── EXAMPLE.md              # Ejemplo completo (HU-001: Login)
│
├── backlog/                     # HU pendientes por priorizar
│   └── HU-XXX_nombre.md
│
├── in_progress/                 # HU en desarrollo activo
│   └── HU-XXX_nombre.md
│
└── done/                        # HU completadas y validadas
    └── HU-XXX_nombre.md
```

---

## 🎯 Convención de Nombres de Archivos

Todas las historias de usuario siguen el formato:

```
HU-XXX_descripcion_corta.md
```

**Ejemplos:**
- `HU-001_login_empleado.md`
- `HU-002_hub_central_dashboard.md`
- `HU-015_sherpa_chat_npc.md`

**Reglas:**
- **ID numérico secuencial**: HU-001, HU-002, HU-003, etc.
- **Descripción en snake_case**: sin espacios, solo guiones bajos
- **Máximo 50 caracteres**: para legibilidad en listados
- **Descriptivo**: debe ser claro qué hace la HU sin abrirla

---

## ✍️ Cómo Crear una Nueva Historia de Usuario

### Paso 1: Copiar la Plantilla

```bash
# Navega al directorio de user stories
cd user_stories/backlog

# Copia la plantilla con el nuevo nombre
cp ../templates/TEMPLATE.md HU-XXX_descripcion.md
```

### Paso 2: Asignar ID Secuencial

Revisa el archivo `INDEX.md` para ver el último ID asignado y usa el siguiente número disponible.

**Ejemplo:** Si el último ID es HU-012, tu nueva HU será **HU-013**.

### Paso 3: Completar los Campos

Abre el archivo y completa todos los campos de la plantilla:

1. **Metadatos**: ID, épica, sprint, prioridad, responsable, fechas
2. **Historia de Usuario**: Formato "Como... Quiero... Para..."
3. **Contexto**: ¿Por qué es importante esta HU?
4. **Criterios de Aceptación**: Escenarios en formato Gherkin (Given-When-Then)
5. **Detalles Técnicos**: Archivos afectados, tablas, APIs
6. **DoD**: Checklist de definición de terminado
7. **Notas y Referencias**: Información adicional relevante

### Paso 4: Actualizar el Índice

Agrega la nueva HU al archivo `INDEX.md` en la sección correspondiente (por épica o sprint).

### Paso 5: Mover según el Estado

Cuando el estado de la HU cambie, mueve el archivo a la carpeta correspondiente:

```bash
# De backlog a in_progress
mv backlog/HU-XXX_nombre.md in_progress/

# De in_progress a done
mv in_progress/HU-XXX_nombre.md done/
```

---

## 📋 Formato de Historia de Usuario

Todas las HU siguen el formato estándar de ágil:

```
Como [tipo de usuario/rol],
Quiero [realizar una acción/funcionalidad],
Para [obtener un beneficio/valor específico].
```

**Roles típicos en Everest Experience:**
- **Empleado/Jugador**: Usuario final que juega la experiencia Everest
- **Admin de Empresa/CEO**: Gerente que ve reportes consolidados de su organización
- **Coach Consultor**: Psicólogo que analiza resultados psicométricos
- **SysAdmin de Plataforma**: Administrador global del sistema

---

## ✅ Criterios de Aceptación (Gherkin)

Todos los criterios de aceptación se escriben en formato **Gherkin** (Given-When-Then):

```gherkin
DADO [estado inicial del sistema / precondición]
CUANDO [acción ejecutada por el usuario]
ENTONCES [resultado esperado / comportamiento del sistema]
  Y [condición adicional si aplica]
```

**Ejemplo real:**

```gherkin
DADO que el empleado tiene una cuenta activa en la organización "TechCorp"
  Y está en la pantalla de login (/)
CUANDO ingresa su email corporativo "juan.perez@techcorp.com"
  Y ingresa su contraseña correcta "SecurePass123!"
  Y hace clic en el botón "Iniciar Sesión"
ENTONCES el sistema valida las credenciales con Supabase Auth
  Y redirige al empleado a su Hub Central (/dashboard)
  Y muestra un mensaje de bienvenida "¡Hola, Juan! Bienvenido al Everest"
```

### Tipos de Escenarios a Incluir

1. **Escenario Principal (Happy Path)**: Caso ideal sin errores
2. **Escenarios Alternativos**: Variaciones válidas del flujo principal
3. **Casos de Borde**: Situaciones límite (listas vacías, valores máximos)
4. **Validaciones Negativas**: Errores esperados (datos inválidos, permisos insuficientes)

---

## 🧪 Definición de Terminado (DoD)

Cada HU incluye un checklist de DoD que DEBE cumplirse antes de moverla a `done/`:

- [ ] Código implementado y funcional
- [ ] Pruebas unitarias escritas y pasando (si aplica)
- [ ] Validación de RLS en Supabase (para backend)
- [ ] Interfaz validada visualmente por Diego (para frontend)
- [ ] Documentación técnica actualizada
- [ ] Sin errores de tipado o warnings críticos
- [ ] Probado en entorno local / staging
- [ ] Revisión de código completada
- [ ] Integrado en la rama principal

**Importante:** NO marcar una HU como DONE si no cumple TODOS los criterios del DoD.

---

## 🏷️ Épicas del Proyecto Everest Experience

Las historias de usuario se agrupan en las siguientes **épicas** principales:

1. **Autenticación y Gestión de Usuarios**
   - Login, registro, recuperación de contraseña
   - Gestión de perfiles y roles

2. **Hub Central y Dashboard**
   - Visualización de perfil del jugador
   - Inventario de avatar y medallas
   - Progreso global en la plataforma

3. **Experiencia del Juego Everest**
   - Renderizado del mapa de montaña
   - Rutas y decisiones de opción múltiple
   - Motor de guardado de partidas

4. **Sherpa NPC (Agente de IA)**
   - Chat conversacional con Gemini API
   - Guardrails de seguridad y privacidad
   - Feedback en tiempo real

5. **Panel Admin de Empresa**
   - Reportes analíticos consolidados
   - Gestión de empleados de la organización
   - Parametrización de reglas del juego

6. **Panel del Coach Consultor**
   - Análisis psicométrico cruzado
   - Planes de acción grupales
   - Exportación de reportes

7. **Panel SysAdmin de Plataforma**
   - Gestión multi-tenancy
   - Licenciamiento de empresas
   - Monitoreo del sistema

---

## 🔄 Flujo de Trabajo con Historias de Usuario

### 1. Sprint Planning (Inicio de Sprint)

1. El Product Owner (Óscar) prioriza las HU del `backlog/`
2. El equipo (Andrés + Diego) estima Story Points
3. Se seleccionan las HU para el sprint actual
4. Las HU seleccionadas permanecen en `backlog/` hasta que se inicia el trabajo

### 2. Durante el Sprint

1. El desarrollador mueve la HU de `backlog/` a `in_progress/`
2. Actualiza el campo `Estado: DOING` en el archivo
3. Actualiza `Fecha de inicio` en los metadatos
4. Trabaja en la implementación siguiendo los criterios de aceptación

### 3. Revisión y Validación

1. Al completar la implementación, verifica el checklist de DoD
2. Solicita revisión de código a otro miembro del equipo
3. Diego valida visualmente (si es frontend)
4. Andrés valida RLS y seguridad (si es backend)

### 4. Completado (Done)

1. Si pasa TODOS los criterios del DoD, mueve la HU a `done/`
2. Actualiza el campo `Estado: DONE` en el archivo
3. Actualiza `Fecha de finalización` en los metadatos
4. Actualiza el `INDEX.md` con el estado final

---

## 📊 Estimación de Story Points

Usamos la escala de Fibonacci para estimar complejidad:

| Story Points | Complejidad | Horas Aprox. | Ejemplos |
|:------------:|-------------|:------------:|----------|
| **1** | Trivial | 1-2h | Cambio de texto, ajuste CSS menor |
| **2** | Pequeña | 2-4h | Componente simple, formulario básico |
| **3** | Moderada | 4-8h | Login con validaciones, integración API |
| **5** | Media | 8-12h | Dashboard con múltiples widgets |
| **8** | Alta | 12-20h | Motor del juego Everest, Sherpa NPC |
| **13** | Muy Alta | 20-32h | Panel Admin completo, sistema de analytics |
| **21** | Épica | 32+h | Dividir en HU más pequeñas |

**Regla:** Si una HU es 13+ Story Points, considerar dividirla en historias más pequeñas.

---

## 🚦 Indicadores de Estado

Cada HU puede estar en uno de estos estados:

| Estado | Carpeta | Significado |
|--------|---------|-------------|
| **TO DO** | `backlog/` | Priorizada pero no iniciada |
| **DOING** | `in_progress/` | En desarrollo activo |
| **PAUSED** | `in_progress/` | Bloqueada por dependencias |
| **DONE** | `done/` | Completada y validada |

**Límite WIP (Work In Progress):** Máximo 2 HU por persona en estado DOING simultáneamente.

---

## 🔗 Referencias

- [Documentación Ágil del Proyecto](../docs/01_planning/agile_dynamics_workflow.md)
- [Cronograma Gantt](../docs/01_planning/project_gantt_plan.md)
- [Matriz RACI](../docs/02_governance/roles_raci_matrix.md)
- [Plantilla Vacía](templates/TEMPLATE.md)
- [Ejemplo Completo](templates/EXAMPLE.md)

---

## ❓ Preguntas Frecuentes

### ¿Cuándo crear una nueva HU?

Crea una nueva HU cuando:
- Se identifica una funcionalidad claramente delimitada
- Tiene valor entregable para el usuario final
- Puede completarse dentro de un sprint (2 semanas)
- Tiene criterios de aceptación verificables

### ¿Cómo sé si mi HU es demasiado grande?

Si la HU:
- Requiere más de 13 Story Points
- Afecta múltiples épicas
- Toma más de 1 sprint completarla
- Tiene más de 10 criterios de aceptación

**→ Divídela en HU más pequeñas.**

### ¿Qué hago si mi HU se bloquea?

1. Cambia el estado a `PAUSED` en el archivo
2. Documenta el bloqueo en "Notas Adicionales"
3. Menciona el bloqueo en el Daily Scrum
4. Si el bloqueo es externo, notifica al PO (Óscar)

### ¿Puedo modificar una HU después de crearla?

Sí, las HU son documentos vivos. Actualiza la sección "Historial de Cambios" cada vez que modifiques algo significativo.

---

**Última actualización:** 2026-06-07  
**Responsable del sistema:** Andrés Muñoz Sánchez (Tech Lead)
