# Backend - Everest Experience (Supabase)

Esta carpeta contendrá el código de la lógica de backend, Edge Functions de Supabase y scripts de configuración de la base de datos.

## Infraestructura

**Platform as a Service:** Supabase (PostgreSQL + Auth + RLS + Realtime + Storage)

## Componentes Principales a Desarrollar

### 1. Esquema de Base de Datos

**Tablas principales:**
- `organizations`: Empresas clientes (multi-tenant)
- `users`: Empleados/Jugadores, Coaches, Admins
- `game_sessions`: Partidas activas del Everest
- `game_progress`: Estado de progreso por usuario
- `decisions`: Registro de decisiones tomadas en el juego
- `psychometric_results`: Resultados agregados de tests
- `achievements`: Medallas y logros desbloqueados
- `avatar_inventory`: Ítems y customizaciones del avatar
- `sherpa_conversations`: Historial de chat con el NPC

### 2. Row Level Security (RLS)

Políticas de seguridad por rol:
- **Jugador**: Solo puede ver/modificar sus propios datos
- **Admin de Empresa**: Ve agregados de su organización
- **Coach**: Accede a reportes consolidados de sus clientes asignados
- **SysAdmin**: Gestión global de la plataforma

### 3. Edge Functions

- `sherpa-chat`: Endpoint seguro para consultas al agente Gemini con Guardrails
- `analytics-report`: Generación de reportes psicométricos agregados
- `achievement-unlock`: Lógica de desbloqueo de medallas y recompensas
- `session-save`: Guardado automático del estado de la partida

### 4. Triggers y Funciones PostgreSQL

- `calculate_psychometric_score`: Función para calcular puntajes basados en decisiones
- `update_achievement_progress`: Trigger para actualizar progreso de logros
- `audit_log`: Registro de accesos a datos sensibles para compliance

### 5. Integración con Gemini API

**Guardrails de Seguridad:**
- Validación de prompts del sistema para prevenir data leakage
- Anonimización de contexto organizacional en consultas
- Rate limiting por organización
- Filtrado de respuestas para contenido no ético

## Estructura Propuesta

```
backend/
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   └── 003_triggers_functions.sql
│   ├── functions/
│   │   ├── sherpa-chat/
│   │   │   └── index.ts
│   │   ├── analytics-report/
│   │   │   └── index.ts
│   │   └── achievement-unlock/
│   │       └── index.ts
│   └── seed/
│       └── test_data.sql
├── scripts/
│   ├── deploy.sh              # Script de despliegue
│   └── setup_local.sh         # Configuración local
└── config/
    ├── supabase.config.json   # Configuración del proyecto
    └── gemini.config.json     # Configuración de Gemini API
```

## Seguridad y Compliance

- ✅ **RLS habilitado** en todas las tablas con datos sensibles
- ✅ **Cifrado en reposo** (nativo de Supabase)
- ✅ **Auditoría de accesos** para compliance Habeas Data
- ✅ **Seudonimización** de IDs de empleados en logs
- ✅ **Guardrails en Gemini** para prevenir cross-tenant leakage

## Variables de Entorno Requeridas

```bash
# Supabase
SUPABASE_URL=https://[project-id].supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Gemini API
GEMINI_API_KEY=AI...
GEMINI_MODEL=gemini-pro
GEMINI_MAX_TOKENS=2048

# Configuración
ENVIRONMENT=production|staging|development
```

---

**Estado:** Carpeta reservada para desarrollo futuro  
**Responsable:** Andrés Muñoz Sánchez (Líder Técnico)
