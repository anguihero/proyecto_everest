-- =====================================================
-- Seed 007: 20 preguntas DISC — Expedición Base (Fase 0)
-- Fuente: docs/retos_fase_0.md
-- Patrón DISC:  A=Dominancia(D)  B=Influencia(I)
--               C=Estabilidad(S) D=Conformidad(C)
-- Pesos: primario=0.700, secundarios=0.100 c/u
--
-- UUID scheme (todos decimal, no hex):
--   Pregunta N:  10000000-0000-0000-0000-00000000{N 4d}-{N 8d}
--   Opción A/N:  20000000-0001-0000-0000-000000000{N 3d}
--   Opción B/N:  20000000-0002-0000-0000-000000000{N 3d}
--   Opción C/N:  20000000-0003-0000-0000-000000000{N 3d}
--   Opción D/N:  20000000-0004-0000-0000-000000000{N 3d}
--
-- Prerrequisito: 005_question_bank.sql y 005_casete_base.sql aplicadas
-- Ejecutar en Supabase SQL Editor (proyecto fwwkchcxildykvfhrcri)
-- =====================================================


DO $$
DECLARE
  fb_d TEXT := 'Actuaste con decisión y orientación a resultados. El Sherpa te pregunta: ¿contemplaste el impacto en las personas involucradas antes de avanzar?';
  fb_i TEXT := 'Tu energía e influencia conectan con el equipo. ¿Cómo garantizas que el entusiasmo se traduzca en acciones concretas y medibles?';
  fb_s TEXT := 'Tu búsqueda de estabilidad y consenso fortalece la confianza colectiva. ¿En qué momentos actuar más rápido habría generado mayor valor?';
  fb_c TEXT := 'Tu rigor y atención al detalle protegen la calidad del proceso. ¿Cuándo la agilidad habría sido más valiosa que la perfección?';
BEGIN

-- ════════════════════════════════════════════════════
-- PREGUNTAS (20)
-- ════════════════════════════════════════════════════

INSERT INTO public.questions
  (id, title, text, difficulty, avg_time_secs, context_notes, is_active)
VALUES
  ('10000000-0000-0000-0001-000000000001',
   'Documento con inconsistencias menores',
   'Estás revisando un documento importante antes de enviarlo al cliente. Notas que hay algunas inconsistencias menores, pero el tiempo apremia.',
   2, 60, 'Calidad vs. velocidad de entrega — perfeccionismo vs. pragmatismo', true),

  ('10000000-0000-0000-0002-000000000002',
   'Reunión con malentendidos frecuentes',
   'Estás en una reunión con distintas áreas. Notas que hay malentendidos frecuentes entre los participantes y la conversación se torna confusa.',
   2, 60, 'Facilitación — claridad y avance vs. inclusión y escucha', true),

  ('10000000-0000-0000-0003-000000000003',
   'Nuevo enfoque fuera de políticas',
   'Tu equipo propone implementar un nuevo enfoque de trabajo, pero no está alineado con las políticas actuales.',
   3, 75, 'Gestión del cambio institucional — acción vs. cumplimiento normativo', true),

  ('10000000-0000-0000-0004-000000000004',
   'Compañero con mal día',
   'Un compañero de trabajo te cuenta que está teniendo un mal día y se siente frustrado por sus tareas.',
   1, 45, 'Inteligencia emocional — apoyo directivo vs. empatía', true),

  ('10000000-0000-0000-0005-000000000005',
   'Tensiones entre dos personas clave',
   'Tu equipo está experimentando tensiones internas entre dos personas clave.',
   2, 75, 'Resolución de conflictos interpersonales — confrontación vs. mediación', true),

  ('10000000-0000-0000-0006-000000000006',
   'Obstáculo potencial en el cronograma',
   'Tu proyecto tiene un posible obstáculo que podría afectar el cronograma, pero aún no es seguro.',
   2, 75, 'Gestión de riesgos — acción anticipada vs. análisis antes de actuar', true),

  ('10000000-0000-0000-0007-000000000007',
   'Reestructuración que cambia tu rol',
   'La empresa anuncia una reestructuración que transformará tu rol y responsabilidades.',
   3, 75, 'Adaptabilidad al cambio organizacional — proactividad vs. apoyo al equipo', true),

  ('10000000-0000-0000-0008-000000000008',
   'Múltiples tareas urgentes en el día',
   'Tienes múltiples tareas urgentes y te resulta difícil cumplir con todas en el día.',
   2, 60, 'Gestión de prioridades — enfoque individual vs. distribución colaborativa', true),

  ('10000000-0000-0000-0009-000000000009',
   'Área de mejora que nadie ha abordado',
   'Notas un área de mejora en tu empresa que nadie ha abordado aún.',
   2, 60, 'Iniciativa e innovación — propuesta directa vs. análisis sistemático', true),

  ('10000000-0000-0000-0010-000000000010',
   'Relanzar producto sin acogida',
   'Te piden diseñar una nueva campaña para lanzar un producto que no ha tenido buena acogida hasta ahora.',
   3, 90, 'Creatividad y estrategia — disrupción vs. fundamentación en datos', true),

  ('10000000-0000-0000-0011-000000000011',
   'Equipo sin metas en ambiente tenso',
   'Eres responsable de un equipo que no está cumpliendo metas y el ambiente está tenso.',
   3, 90, 'Liderazgo en crisis — control y estructura vs. motivación y confianza', true),

  ('10000000-0000-0000-0012-000000000012',
   'Problema operativo recurrente',
   'Te piden resolver un problema operativo que se ha presentado en varias ocasiones.',
   2, 75, 'Resolución de problemas — rediseño radical vs. diagnóstico sistemático', true),

  ('10000000-0000-0000-0013-000000000013',
   'Expansión a nuevo mercado',
   'Te piden planear la expansión de una unidad de negocio en un nuevo mercado.',
   3, 90, 'Planificación estratégica — agresividad vs. metodología estructurada', true),

  ('10000000-0000-0000-0014-000000000014',
   'Persuadir gerencia con nueva metodología',
   'Debes persuadir a la gerencia para adoptar una nueva metodología de trabajo.',
   3, 90, 'Influencia sin autoridad — urgencia y firmeza vs. evidencia y demostración', true),

  ('10000000-0000-0000-0015-000000000015',
   'Proyecto complejo con múltiples actores',
   'Estás liderando un proyecto complejo con múltiples actores y plazos ajustados.',
   3, 90, 'Gestión de proyectos — delegación estructurada vs. control con herramientas', true),

  ('10000000-0000-0000-0016-000000000016',
   'Desacuerdo fuerte entre departamentos',
   'Hay un desacuerdo fuerte entre dos departamentos que bloquea un proceso esencial.',
   2, 75, 'Mediación interdepartamental — autoridad directiva vs. facilitación', true),

  ('10000000-0000-0000-0017-000000000017',
   'Cliente insatisfecho y emocional',
   'Un cliente transmite su insatisfacción de manera emocional y caótica.',
   2, 60, 'Atención al cliente difícil — firmeza en políticas vs. empatía activa', true),

  ('10000000-0000-0000-0018-000000000018',
   'Elegir entre dos proveedores',
   'Te solicitan elegir entre dos proveedores con ventajas y desventajas distintas.',
   2, 60, 'Toma de decisiones de compra — ambición de resultados vs. rigor técnico', true),

  ('10000000-0000-0000-0019-000000000019',
   'Miembro del equipo que no colabora',
   'El equipo debe entregar un proyecto, pero hay una persona que no colabora.',
   2, 75, 'Gestión del bajo desempeño — exigencia directa vs. integración y apoyo', true),

  ('10000000-0000-0000-0020-000000000020',
   'Negociar plazos con cliente exigente',
   'Debes negociar los plazos de entrega con un cliente que exige tiempos muy cortos.',
   3, 75, 'Negociación — firmeza en límites vs. propuesta con datos técnicos', true)

ON CONFLICT (id) DO UPDATE
  SET title         = EXCLUDED.title,
      text          = EXCLUDED.text,
      difficulty    = EXCLUDED.difficulty,
      avg_time_secs = EXCLUDED.avg_time_secs,
      context_notes = EXCLUDED.context_notes,
      is_active     = EXCLUDED.is_active;


-- ════════════════════════════════════════════════════
-- OPCIONES (80 = 20 preguntas × 4)
-- sort_order: 1=A(D)  2=B(I)  3=C(S)  4=D(C)
-- ════════════════════════════════════════════════════

INSERT INTO public.question_options
  (id, question_id, text, feedback, disc_d, disc_i, disc_s, disc_c, sort_order, is_active)
VALUES

  -- Q01
  ('20000000-0001-0000-0001-000000000001','10000000-0000-0000-0001-000000000001',
   'Lo envío de inmediato. El cliente necesita respuestas rápidas, y esos detalles no cambian el fondo.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0001-000000000001','10000000-0000-0000-0001-000000000001',
   'Informo al equipo y escribo un mensaje al cliente explicando que estamos afinando los últimos puntos para entregarle algo excelente.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0001-000000000001','10000000-0000-0000-0001-000000000001',
   'Propongo enviar una parte del documento ya revisada y trabajar tranquilamente en el resto para evitar errores.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0001-000000000001','10000000-0000-0000-0001-000000000001',
   'Reviso todo en detalle, verifico datos y formato, aunque me tome más tiempo. No puedo permitir que haya errores.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q02
  ('20000000-0001-0000-0002-000000000002','10000000-0000-0000-0002-000000000002',
   'Tomo la palabra, resumo lo esencial y propongo seguir una estructura más clara. Hay que avanzar.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0002-000000000002','10000000-0000-0000-0002-000000000002',
   'Uso un lenguaje positivo para reencauzar la conversación y aseguro que todos se sientan escuchados.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0002-000000000002','10000000-0000-0000-0002-000000000002',
   'Pido turno, invito a cada persona a expresar su punto de vista sin interrupciones y busco que todos comprendan bien.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0002-000000000002','10000000-0000-0000-0002-000000000002',
   'Propongo registrar por escrito los acuerdos, asignar responsabilidades y revisar juntos los puntos confusos.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q03
  ('20000000-0001-0000-0003-000000000003','10000000-0000-0000-0003-000000000003',
   'Lo implemento si acelera resultados, asumo las consecuencias después.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0003-000000000003','10000000-0000-0000-0003-000000000003',
   'Lo presento como una innovación positiva y trato de conseguir aceptación informal primero.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0003-000000000003','10000000-0000-0000-0003-000000000003',
   'Sugiero revisarlo en conjunto antes de aplicar cualquier cambio.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0003-000000000003','10000000-0000-0000-0003-000000000003',
   'Reviso los procedimientos y consulto con legal para asegurarme de no incumplir normas.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q04
  ('20000000-0001-0000-0004-000000000004','10000000-0000-0000-0004-000000000004',
   'Le sugiero enfocarse en lo que sí puede controlar y seguir adelante.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0004-000000000004','10000000-0000-0000-0004-000000000004',
   'Le ofrezco ánimo con una historia inspiradora y le digo que puede contar conmigo.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0004-000000000004','10000000-0000-0000-0004-000000000004',
   'Le escucho con calma, mostrando comprensión y validando sus emociones.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0004-000000000004','10000000-0000-0000-0004-000000000004',
   'Le ayudo a organizar sus pendientes para que vea que hay un camino claro para salir del problema.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q05
  ('20000000-0001-0000-0005-000000000005','10000000-0000-0000-0005-000000000005',
   'Reúno a ambos y los confronto directamente para resolverlo rápido.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0005-000000000005','10000000-0000-0000-0005-000000000005',
   'Hablo con cada uno por separado para mediar con empatía y calmar los ánimos.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0005-000000000005','10000000-0000-0000-0005-000000000005',
   'Promuevo una actividad colaborativa para que vuelvan a conectarse desde el trabajo en común.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0005-000000000005','10000000-0000-0000-0005-000000000005',
   'Documento lo ocurrido, analizo causas y busco soluciones estructurales.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q06
  ('20000000-0001-0000-0006-000000000006','10000000-0000-0000-0006-000000000006',
   'Decido actuar de inmediato y reorganizo el plan para evitar cualquier pérdida.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0006-000000000006','10000000-0000-0000-0006-000000000006',
   'Planteo el riesgo al equipo de forma motivadora y busco ideas creativas para afrontarlo.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0006-000000000006','10000000-0000-0000-0006-000000000006',
   'Preparo un plan alternativo pero sigo el curso actual hasta tener más datos.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0006-000000000006','10000000-0000-0000-0006-000000000006',
   'Elaboro una matriz de riesgos y activo los protocolos de contingencia.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q07
  ('20000000-0001-0000-0007-000000000007','10000000-0000-0000-0007-000000000007',
   'Me anticipo proponiendo mejoras para tener protagonismo en el nuevo esquema.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0007-000000000007','10000000-0000-0000-0007-000000000007',
   'Hablo con mis compañeros para mantener el ánimo y aprovechar juntos el cambio.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0007-000000000007','10000000-0000-0000-0007-000000000007',
   'Escucho, me adapto gradualmente y doy apoyo a quienes están más inseguros.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0007-000000000007','10000000-0000-0000-0007-000000000007',
   'Reviso cuidadosamente la nueva estructura y ajusto mis procesos a lo establecido.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q08
  ('20000000-0001-0000-0008-000000000008','10000000-0000-0000-0008-000000000008',
   'Ataco lo más importante de inmediato, sin distraerme.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0008-000000000008','10000000-0000-0000-0008-000000000008',
   'Pido apoyo al equipo y genero un clima colaborativo para repartir las cargas.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0008-000000000008','10000000-0000-0000-0008-000000000008',
   'Me enfoco en lo que puedo resolver bien hoy, y dejo claro cuándo terminaré el resto.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0008-000000000008','10000000-0000-0000-0008-000000000008',
   'Organizo una lista detallada de prioridades y sigo un cronograma estricto.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q09
  ('20000000-0001-0000-0009-000000000009','10000000-0000-0000-0009-000000000009',
   'Desarrollo una propuesta y se la presento directamente a los líderes.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0009-000000000009','10000000-0000-0000-0009-000000000009',
   'Creo un pequeño grupo de entusiastas y los motivo a trabajar en ello juntos.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0009-000000000009','10000000-0000-0000-0009-000000000009',
   'Comparto mi idea en una reunión y me ofrezco como voluntario si es bien recibida.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0009-000000000009','10000000-0000-0000-0009-000000000009',
   'Investigo, documento todo y presento un informe técnico con soluciones sugeridas.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q10
  ('20000000-0001-0000-0010-000000000010','10000000-0000-0000-0010-000000000010',
   'Cambio por completo el enfoque, apunto a algo disruptivo y con alto impacto.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0010-000000000010','10000000-0000-0000-0010-000000000010',
   'Planteo ideas originales en una lluvia de ideas y motivo al equipo con entusiasmo.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0010-000000000010','10000000-0000-0000-0010-000000000010',
   'Reutilizo elementos que han funcionado en otras campañas y los adapto al nuevo público.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0010-000000000010','10000000-0000-0000-0010-000000000010',
   'Hago benchmarking de campañas exitosas, analizo datos y diseño una propuesta fundamentada.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q11
  ('20000000-0001-0000-0011-000000000011','10000000-0000-0000-0011-000000000011',
   'Pongo reglas claras y asigno responsabilidades con fechas límite.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0011-000000000011','10000000-0000-0000-0011-000000000011',
   'Organizo una charla motivacional y refuerzo la visión del equipo.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0011-000000000011','10000000-0000-0000-0011-000000000011',
   'Escucho a todos y trabajo en mejorar la confianza colectiva.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0011-000000000011','10000000-0000-0000-0011-000000000011',
   'Hago seguimiento individual y ofrezco retroalimentación estructurada.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q12
  ('20000000-0001-0000-0012-000000000012','10000000-0000-0000-0012-000000000012',
   'Propongo eliminar el proceso actual y empezar de cero con algo más efectivo.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0012-000000000012','10000000-0000-0000-0012-000000000012',
   'Escucho distintas opiniones y conecto ideas para proponer una solución atractiva.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0012-000000000012','10000000-0000-0000-0012-000000000012',
   'Recojo información de todos los involucrados y la comparo con experiencias anteriores.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0012-000000000012','10000000-0000-0000-0012-000000000012',
   'Recolecto datos, identifico causas raíz y diseño una solución lógica.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q13
  ('20000000-0001-0000-0013-000000000013','10000000-0000-0000-0013-000000000013',
   'Identifico las ventajas competitivas clave y planteo una estrategia agresiva.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0013-000000000013','10000000-0000-0000-0013-000000000013',
   'Analizo las tendencias sociales y culturales del mercado para posicionarnos mejor.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0013-000000000013','10000000-0000-0000-0013-000000000013',
   'Estudio casos anteriores, busco aliados locales y avanzo paso a paso.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0013-000000000013','10000000-0000-0000-0013-000000000013',
   'Realizo un análisis DOFA completo y desarrollo un plan estructurado.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q14
  ('20000000-0001-0000-0014-000000000014','10000000-0000-0000-0014-000000000014',
   'Presento resultados esperados con firmeza y muestro la urgencia del cambio.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0014-000000000014','10000000-0000-0000-0014-000000000014',
   'Cuento una historia convincente sobre los beneficios y el entusiasmo de otros usuarios.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0014-000000000014','10000000-0000-0000-0014-000000000014',
   'Invito a un taller demostrativo para que puedan experimentar los beneficios.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0014-000000000014','10000000-0000-0000-0014-000000000014',
   'Presento datos, estadísticas y estudios de caso que sustentan mi recomendación.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q15
  ('20000000-0001-0000-0015-000000000015','10000000-0000-0000-0015-000000000015',
   'Divido el proyecto en fases clave y asigno responsables según fortalezas.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0015-000000000015','10000000-0000-0000-0015-000000000015',
   'Organizo reuniones motivadoras para que todos estén alineados.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0015-000000000015','10000000-0000-0000-0015-000000000015',
   'Creo un cronograma claro con margen para adaptaciones y consensos.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0015-000000000015','10000000-0000-0000-0015-000000000015',
   'Uso una herramienta de gestión para documentar cada tarea y controlar avances.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q16
  ('20000000-0001-0000-0016-000000000016','10000000-0000-0000-0016-000000000016',
   'Reúno a los líderes, defino una línea de acción clara y hago que la sigan.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0016-000000000016','10000000-0000-0000-0016-000000000016',
   'Busco puntos en común y propongo una actividad de integración.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0016-000000000016','10000000-0000-0000-0016-000000000016',
   'Facilito un espacio de escucha mutua y mediación.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0016-000000000016','10000000-0000-0000-0016-000000000016',
   'Reviso procesos para detectar fallas y propongo ajustes desde la norma.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q17
  ('20000000-0001-0000-0017-000000000017','10000000-0000-0000-0017-000000000017',
   'Le explico de forma firme las políticas y condiciones del servicio.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0017-000000000017','10000000-0000-0000-0017-000000000017',
   'Me conecto con sus emociones y busco empatizar para tranquilizarlo.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0017-000000000017','10000000-0000-0000-0017-000000000017',
   'Escucho atentamente, agradezco su retroalimentación y ofrezco alternativas.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0017-000000000017','10000000-0000-0000-0017-000000000017',
   'Registro su queja formalmente y sigo el protocolo de resolución.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q18
  ('20000000-0001-0000-0018-000000000018','10000000-0000-0000-0018-000000000018',
   'Elijo el que promete resultados más ambiciosos y rápidos.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0018-000000000018','10000000-0000-0000-0018-000000000018',
   'Elijo al que tiene mejor reputación y trato humano.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0018-000000000018','10000000-0000-0000-0018-000000000018',
   'Me inclino por el más constante y confiable a largo plazo.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0018-000000000018','10000000-0000-0000-0018-000000000018',
   'Comparo datos técnicos y costo-beneficio para decidir objetivamente.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q19
  ('20000000-0001-0000-0019-000000000019','10000000-0000-0000-0019-000000000019',
   'Le exijo que cumpla o asumo su parte y lo reporto.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0019-000000000019','10000000-0000-0000-0019-000000000019',
   'Trato de entusiasmarlo e integrarlo al espíritu de equipo.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0019-000000000019','10000000-0000-0000-0019-000000000019',
   'Le ofrezco apoyo para que se sienta incluido sin juzgarlo.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0019-000000000019','10000000-0000-0000-0019-000000000019',
   'Le explico sus responsabilidades y documento su desempeño.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true),

  -- Q20
  ('20000000-0001-0000-0020-000000000020','10000000-0000-0000-0020-000000000020',
   'Planteo firmemente mis condiciones y marco un límite claro.',
   fb_d, 0.700,0.100,0.100,0.100, 1, true),
  ('20000000-0002-0000-0020-000000000020','10000000-0000-0000-0020-000000000020',
   'Uso el humor y la empatía para encontrar una solución creativa que lo convenza.',
   fb_i, 0.100,0.700,0.100,0.100, 2, true),
  ('20000000-0003-0000-0020-000000000020','10000000-0000-0000-0020-000000000020',
   'Escucho sus razones, explico las nuestras y propongo un punto medio justo.',
   fb_s, 0.100,0.100,0.700,0.100, 3, true),
  ('20000000-0004-0000-0020-000000000020','10000000-0000-0000-0020-000000000020',
   'Explico con datos la viabilidad técnica del plazo y propongo una nueva programación.',
   fb_c, 0.100,0.100,0.100,0.700, 4, true)

ON CONFLICT (id) DO UPDATE
  SET text        = EXCLUDED.text,
      feedback    = EXCLUDED.feedback,
      disc_d      = EXCLUDED.disc_d,
      disc_i      = EXCLUDED.disc_i,
      disc_s      = EXCLUDED.disc_s,
      disc_c      = EXCLUDED.disc_c,
      sort_order  = EXCLUDED.sort_order,
      is_active   = EXCLUDED.is_active;


-- ════════════════════════════════════════════════════
-- COMPOSICIÓN: vincular las 20 preguntas a expedicion-base
-- ════════════════════════════════════════════════════

INSERT INTO public.reto_compositions (experience_id, question_id, sort_order, is_active)
VALUES
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0001-000000000001', 1, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0002-000000000002', 2, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0003-000000000003', 3, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0004-000000000004', 4, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0005-000000000005', 5, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0006-000000000006', 6, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0007-000000000007', 7, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0008-000000000008', 8, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0009-000000000009', 9, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0010-000000000010',10, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0011-000000000011',11, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0012-000000000012',12, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0013-000000000013',13, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0014-000000000014',14, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0015-000000000015',15, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0016-000000000016',16, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0017-000000000017',17, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0018-000000000018',18, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0019-000000000019',19, true),
  ('b0000000-0000-0000-0000-000000000001','10000000-0000-0000-0020-000000000020',20, true)
ON CONFLICT (experience_id, question_id) DO UPDATE
  SET is_active  = true,
      sort_order = EXCLUDED.sort_order;

END $$;


-- ════════════════════════════════════════════════════
-- ENSAMBLAR versión v2.0.0 de expedicion-base
-- (fuera del DO block para capturar el UUID retornado)
-- ════════════════════════════════════════════════════

DO $$
DECLARE
  v_v2_id UUID;
BEGIN
  -- Retirar v1 (3 preguntas dummy) — las sesiones completadas quedan intactas
  UPDATE public.experience_versions
  SET    status = 'retired'
  WHERE  experience_id = 'b0000000-0000-0000-0000-000000000001'
    AND  schema_version = '1.0';

  -- Ensamblar v2.0.0 desde el banco relacional
  -- auth.uid() = NULL en seed context → bypasea check de rol
  SELECT public.assemble_reto_version(
    'b0000000-0000-0000-0000-000000000001',
    '2.0.0',
    NULL
  ) INTO v_v2_id;

  RAISE NOTICE 'Versión v2.0.0 creada: %', v_v2_id;

  -- Migrar asignaciones activas a la nueva versión
  UPDATE public.experience_assignments
  SET    experience_version_id = v_v2_id
  WHERE  experience_id = 'b0000000-0000-0000-0000-000000000001'
    AND  status != 'completed';

  RAISE NOTICE 'Asignaciones activas migradas a v2.0.0';
END $$;


-- ─── Verificación final ──────────────────────────────

SELECT entidad, total FROM (
  SELECT 'questions activas'          AS entidad, COUNT(*)::text AS total FROM public.questions WHERE is_active
  UNION ALL
  SELECT 'question_options activas',               COUNT(*)::text         FROM public.question_options WHERE is_active
  UNION ALL
  SELECT 'reto_compositions activas',              COUNT(*)::text         FROM public.reto_compositions WHERE is_active
  UNION ALL
  SELECT 'experience_versions v2.0 publicada',     COUNT(*)::text
    FROM public.experience_versions
    WHERE experience_id = 'b0000000-0000-0000-0000-000000000001'
      AND schema_version = '2.0' AND status = 'published'
  UNION ALL
  SELECT 'assignments migradas a v2',              COUNT(*)::text
    FROM public.experience_assignments ea
    JOIN public.experience_versions    ev ON ev.id = ea.experience_version_id
    WHERE ev.schema_version = '2.0'
) sub;
