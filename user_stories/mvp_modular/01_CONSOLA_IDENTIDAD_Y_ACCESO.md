# Épica CA — Consola: identidad, acceso y operación por rol

**Objetivo:** Proveer una entrada segura, privada y diferenciada a la consola.  
**Dependencias externas:** Decisiones `DEC-P-03`, `DEC-P-04` y políticas de tratamiento de datos.

---

## HU-CA-001 — Autenticación y recuperación segura

**Tipo:** Funcional + UX + técnica  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Frontend + Backend  
**Trazabilidad:** RF-ID-01, RF-ID-02, RT-01, RS-SEC-05

**Como** usuario registrado, **quiero** autenticarme y recuperar mi contraseña, **para** acceder de forma segura sin depender de soporte.

### Criterios de aceptación

```gherkin
Escenario: Login exitoso
  DADO un usuario activo con credenciales válidas
  CUANDO inicia sesión
  ENTONCES Supabase Auth crea una sesión segura
  Y la consola solicita su perfil y destino por rol

Escenario: Credenciales inválidas
  DADO un intento con email o contraseña incorrectos
  CUANDO el proveedor rechaza la autenticación
  ENTONCES se muestra un mensaje genérico
  Y no se confirma si el email existe

Escenario: Recuperación
  DADO un usuario que olvidó su contraseña
  CUANDO solicita recuperación con un email válido
  ENTONCES recibe siempre una confirmación neutral
  Y Supabase procesa el envío cuando la cuenta aplica
```

### UX

- Labels visibles, validación inline, foco en primer error y toggle accesible de contraseña.
- Estados: enviando, error, éxito, sesión expirada y demasiados intentos.
- Operable desde 320 px y por teclado.

### Técnica, datos y seguridad

- Supabase Auth; sesión persistida mediante su cliente oficial, no tokens propios.
- Rate limiting y mensajes anti-enumeración.
- No registrar email, contraseña ni tokens en logs.

### Dependencias y DoD específico

- Configuración de Auth y URLs de recuperación.
- Pruebas de login, logout, expiración, recuperación y enumeración.

---

## HU-CA-002 — Resolución de organización, rol y autorización

**Tipo:** Habilitadora técnica + seguridad  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsable:** Backend  
**Trazabilidad:** RF-ID-03, RT-02, RS-SEC-01, RS-SEC-02

**Como** propietario de la plataforma, **quiero** que cada sesión resuelva organización y permisos, **para** impedir acceso a datos o funciones no autorizadas.

### Criterios de aceptación

```gherkin
Escenario: Acceso permitido
  DADO un usuario activo con rol asignado en una organización
  CUANDO solicita un recurso permitido
  ENTONCES el backend valida user_id, org_id y permiso
  Y entrega únicamente filas autorizadas por RLS

Escenario: Acceso cruzado
  DADO un usuario de la organización A
  CUANDO intenta consultar un identificador de la organización B
  ENTONCES la operación no entrega información
  Y registra un evento de seguridad sin datos sensibles

Escenario: Rol modificado
  DADO un usuario cuya asignación fue inactivada
  CUANDO realiza una nueva operación protegida
  ENTONCES se aplica el permiso vigente
  Y el cliente redirige a una vista segura
```

### UX

- Rutas no autorizadas muestran explicación breve y salida segura.
- La interfaz oculta acciones no aplicables, pero nunca sustituye autorización backend.

### Técnica, datos y seguridad

- Entidades `organizations`, `profiles`, `role_assignments`.
- Políticas RLS explícitas por operación y pruebas con cuentas cross-tenant.
- Roles provisionales: player, coach, org_admin, support y sys_admin; sujetos a decisiones.

### Dependencias y DoD específico

- `DEC-P-03` y `DEC-P-04`.
- Matriz de permisos aprobada y suite RLS pasando para cada rol.

---

## HU-CA-003 — Consentimiento informado y versionado

**Tipo:** Funcional + UX + legal  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Gobierno + UX + Backend  
**Trazabilidad:** RF-PR-01, RF-PR-02

**Como** jugador, **quiero** conocer y aceptar el uso de mis datos antes de participar, **para** decidir de manera informada.

### Criterios de aceptación

```gherkin
Escenario: Consentimiento requerido
  DADO un usuario sin consentimiento vigente
  CUANDO intenta iniciar una experiencia
  ENTONCES conoce finalidad, datos, IA, visibilidad, retención y derechos
  Y no puede iniciar hasta aceptar las finalidades obligatorias

Escenario: Evidencia
  DADO que el usuario acepta
  CUANDO confirma la decisión
  ENTONCES se registra versión, fecha, finalidad y usuario
  Y se permite iniciar la experiencia

Escenario: Nueva versión material
  DADO un consentimiento anterior y una política con cambio material
  CUANDO el usuario vuelve a una función afectada
  ENTONCES se solicita una nueva aceptación
```

### UX

- Resumen legible y acceso al texto completo.
- Casillas separadas cuando existan finalidades opcionales.
- No usar casillas premarcadas ni consentimiento oscuro.

### Técnica, datos y seguridad

- `consent_records` inmutables; no almacenar solo un booleano.
- La versión aceptada debe vincularse a la sesión de experiencia.

### Dependencias y DoD específico

- Texto aprobado por Gobierno.
- Pruebas de versión vigente, rechazo, reconsentimiento y auditoría.

---

## HU-CA-004 — Perfil y configuración básica

**Tipo:** Funcional + UX  
**Prioridad:** Must · **Estimación:** 3 SP · **Responsables:** Frontend + Backend  
**Trazabilidad:** RF-ID-04

**Como** usuario, **quiero** consultar y actualizar mis preferencias básicas, **para** mantener mi cuenta y experiencia personalizadas.

### Criterios de aceptación

```gherkin
Escenario: Consulta
  DADO un usuario autenticado
  CUANDO abre Configuración
  ENTONCES ve nombre preferido, preferencias permitidas, organización y rol
  Y los campos no editables se distinguen claramente

Escenario: Actualización válida
  DADO cambios válidos en campos editables
  CUANDO guarda
  ENTONCES se persisten únicamente en su perfil
  Y recibe confirmación accesible

Escenario: Cambio inválido
  DADO un valor fuera de las reglas
  CUANDO intenta guardar
  ENTONCES se conserva el formulario
  Y se indica cómo corregirlo
```

### UX

- Configuración mínima; sin avatar avanzado ni preferencias especulativas.
- Estados guardando, guardado y error; aviso de cambios sin guardar.

### Técnica, datos y seguridad

- El usuario no puede modificar `org_id`, roles ni consentimientos desde esta vista.
- RLS `auth.uid() = profile.id`.

### Dependencias y DoD específico

- HU-CA-001 y HU-CA-002.
- Pruebas de actualización propia y bloqueo de campos privilegiados.

---

## HU-CA-005 — Hub y catálogo personal de experiencias

**Tipo:** Funcional + UX  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsable:** Frontend  
**Trazabilidad:** RF-EX-01

**Como** jugador, **quiero** ver las experiencias que tengo asignadas, **para** iniciar o continuar la expedición adecuada.

### Criterios de aceptación

```gherkin
Escenario: Catálogo
  DADO un jugador con casetes asignados
  CUANDO entra al Hub
  ENTONCES ve nombre, propósito, duración y estado de cada casete
  Y dispone de un CTA coherente: iniciar, continuar o ver resultado

Escenario: Sin asignaciones
  DADO un jugador sin casetes
  CUANDO entra al Hub
  ENTONCES ve un estado vacío explicativo
  Y no se muestran tarjetas o métricas falsas

Escenario: Versión no disponible
  DADO una asignación cuyo casete ya no puede iniciarse
  CUANDO se carga el Hub
  ENTONCES se explica su indisponibilidad
  Y una sesión histórica terminada sigue accesible
```

### UX

- Un CTA principal por tarjeta, progreso textual y visual, sin rankings.
- Diferenciar claramente exploración y simulación.
- Primera carga útil <3 s según condiciones acordadas.

### Técnica, datos y seguridad

- Consultar `experience_assignments`, versión publicada y última sesión autorizada.
- No enviar definiciones completas de casetes en el listado.

### Dependencias y DoD específico

- HU-CA-002, HU-CM-001 y HU-CM-002.
- Estados vacío, error, carga y acceso probados.

---

## HU-CA-006 — Onboarding inicial de la consola

**Tipo:** UX + funcional  
**Prioridad:** Must · **Estimación:** 3 SP · **Responsable:** UX/Frontend  
**Trazabilidad:** RX-01

**Como** usuario en su primer acceso, **quiero** comprender la metáfora y el funcionamiento, **para** comenzar sin capacitación externa.

### Criterios de aceptación

```gherkin
Escenario: Primer acceso
  DADO un usuario que no completó onboarding
  CUANDO accede a la consola
  ENTONCES conoce en menos de 60 segundos qué hará, qué no mide el sistema y cómo se guardará
  Y puede continuar al Hub

Escenario: Acceso posterior
  DADO un usuario con onboarding completo
  CUANDO inicia sesión nuevamente
  ENTONCES no se bloquea con el onboarding
  Y puede consultarlo desde Ayuda
```

### UX

- Máximo tres pasos, lenguaje profesional, controles de avanzar/saltar accesibles.
- Sin carrusel automático ni animaciones obligatorias.

### Técnica, datos y seguridad

- Guardar versión de onboarding completada, no solo `first_login`.
- No mezclar aceptación legal con el onboarding narrativo.

### Dependencias y DoD específico

- Guía de tono aprobada y HU-CA-001.
- Prueba de comprensión con usuarios.

---

## HU-CA-007 — Gestión organizacional de usuarios

**Tipo:** Funcional + administrativa  
**Prioridad:** Must · **Estimación:** 8 SP · **Responsables:** Frontend + Backend  
**Trazabilidad:** RF-ID-05

**Como** OrgAdmin, **quiero** crear y gestionar usuarios de mi organización, **para** controlar quién participa en las experiencias.

### Criterios de aceptación

```gherkin
Escenario: Alta
  DADO un OrgAdmin autenticado
  CUANDO registra un usuario válido con rol permitido
  ENTONCES se crea o invita dentro de su organización
  Y la acción queda auditada

Escenario: Inactivación
  DADO un usuario activo de su organización
  CUANDO el OrgAdmin confirma inactivarlo
  ENTONCES se bloquean nuevos accesos
  Y se conservan datos según la política de retención

Escenario: Intento cross-tenant
  DADO un identificador de otra organización
  CUANDO el OrgAdmin intenta modificarlo
  ENTONCES la operación es rechazada sin revelar datos
```

### UX

- Tabla accesible con búsqueda y estados; confirmación para acciones destructivas.
- Soft delete/inactivación como operación habitual.

### Técnica, datos y seguridad

- Creación privilegiada desde Edge Function; nunca con service key en cliente.
- El OrgAdmin no puede asignar roles globales o de soporte.

### Dependencias y DoD específico

- HU-CA-002 y matriz de roles aprobada.
- Pruebas RLS, auditoría e invitación.

---

## HU-CA-008 — Asignación y seguimiento operativo

**Tipo:** Funcional + administrativa  
**Prioridad:** Must · **Estimación:** 5 SP · **Responsables:** Frontend + Backend  
**Trazabilidad:** RF-AD-01, RF-AD-02

**Como** OrgAdmin, **quiero** asignar casetes y consultar avance, **para** operar un programa sin acceder a respuestas privadas.

### Criterios de aceptación

```gherkin
Escenario: Asignar experiencia
  DADO usuarios activos y un casete publicable para la organización
  CUANDO el OrgAdmin confirma la asignación
  ENTONCES se crean asignaciones sin sesiones duplicadas
  Y los jugadores lo ven en su Hub

Escenario: Consultar avance
  DADO asignaciones de su organización
  CUANDO abre seguimiento
  ENTONCES ve no iniciada, en progreso o completada y fechas operativas
  Y no ve respuestas, chats ni inferencias individuales

Escenario: Reasignación
  DADO una asignación existente
  CUANDO intenta repetirla
  ENTONCES el sistema evita duplicados
  Y explica el estado actual
```

### UX

- Selección masiva controlada, resumen antes de confirmar y resultado por usuario.
- Filtros por estado y cohorte; sin ranking.

### Técnica, datos y seguridad

- `experience_assignments` con restricción de unicidad definida.
- Consultas limitadas al `org_id`; eventos de asignación auditados.

### Dependencias y DoD específico

- HU-CA-007, HU-CM-002 y HU-FB-005.
- Pruebas de asignación única y privacidad del seguimiento.

