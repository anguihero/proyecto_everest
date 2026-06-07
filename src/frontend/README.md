# Frontend - Everest Experience

Esta carpeta contendrá el código fuente del cliente web de la aplicación.

## Tecnologías Planificadas

- **HTML5**: Estructura semántica de la aplicación
- **JavaScript** (Vanilla o framework liviano): Lógica del cliente y gestión de estado
- **CSS/Tailwind**: Estilos y diseño responsive
- **Assets**: Sprites, ilustraciones del Everest, avatares, medallas

## Componentes Principales a Desarrollar

1. **Módulo de Autenticación**: Login corporativo integrado con Supabase Auth
2. **Hub Central/Dashboard**: Perfil de usuario, progreso, inventario de avatar
3. **Motor del Juego Everest**: Renderizado del mapa, rutas, modalidades de decisión
4. **Interfaz del Sherpa NPC**: Chat conversacional con el agente de IA
5. **Panels Administrativos**: 
   - Panel Admin de Empresa (CEO/HR)
   - Panel del Coach
   - Panel SysAdmin

## Estructura Propuesta

```
frontend/
├── index.html              # Punto de entrada
├── assets/
│   ├── images/            # Sprites, avatares, medallas
│   ├── styles/            # CSS/Tailwind
│   └── audio/             # Efectos de sonido (opcional)
├── components/
│   ├── auth/              # Login, registro
│   ├── dashboard/         # Hub central
│   ├── game/              # Motor del Everest
│   ├── sherpa/            # NPC conversacional
│   └── admin/             # Panels administrativos
├── utils/
│   ├── api.js             # Cliente de Supabase
│   ├── state.js           # Gestión de estado del juego
│   └── validators.js      # Validaciones del cliente
└── config/
    └── supabase.js        # Configuración de conexión
```

---

**Estado:** Carpeta reservada para desarrollo futuro  
**Responsables:** Andrés Muñoz (Full Stack), Diego (UI/UX)
