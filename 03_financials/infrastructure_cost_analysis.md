# 3. Análisis Financiero: Presupuesto Total de Infraestructura, Diseño y Desarrollo

El presente documento detalla la estimación de costos asociados al ciclo de vida del software para un horizonte de proyección de 1 y 3 años. Este análisis separa los gastos únicos por desarrollo de software de los costos operativos fijos por arrendamiento de servicios Cloud.

## 💰 Resumen Consolidado de Costos (Moneda de Referencia: COP)

| Componente | Tipo de Gasto | Costo Mensual | Costo Año 1 | Costo Acumulado 3 Años | Notas Técnicas |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Desarrollo de Software** | Único (One-time) | N/A | $2.000.000 | $2.000.000 | Honorarios del equipo de desarrollo e ingeniería. |
| **Infraestructura Cloud (Supabase)**| Recurrente (SaaS) | $100.000* | $0 - $1.200.000** | $3.600.000 | Plan Pro: $25 USD/mes (~$100.000 COP/mes). Año 1 con Free Tier ($0). Años 2-3 con plan Pro. |
| **Consumo de APIs de IA (Gemini)** | Recurrente (Uso) | $40.000 | $480.000 | $1.440.000 | Estimado en base a tokens consumidos ($10 USD/mes ≈ $40.000 COP/mes) con Guardrails activos. |
| **Hosting Frontend y Dominios** | Recurrente (Anual) | $12.500 | $150.000 | $450.000 | Dominio `.com` o `.co` + Hosting estático administrado (Vercel/Netlify). |
| **Soporte y Mantenimiento** | Recurrente (Anual) | $0 / $62.500*** | $0 | $1.500.000 | Garantía incluida el Año 1 ($0). Mantenimiento preventivo Años 2-3 ($750.000/año). |
| **TOTAL ESTIMADO** | | **$152.500*** | **$2.630.000** | **$9.000.000***| **Sujeto a variaciones de TRM y volumen real de usuarios.** |

---

## 🛠️ Desglose de Rubros Tecnológicos y Supuestos

### 1. Desarrollo y Diseño ($2.000.000 COP - Capex)
* Costo fijo establecido para la ejecución del MVP que incluye la entrega de la interfaz del Everest, panel de administración para clientes empresariales, panel del coach y lógica relacional interna.

### 2. Infraestructura y Hosting (Opex)
* **Supabase (BaaS):** Se presupuesta el plan Pro de $25 USD/mes para asegurar respaldos automáticos, mayores conexiones concurrentes y escalabilidad en almacenamiento de logs analíticos. Si el tráfico inicial es bajo, se operará bajo el Free Tier ($0 COP).
* **Dominios y Certificados:** Compra de dominio con TLS/SSL administrado de forma nativa por el proveedor de despliegue frontend para mitigar riesgos de Man-in-the-Middle.

### 3. Orquestación del Agente de Inteligencia Artificial (Gemini API)
* El agente utiliza un modelo de lenguaje avanzado provisto por Google. Cada prompt enviado por el usuario pasa por una plantilla de validación estricta (*Guardrail Prompting*) para impedir filtraciones de datos sensibles de la empresa o respuestas no éticas.
* *Cálculo del presupuesto:* Se proyecta un costo de $10 USD mensuales basados en cobro por cada 1M de tokens de entrada/salida para las consultas psicométricas interactivas y recomendaciones del Sherpa NPC.

---

## 📊 Explicación de Cálculos y Notas

### Columna de Costo Mensual
- **Asterisco (*) en Supabase:** Aplica solo a partir del Año 2 cuando se migra al plan Pro. En Año 1 se usa Free Tier ($0/mes).
- **Asterisco (*) en Soporte:** Muestra $0 para el Año 1 (garantía incluida) y $62.500/mes para Años 2-3 ($750.000 ÷ 12 meses).
- **Asterisco (*) en Total mensual:** Promedio para Año 1 es $52.500/mes (sin Supabase). Promedio para Años 2-3 es $215.000/mes (todos los servicios activos).

### Correcciones Realizadas
| Concepto | Valor Anterior | Valor Correcto | Justificación |
| :--- | :---: | :---: | :--- |
| **Costo Acumulado 3 Años** | $8.990.000 | $9.000.000 | Corrección aritmética: Dev($2M) + Supabase($3.6M) + Gemini($1.44M) + Hosting($0.45M) + Soporte($1.5M) = $9.0M |
| **Estructura de Supabase** | $0 - $1.200.000 por año | $0 (Año 1), $1.200.000 (Años 2-3) | Clarificación: Free Tier en Año 1; Pro plan a partir de Año 2 ($25 USD/mes ≈ $100.000 COP/mes) |
| **Conversión USD a COP** | No especificado | ~4.000 COP/USD | Referencia: $25 USD/mes = ~$100.000 COP/mes; $10 USD/mes = ~$40.000 COP/mes (TRM aproximada) |