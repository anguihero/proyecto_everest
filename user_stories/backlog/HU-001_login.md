# [HU-001] Login de Plataforma

---

## 📋 Metadatos

| Campo | Valor |
|-------|-------|
| **ID** | HU-001 |
| **Épica** | Autenticación y Acceso |
| **Sprint** | Sprint 1 |
| **Estado** | TO DO |
| **Prioridad** | Alta |
| **Estimación** | 5 Story Points |
| **Responsable** | Andrés (backend) / Diego (frontend) |
| **Fecha de creación** | 2026-06-22 |
| **Fecha de inicio** | — |
| **Fecha de finalización** | — |

---

## 📖 Historia de Usuario

**Como** líder corporativo (Player, Coach u OrgAdmin),  
**Quiero** ingresar a Everest Experience con mi email corporativo y contraseña,  
**Para** acceder a mi experiencia de desarrollo de liderazgo de forma segura y personalizada.

---

## 🎯 Contexto y Justificación

Es el punto de entrada único a la plataforma. Debe funcionar en el primer intento sin curva de aprendizaje (principio B2B: el usuario no llegó voluntariamente). Si es el primer acceso, dispara un onboarding breve. El rol del usuario (Player / Coach / OrgAdmin) se resuelve en este paso y determina a qué pantalla se redirige.

---

## ✅ Criterios de Aceptación (Gherkin)

### Escenario 1: Login exitoso — usuario existente

```gherkin
DADO que el usuario tiene cuenta activa en Supabase Auth
CUANDO ingresa email corporativo válido y contraseña correcta
  Y hace clic en "Iniciar Sesión"
ENTONCES el sistema autentica vía Supabase Auth
  Y redirige al Hub Central (Player) o Panel de Coach / OrgAdmin según el rol
  Y el estado de sesión se persiste en localStorage
```

### Escenario 2: Primer acceso — onboarding breve

```gherkin
DADO que el usuario se autentica exitosamente por primera vez
CUANDO el sistema detecta que `first_login = true` en su perfil
ENTONCES muestra un modal de onboarding (máx. 60 segundos de lectura)
  Y al cerrarlo marca `first_login = false` y redirige al Hub Central
```

### Escenario 3: Credenciales incorrectas

```gherkin
DADO que el usuario ingresa email o contraseña erróneos
CUANDO hace clic en "Iniciar Sesión"
ENTONCES el sistema muestra el mensaje: "Email o contraseña incorrectos. Intenta de nuevo."
  Y no revela si el email existe o no (prevención de enumeración)
  Y el campo de contraseña se limpia, el de email permanece
```

### Escenario 4: Validación en tiempo real — email mal formado

```gherkin
DADO que el usuario está en el campo de email
CUANDO ingresa un valor sin formato de email válido y pierde el foco del campo
ENTONCES el sistema muestra inline: "Ingresa un email válido"
  Y el botón "Iniciar Sesión" permanece deshabilitado
```

### Escenario 5: Recuperación de contraseña

```gherkin
DADO que el usuario no recuerda su contraseña
CUANDO hace clic en "¿Olvidaste tu contraseña?"
ENTONCES el sistema muestra un campo para ingresar el email
  Y al confirmarlo envía un email de recuperación vía Supabase Auth
  Y muestra: "Revisa tu bandeja. Te enviamos un enlace de recuperación."
```

---

## 🔧 Detalles Técnicos

### Frontend
- **Archivos:** `src/frontend/pages/login.html`, `src/frontend/css/login.css`, `src/frontend/js/auth.js`
- **Componentes:** Formulario de login, Modal de onboarding, Loader animado en botón
- **Estilos:** Inter 14px cuerpo / Inter Bold 32px título; primario `#2E7D32`; error `#D32F2F`; border-radius 4px botón; 0.3s ease transiciones
- **Accesibilidad:** Contraste WCAG AA mínimo; toggle visibilidad contraseña; labels asociados a inputs; responsive desde 320px

### Backend
- **Tablas de Supabase:** `auth.users` (gestionada por Supabase), `profiles` (`id`, `role`, `org_id`, `first_login`, `created_at`)
- **Edge Functions:** —
- **Políticas RLS:** `profiles` → el usuario solo puede leer/actualizar su propio registro (`auth.uid() = id`)
- **APIs externas:** Supabase Auth (email + password, magic link opcional en fase 2)

### Dependencias
- [ ] Tabla `profiles` creada en Supabase con campos `role` y `first_login`
- [ ] Roles definidos en Supabase: `player`, `coach`, `org_admin`, `sys_admin`
- [ ] Assets visuales del login disponibles (logo Everest Experience)

---

## 🧪 Definición de Terminado (DoD)

- [ ] Formulario funcional: email corporativo + contraseña + toggle de visibilidad
- [ ] Validación en tiempo real (email) y botón deshabilitado hasta form válido
- [ ] Autenticación real contra Supabase Auth
- [ ] Redirección por rol post-login
- [ ] Modal de onboarding en primer acceso
- [ ] Flujo de recuperación de contraseña operativo
- [ ] RLS verificada: usuario solo accede a su propio `profile`
- [ ] Probado en Chrome, Firefox, Safari — mobile (375px) y desktop (1280px)
- [ ] Validado visualmente por Diego contra brandbook

---

## 📝 Notas Adicionales

- No mostrar si el email existe al fallar el login (mitiga enumeración de usuarios).
- El logo corporativo del cliente aparece **solo en esta pantalla** (decisión de cliente registrada en contexto).
- SSO corporativo es fase 2; no implementar en MVP.
- El campo de email no se limpia en error para no forzar reescritura al usuario.

---

## 🔗 Referencias

- [Contexto maestro](../../05_context/CONTEXTO_EVEREST_EXPERIENCE.md)
- [Brandbook specs](../../04_sales/GUIA_WORKSHOP_C3_MOCKUP.md#actividad-11-exportar-brandbook-en-formato-estructurado)

---

## 📊 Historial de Cambios

| Fecha | Autor | Cambio Realizado |
|-------|-------|------------------|
| 2026-06-22 | Diego Muñoz | Historia creada |
