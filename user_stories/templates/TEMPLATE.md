# [ID-HU-XXX] Título de la Historia de Usuario

---

## 📋 Metadatos

| Campo | Valor |
|-------|-------|
| **ID** | HU-XXX |
| **Épica** | [Nombre de la épica] |
| **Sprint** | Sprint X |
| **Estado** | TO DO / DOING / PAUSED / DONE |
| **Prioridad** | Alta / Media / Baja |
| **Estimación** | X Story Points / X horas |
| **Responsable** | Andrés / Diego / Equipo |
| **Fecha de creación** | YYYY-MM-DD |
| **Fecha de inicio** | YYYY-MM-DD |
| **Fecha de finalización** | YYYY-MM-DD |

---

## 📖 Historia de Usuario

**Como** [tipo de usuario/rol],  
**Quiero** [realizar una acción/funcionalidad],  
**Para** [obtener un beneficio/valor específico].

---

## 🎯 Contexto y Justificación

[Descripción detallada del problema o necesidad que esta historia resuelve. Incluye el contexto de negocio, antecedentes técnicos y por qué es importante para el proyecto Everest Experience.]

---

## ✅ Criterios de Aceptación (Gherkin)

### Escenario 1: [Nombre del escenario principal]

```gherkin
DADO [estado inicial del sistema / precondición]
CUANDO [acción ejecutada por el usuario]
ENTONCES [resultado esperado / comportamiento del sistema]
  Y [condición adicional si aplica]
```

### Escenario 2: [Nombre del escenario alternativo]

```gherkin
DADO [estado inicial del sistema / precondición]
CUANDO [acción ejecutada por el usuario]
ENTONCES [resultado esperado / comportamiento del sistema]
```

### Escenario 3: [Caso de borde / validación negativa]

```gherkin
DADO [estado inicial del sistema / precondición]
CUANDO [acción ejecutada por el usuario]
ENTONCES [resultado esperado / mensaje de error]
```

---

## 🔧 Detalles Técnicos

### Frontend
- **Archivos afectados:** `[ruta/archivo.js]`
- **Componentes:** `[Componente1, Componente2]`
- **Estilos:** `[Tailwind classes / Custom CSS]`

### Backend
- **Tablas de Supabase:** `[tabla1, tabla2]`
- **Edge Functions:** `[función1, función2]`
- **Políticas RLS:** `[política de seguridad]`
- **APIs externas:** `[Gemini API / Otras]`

### Dependencias
- [ ] Historia de usuario HU-XXX debe estar completa
- [ ] Assets visuales deben estar disponibles
- [ ] Tabla X en Supabase debe estar creada

---

## 🧪 Definición de Terminado (DoD)

- [ ] Código implementado y funcional
- [ ] Pruebas unitarias escritas y pasando (si aplica)
- [ ] Validación de RLS en Supabase (para backend)
- [ ] Interfaz validada visualmente por Diego (para frontend)
- [ ] Documentación técnica actualizada (README o comentarios)
- [ ] Sin errores de tipado o warnings críticos
- [ ] Probado en entorno local / staging
- [ ] Revisión de código completada
- [ ] Integrado en la rama principal (main/develop)

---

## 📝 Notas Adicionales

[Cualquier información relevante adicional: decisiones técnicas tomadas, bloqueos encontrados, referencias a documentación externa, enlaces a diseños en Figma, etc.]

---

## 🔗 Referencias

- [Enlace a diseño en Figma/Sketch]
- [Enlace a documentación técnica]
- [Enlace a issue en GitHub]
- [Enlace a especificación de API]

---

## 📊 Historial de Cambios

| Fecha | Autor | Cambio Realizado |
|-------|-------|------------------|
| YYYY-MM-DD | [Nombre] | Historia creada |
| YYYY-MM-DD | [Nombre] | [Descripción del cambio] |
