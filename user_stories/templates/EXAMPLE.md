# [HU-001] Autenticación de Empleado con Credenciales Corporativas

---

## 📋 Metadatos

| Campo | Valor |
|-------|-------|
| **ID** | HU-001 |
| **Épica** | Autenticación y Gestión de Usuarios |
| **Sprint** | Sprint 3 |
| **Estado** | TO DO |
| **Prioridad** | Alta |
| **Estimación** | 8 Story Points / 12 horas |
| **Responsable** | Andrés (Backend + Integración), Diego (UI) |
| **Fecha de creación** | 2026-06-07 |
| **Fecha de inicio** | - |
| **Fecha de finalización** | - |

---

## 📖 Historia de Usuario

**Como** empleado de una organización cliente,  
**Quiero** autenticarme en la plataforma Everest Experience utilizando mis credenciales corporativas,  
**Para** acceder a mi perfil, iniciar partidas del juego psicométrico y visualizar mi progreso personal de manera segura.

---

## 🎯 Contexto y Justificación

La autenticación es el punto de entrada crítico para la plataforma. Cada empleado debe acceder de forma segura utilizando su email corporativo, asegurando que:

1. **Seguridad Multi-Tenant**: Los empleados solo pueden ver datos de su propia organización (RLS en Supabase).
2. **Trazabilidad**: Cada sesión de juego queda vinculada al usuario autenticado para análisis psicométrico.
3. **Compliance**: Cumplir con Habeas Data (Ley 1581) mediante autenticación verificable.

Esta historia es **bloqueante** para todas las funcionalidades posteriores del Everest Experience, ya que sin autenticación no hay acceso al Hub Central, al juego ni a los paneles administrativos.

---

## ✅ Criterios de Aceptación (Gherkin)

### Escenario 1: Login exitoso con credenciales válidas

```gherkin
DADO que el empleado tiene una cuenta activa en la organización "TechCorp"
  Y está en la pantalla de login (/)
CUANDO ingresa su email corporativo "juan.perez@techcorp.com"
  Y ingresa su contraseña correcta "SecurePass123!"
  Y hace clic en el botón "Iniciar Sesión"
ENTONCES el sistema valida las credenciales con Supabase Auth
  Y redirige al empleado a su Hub Central (/dashboard)
  Y muestra un mensaje de bienvenida "¡Hola, Juan! Bienvenido al Everest"
  Y carga su información de perfil (nombre, avatar, progreso)
```

### Escenario 2: Login fallido por credenciales incorrectas

```gherkin
DADO que el empleado está en la pantalla de login (/)
CUANDO ingresa su email "juan.perez@techcorp.com"
  Y ingresa una contraseña incorrecta "WrongPassword"
  Y hace clic en el botón "Iniciar Sesión"
ENTONCES el sistema muestra un mensaje de error "Email o contraseña incorrectos"
  Y NO permite el acceso al sistema
  Y limpia el campo de contraseña por seguridad
  Y mantiene el email ingresado en el campo
```

### Escenario 3: Login con email no registrado

```gherkin
DADO que el empleado está en la pantalla de login (/)
CUANDO ingresa un email no registrado "noexiste@empresa.com"
  Y ingresa cualquier contraseña
  Y hace clic en el botón "Iniciar Sesión"
ENTONCES el sistema muestra un mensaje de error "Email o contraseña incorrectos"
  Y NO revela si el email existe o no (seguridad)
  Y registra el intento fallido en los logs de auditoría
```

### Escenario 4: Validación de formato de email

```gherkin
DADO que el empleado está en la pantalla de login (/)
CUANDO ingresa un texto que no es un email válido "juan.perez"
  Y intenta hacer clic en el botón "Iniciar Sesión"
ENTONCES el sistema muestra un error de validación "Ingresa un email válido"
  Y deshabilita el botón de login hasta que el formato sea correcto
```

### Escenario 5: Sesión persistente (Remember Me)

```gherkin
DADO que el empleado se ha autenticado exitosamente
  Y ha marcado la opción "Recordar sesión"
CUANDO cierra el navegador
  Y regresa al sitio después de 3 días
ENTONCES el sistema mantiene la sesión activa
  Y redirige automáticamente al Hub Central
  Y NO solicita nuevamente las credenciales
```

### Escenario 6: Cierre de sesión manual

```gherkin
DADO que el empleado está autenticado y en su Hub Central
CUANDO hace clic en el botón "Cerrar Sesión"
ENTONCES el sistema invalida el token de sesión en Supabase
  Y redirige al empleado a la pantalla de login (/)
  Y muestra un mensaje "Sesión cerrada exitosamente"
  Y limpia todos los datos de sesión del navegador
```

---

## 🔧 Detalles Técnicos

### Frontend
- **Archivos afectados:** 
  - `src/frontend/components/auth/Login.js`
  - `src/frontend/components/auth/LoginForm.js`
  - `src/frontend/utils/validators.js`
  - `src/frontend/config/supabase.js`
- **Componentes:** 
  - `<LoginPage>`: Página principal de autenticación
  - `<LoginForm>`: Formulario con campos de email y password
  - `<ErrorMessage>`: Componente para mostrar errores de validación
- **Estilos:** 
  - Tailwind CSS con paleta corporativa del brandbook
  - Diseño responsive (mobile-first)
  - Animaciones de carga durante autenticación

### Backend
- **Tablas de Supabase:** 
  - `users`: Tabla principal de usuarios (email, password_hash, organization_id)
  - `organizations`: Tabla de organizaciones cliente (multi-tenant)
  - `audit_logs`: Registro de intentos de login para compliance
- **Edge Functions:** 
  - No requerida inicialmente (Supabase Auth maneja la autenticación)
  - Futura: `validate-corporate-email` para verificar dominios corporativos
- **Políticas RLS:** 
  ```sql
  -- Solo el usuario puede ver su propio registro
  CREATE POLICY "users_select_own" ON users
    FOR SELECT USING (auth.uid() = id);
  
  -- Solo usuarios de la misma organización pueden verse entre sí
  CREATE POLICY "users_select_org" ON users
    FOR SELECT USING (
      organization_id = (
        SELECT organization_id FROM users WHERE id = auth.uid()
      )
    );
  ```
- **APIs externas:** 
  - Supabase Auth API (integrada)

### Dependencias
- [x] Proyecto de Supabase creado y configurado
- [ ] Tabla `users` creada con esquema completo
- [ ] Tabla `organizations` creada
- [ ] RLS habilitado en Supabase
- [ ] Assets visuales del login (logo, fondos) disponibles
- [ ] Brandbook con paleta cromática definido

---

## 🧪 Definición de Terminado (DoD)

- [ ] Código del formulario de login implementado en `src/frontend/components/auth/Login.js`
- [ ] Integración con Supabase Auth completada y probada
- [ ] Validaciones del lado del cliente implementadas (formato de email, campos requeridos)
- [ ] Manejo de errores con mensajes amigables al usuario
- [ ] Políticas RLS configuradas y validadas en Supabase
- [ ] Sesión persistente ("Remember Me") funcional
- [ ] Cierre de sesión manual funcional
- [ ] Redirecciones correctas (login → dashboard, logout → login)
- [ ] Diseño responsive validado en mobile, tablet y desktop
- [ ] Interfaz validada visualmente por Diego (brandbook aplicado)
- [ ] Sin errores de consola en navegador
- [ ] Registro de audit_logs en intentos fallidos funcional
- [ ] Probado con usuarios de diferentes organizaciones (multi-tenancy)
- [ ] Revisión de código completada por Andrés
- [ ] Integrado en rama `develop`

---

## 📝 Notas Adicionales

### Consideraciones de Seguridad
- **Hashing de contraseñas**: Supabase Auth maneja automáticamente con bcrypt
- **Rate limiting**: Configurar límite de 5 intentos fallidos por minuto por IP
- **HTTPS obligatorio**: SSL nativo de Vercel/Netlify
- **Tokens JWT**: Expiración de 24 horas, renovación automática

### Decisiones Técnicas
1. **Supabase Auth vs. Custom Auth**: Se decidió usar Supabase Auth para reducir complejidad y aprovechar seguridad nativa.
2. **Remember Me**: Se implementa mediante configuración de `persistSession: true` en Supabase Client.
3. **Auditoría**: Los intentos fallidos se registran en `audit_logs` para compliance con Habeas Data.

### Bloqueos Potenciales
- Esperar aprobación del brandbook para colores y tipografía del login
- Coordinación con Diego para assets visuales del fondo de login
- Definición de política de contraseñas corporativas (longitud mínima, caracteres especiales)

---

## 🔗 Referencias

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Documento de Gobernanza: Legal Compliance](docs/02_governance/legal_compliance_ip.md)
- [Matriz RACI del Proyecto](docs/02_governance/roles_raci_matrix.md)
- Diseño en Figma: [Pendiente por Diego]

---

## 📊 Historial de Cambios

| Fecha | Autor | Cambio Realizado |
|-------|-------|------------------|
| 2026-06-07 | Andrés | Historia creada como ejemplo de plantilla |
| 2026-06-07 | Andrés | Agregados criterios de aceptación con Gherkin |
| 2026-06-07 | Andrés | Definidas políticas RLS preliminares |
