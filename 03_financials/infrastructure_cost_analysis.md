# 3. Análisis Financiero: Presupuesto Total de Infraestructura, Diseño y Desarrollo

El presente documento detalla la estimación de costos asociados al ciclo de vida del software para un horizonte de proyección de 1 y 3 años. Este análisis separa los gastos únicos por desarrollo de software de los costos operativos fijos por arrendamiento de servicios Cloud.

## 💰 Resumen Consolidado de Costos (Moneda de Referencia: COP)

| Componente | Tipo de Gasto | Costo Mensual | Costo Año 1 | Costo Acumulado 3 Años | Notas Técnicas |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Desarrollo de Software** | Recurrente (Mensual) | $1.400.000 | $5.600.000 | $5.600.000 | Honorarios del equipo de desarrollo e ingeniería. Modelo ágil: $1.400.000 COP/mes. MVP = 4 meses. Futuros desarrollos siguen el mismo tabulador. |
| **Infraestructura Cloud (Supabase)**| Recurrente (SaaS) | $100.000* | $0 - $1.200.000** | $3.600.000 | Plan Pro: $100.000 COP/mes. Año 1 con Free Tier ($0). Años 2-3 con plan Pro. |
| **Consumo de APIs de IA (Gemini)** | Recurrente (Uso) | $40.000 | $480.000 | $1.440.000 | Estimado en base a tokens consumidos ($40.000 COP/mes) con Guardrails activos. |
| **Hosting Frontend y Dominios** | Recurrente (Anual) | $12.500 | $150.000 | $450.000 | Dominio `.com` o `.co` + Hosting estático administrado (Vercel/Netlify). |
| **Soporte y Mantenimiento** | Recurrente (Anual) | $0 / $62.500*** | $0 | $1.500.000 | Garantía incluida el Año 1 ($0). Mantenimiento preventivo Años 2-3 ($750.000/año). |
| **TOTAL ESTIMADO** | | **$352.500*** | **$6.230.000** | **$12.590.000***| **Sujeto a variaciones de TRM y volumen real de usuarios. Desarrollo incluido: 4 meses MVP ($1.4M/mes) + costos operativos 3 años.** |

---

## 🛠️ Desglose de Rubros Tecnológicos y Supuestos

### 1. Desarrollo y Diseño ($1.400.000 COP/mes - Modelo Ágil Iterativo)
* Modelo de tarifa mensual para la ejecución del MVP (4 meses) y posteriores desarrollos. Incluye la entrega de la interfaz del Everest, panel de administración para clientes empresariales, panel del coach, lógica relacional interna, y agente Sherpa.
* **Estructura:** $1.400.000 COP/mes × 4 meses = $5.600.000 para MVP completo
* **Nuevos desarrollos post-MVP:** Mantienen el tabulador de $1.400.000 COP/mes (modulares, no acumulativos)

### 2. Infraestructura y Hosting (Opex)
* **Supabase (BaaS):** Se presupuesta el plan Pro de $100.000 COP/mes para asegurar respaldos automáticos, mayores conexiones concurrentes y escalabilidad en almacenamiento de logs analíticos. Si el tráfico inicial es bajo, se operará bajo el Free Tier ($0 COP).
* **Dominios y Certificados:** Compra de dominio con TLS/SSL administrado de forma nativa por el proveedor de despliegue frontend para mitigar riesgos de Man-in-the-Middle.

### 3. Orquestación del Agente de Inteligencia Artificial (Gemini API)
* El agente utiliza un modelo de lenguaje avanzado provisto por Google. Cada prompt enviado por el usuario pasa por una plantilla de validación estricta (*Guardrail Prompting*) para impedir filtraciones de datos sensibles de la empresa o respuestas no éticas.
* *Cálculo del presupuesto:* Se proyecta un costo de $40.000 COP mensuales basados en cobro por cada 1M de tokens de entrada/salida para las consultas psicométricas interactivas y recomendaciones del Sherpa NPC.

---

## 📊 Explicación de Cálculos

### Detalles de Componentes

**Desarrollo de Software:** $1.400.000 COP/mes (4 meses MVP = $5.600.000 COP)
- Modelo de tarifa mensual para garantizar flexibilidad en alcance y facilitar posteriores desarrollos modulares
- Nuevos desarrollos post-MVP utilizan el mismo tabulador mensual

**Supabase:** Free Tier en Año 1 ($0/mes), Plan Pro a partir de Año 2 ($100.000 COP/mes)
- Incluye backups automáticos, conexiones concurrentes y escalabilidad en logs

**Gemini API:** $40.000 COP/mes basado en consumo de 1M tokens
- Consultas psicométricas interactivas y recomendaciones del Sherpa NPC

**Hosting Frontend:** $12.500 COP/mes
- Dominio `.com` o `.co` + hosting estático en Vercel/Netlify con SSL nativo

**Soporte y Mantenimiento:** $0 en Año 1 (incluido), $62.500 COP/mes en Años 2-3
- Garantía incluida en Año 1; mantenimiento preventivo: $750.000/año