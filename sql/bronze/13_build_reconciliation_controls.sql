CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.control_totales`
PARTITION BY periodo
CLUSTER BY capa, tabla, metrica, ramo_id AS
WITH
origen_polizas AS (
  SELECT
    DATE_TRUNC(fecha_emision, MONTH) AS periodo,
    ramo_id,
    moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(prima_total), 2) AS prima_total,
    ROUND(SUM(suma_asegurada), 2) AS suma_asegurada
  FROM `${PROJECT_ID}.${DATASET_ID}.polizas`
  GROUP BY 1, 2, 3
),
bronce_polizas AS (
  SELECT
    DATE_TRUNC(fecha_emision, MONTH) AS periodo,
    ramo_id,
    moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(prima_total), 2) AS prima_total,
    ROUND(SUM(suma_asegurada), 2) AS suma_asegurada
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.polizas`
  GROUP BY 1, 2, 3
),
origen_pagos AS (
  SELECT
    DATE_TRUNC(pp.fecha_vencimiento, MONTH) AS periodo,
    p.ramo_id,
    pp.moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(pp.importe_programado), 2) AS importe_programado,
    ROUND(SUM(pp.importe_pagado), 2) AS importe_pagado
  FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas` AS pp
  JOIN `${PROJECT_ID}.${DATASET_ID}.polizas` AS p
    ON pp.poliza_id = p.poliza_id
  GROUP BY 1, 2, 3
),
bronce_pagos AS (
  SELECT
    DATE_TRUNC(pp.fecha_vencimiento, MONTH) AS periodo,
    p.ramo_id,
    pp.moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(pp.importe_programado), 2) AS importe_programado,
    ROUND(SUM(pp.importe_pagado), 2) AS importe_pagado
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.pagos_primas` AS pp
  JOIN `${PROJECT_ID}.${BRONZE_DATASET_ID}.polizas` AS p
    ON pp.poliza_id = p.poliza_id
  GROUP BY 1, 2, 3
),
origen_siniestros AS (
  SELECT
    DATE_TRUNC(fecha_ocurrencia, MONTH) AS periodo,
    ramo_id,
    moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(monto_reclamado), 2) AS monto_reclamado,
    ROUND(SUM(monto_reserva), 2) AS monto_reserva,
    ROUND(SUM(COALESCE(monto_indemnizado, 0)), 2) AS monto_indemnizado
  FROM `${PROJECT_ID}.${DATASET_ID}.siniestros`
  GROUP BY 1, 2, 3
),
bronce_siniestros AS (
  SELECT
    DATE_TRUNC(fecha_ocurrencia, MONTH) AS periodo,
    ramo_id,
    moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(monto_reclamado), 2) AS monto_reclamado,
    ROUND(SUM(monto_reserva), 2) AS monto_reserva,
    ROUND(SUM(COALESCE(monto_indemnizado, 0)), 2) AS monto_indemnizado
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
  GROUP BY 1, 2, 3
),
origen_movimientos AS (
  SELECT
    DATE_TRUNC(m.fecha_movimiento, MONTH) AS periodo,
    p.ramo_id,
    p.moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(COALESCE(m.monto_movimiento, 0)), 2) AS monto_movimiento
  FROM `${PROJECT_ID}.${DATASET_ID}.movimientos_siniestro` AS m
  JOIN `${PROJECT_ID}.${DATASET_ID}.polizas` AS p
    ON m.poliza_id = p.poliza_id
  GROUP BY 1, 2, 3
),
bronce_movimientos AS (
  SELECT
    DATE_TRUNC(m.fecha_movimiento, MONTH) AS periodo,
    p.ramo_id,
    p.moneda,
    COUNT(*) AS cantidad_registros,
    ROUND(SUM(COALESCE(m.monto_movimiento, 0)), 2) AS monto_movimiento
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.movimientos_siniestro` AS m
  JOIN `${PROJECT_ID}.${BRONZE_DATASET_ID}.polizas` AS p
    ON m.poliza_id = p.poliza_id
  GROUP BY 1, 2, 3
)
SELECT
  'ORIGEN' AS capa,
  'polizas' AS tabla,
  periodo,
  ramo_id,
  moneda,
  metrica,
  valor,
  '${BRONZE_LOAD_ID}' AS carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS fecha_control
FROM origen_polizas
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('PRIMA_TOTAL', prima_total),
  STRUCT('SUMA_ASEGURADA', suma_asegurada)
])
UNION ALL
SELECT
  'BRONCE', 'polizas', periodo, ramo_id, moneda, metrica, valor,
  '${BRONZE_LOAD_ID}', TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}'
FROM bronce_polizas
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('PRIMA_TOTAL', prima_total),
  STRUCT('SUMA_ASEGURADA', suma_asegurada)
])
UNION ALL
SELECT
  'ORIGEN', 'pagos_primas', periodo, ramo_id, moneda, metrica, valor,
  '${BRONZE_LOAD_ID}', TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}'
FROM origen_pagos
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('IMPORTE_PROGRAMADO', importe_programado),
  STRUCT('IMPORTE_PAGADO', importe_pagado)
])
UNION ALL
SELECT
  'BRONCE', 'pagos_primas', periodo, ramo_id, moneda, metrica, valor,
  '${BRONZE_LOAD_ID}', TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}'
FROM bronce_pagos
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('IMPORTE_PROGRAMADO', importe_programado),
  STRUCT('IMPORTE_PAGADO', importe_pagado)
])
UNION ALL
SELECT
  'ORIGEN', 'siniestros', periodo, ramo_id, moneda, metrica, valor,
  '${BRONZE_LOAD_ID}', TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}'
FROM origen_siniestros
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('MONTO_RECLAMADO', monto_reclamado),
  STRUCT('MONTO_RESERVA', monto_reserva),
  STRUCT('MONTO_INDEMNIZADO', monto_indemnizado)
])
UNION ALL
SELECT
  'BRONCE', 'siniestros', periodo, ramo_id, moneda, metrica, valor,
  '${BRONZE_LOAD_ID}', TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}'
FROM bronce_siniestros
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('MONTO_RECLAMADO', monto_reclamado),
  STRUCT('MONTO_RESERVA', monto_reserva),
  STRUCT('MONTO_INDEMNIZADO', monto_indemnizado)
])
UNION ALL
SELECT
  'ORIGEN', 'movimientos_siniestro', periodo, ramo_id, moneda, metrica, valor,
  '${BRONZE_LOAD_ID}', TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}'
FROM origen_movimientos
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('MONTO_MOVIMIENTO', monto_movimiento)
])
UNION ALL
SELECT
  'BRONCE', 'movimientos_siniestro', periodo, ramo_id, moneda, metrica, valor,
  '${BRONZE_LOAD_ID}', TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}'
FROM bronce_movimientos
CROSS JOIN UNNEST([
  STRUCT('CANTIDAD_REGISTROS' AS metrica, CAST(cantidad_registros AS NUMERIC) AS valor),
  STRUCT('MONTO_MOVIMIENTO', monto_movimiento)
]);

CREATE OR REPLACE VIEW `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_resultado_cuadratura` AS
WITH origen AS (
  SELECT * EXCEPT(capa)
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.control_totales`
  WHERE capa = 'ORIGEN'
),
bronce AS (
  SELECT * EXCEPT(capa)
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.control_totales`
  WHERE capa = 'BRONCE'
)
SELECT
  COALESCE(o.tabla, b.tabla) AS tabla,
  COALESCE(o.periodo, b.periodo) AS periodo,
  COALESCE(o.ramo_id, b.ramo_id) AS ramo_id,
  COALESCE(o.moneda, b.moneda) AS moneda,
  COALESCE(o.metrica, b.metrica) AS metrica,
  o.valor AS valor_origen,
  b.valor AS valor_bronce,
  ROUND(COALESCE(b.valor, 0) - COALESCE(o.valor, 0), 2) AS diferencia,
  CASE
    WHEN COALESCE(o.metrica, b.metrica) = 'CANTIDAD_REGISTROS' THEN CAST(0 AS NUMERIC)
    ELSE CAST(0.01 AS NUMERIC)
  END AS tolerancia,
  CASE
    WHEN ABS(COALESCE(b.valor, 0) - COALESCE(o.valor, 0)) <=
      CASE
        WHEN COALESCE(o.metrica, b.metrica) = 'CANTIDAD_REGISTROS' THEN CAST(0 AS NUMERIC)
        ELSE CAST(0.01 AS NUMERIC)
      END
      THEN 'OK'
    ELSE 'DIFERENCIA'
  END AS estado_cuadratura,
  COALESCE(o.carga_id, b.carga_id) AS carga_id,
  GREATEST(o.fecha_control, b.fecha_control) AS fecha_control
FROM origen AS o
FULL OUTER JOIN bronce AS b
  ON o.tabla = b.tabla
 AND o.periodo = b.periodo
 AND o.ramo_id = b.ramo_id
 AND o.moneda = b.moneda
 AND o.metrica = b.metrica;

CREATE OR REPLACE VIEW `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura` AS
WITH
pagos_origen AS (
  SELECT
    pago_id AS clave_registro,
    COUNT(*) AS cantidad,
    ROUND(SUM(importe_pagado), 2) AS monto
  FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas`
  GROUP BY 1
),
pagos_bronce AS (
  SELECT
    pago_id AS clave_registro,
    COUNT(*) AS cantidad,
    ROUND(SUM(importe_pagado), 2) AS monto
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.pagos_primas`
  GROUP BY 1
),
siniestros_origen AS (
  SELECT
    siniestro_id AS clave_registro,
    COUNT(*) AS cantidad,
    ROUND(SUM(monto_reserva), 2) AS monto
  FROM `${PROJECT_ID}.${DATASET_ID}.siniestros`
  GROUP BY 1
),
siniestros_bronce AS (
  SELECT
    siniestro_id AS clave_registro,
    COUNT(*) AS cantidad,
    ROUND(SUM(monto_reserva), 2) AS monto
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
  GROUP BY 1
),
excepciones_pagos AS (
  SELECT
    'pagos_primas' AS tabla,
    COALESCE(o.clave_registro, b.clave_registro) AS clave_registro,
    CASE
      WHEN b.clave_registro IS NULL THEN 'FALTANTE_BRONCE'
      WHEN o.clave_registro IS NULL THEN 'EXTRA_BRONCE'
      WHEN b.cantidad > o.cantidad THEN 'DUPLICADO_BRONCE'
      WHEN ABS(b.monto - o.monto) > CAST(0.01 AS NUMERIC) THEN 'MONTO_DIFERENTE'
      ELSE 'OK'
    END AS tipo_excepcion,
    CASE
      WHEN b.clave_registro IS NULL OR o.clave_registro IS NULL OR b.cantidad > o.cantidad THEN 'ALTA'
      WHEN ABS(b.monto - o.monto) > CAST(0.01 AS NUMERIC) THEN 'MEDIA'
      ELSE 'NINGUNA'
    END AS severidad,
    o.cantidad AS cantidad_origen,
    b.cantidad AS cantidad_bronce,
    o.monto AS monto_origen,
    b.monto AS monto_bronce,
    ROUND(COALESCE(b.monto, 0) - COALESCE(o.monto, 0), 2) AS diferencia_monto
  FROM pagos_origen AS o
  FULL OUTER JOIN pagos_bronce AS b USING (clave_registro)
),
excepciones_siniestros AS (
  SELECT
    'siniestros' AS tabla,
    COALESCE(o.clave_registro, b.clave_registro) AS clave_registro,
    CASE
      WHEN b.clave_registro IS NULL THEN 'FALTANTE_BRONCE'
      WHEN o.clave_registro IS NULL THEN 'EXTRA_BRONCE'
      WHEN b.cantidad > o.cantidad THEN 'DUPLICADO_BRONCE'
      WHEN ABS(b.monto - o.monto) > CAST(0.01 AS NUMERIC) THEN 'MONTO_DIFERENTE'
      ELSE 'OK'
    END AS tipo_excepcion,
    CASE
      WHEN b.clave_registro IS NULL OR o.clave_registro IS NULL OR b.cantidad > o.cantidad THEN 'ALTA'
      WHEN ABS(b.monto - o.monto) > CAST(0.01 AS NUMERIC) THEN 'MEDIA'
      ELSE 'NINGUNA'
    END AS severidad,
    o.cantidad AS cantidad_origen,
    b.cantidad AS cantidad_bronce,
    o.monto AS monto_origen,
    b.monto AS monto_bronce,
    ROUND(COALESCE(b.monto, 0) - COALESCE(o.monto, 0), 2) AS diferencia_monto
  FROM siniestros_origen AS o
  FULL OUTER JOIN siniestros_bronce AS b USING (clave_registro)
),
movimientos_huerfanos AS (
  SELECT
    'movimientos_siniestro' AS tabla,
    m.movimiento_id AS clave_registro,
    'SINIESTRO_FALTANTE_BRONCE' AS tipo_excepcion,
    'ALTA' AS severidad,
    CAST(1 AS INT64) AS cantidad_origen,
    CAST(1 AS INT64) AS cantidad_bronce,
    CAST(NULL AS NUMERIC) AS monto_origen,
    m.monto_movimiento AS monto_bronce,
    CAST(NULL AS NUMERIC) AS diferencia_monto
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.movimientos_siniestro` AS m
  LEFT JOIN (
    SELECT DISTINCT siniestro_id
    FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
  ) AS s
    ON m.siniestro_id = s.siniestro_id
  WHERE s.siniestro_id IS NULL
)
SELECT *, '${BRONZE_LOAD_ID}' AS carga_id
FROM excepciones_pagos
WHERE tipo_excepcion != 'OK'
UNION ALL
SELECT *, '${BRONZE_LOAD_ID}'
FROM excepciones_siniestros
WHERE tipo_excepcion != 'OK'
UNION ALL
SELECT *, '${BRONZE_LOAD_ID}'
FROM movimientos_huerfanos;

CREATE OR REPLACE VIEW `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_resumen_cuadratura` AS
SELECT
  tabla,
  tipo_excepcion,
  severidad,
  COUNT(*) AS cantidad_excepciones,
  ROUND(SUM(ABS(COALESCE(diferencia_monto, 0))), 2) AS impacto_monetario_absoluto,
  carga_id
FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
GROUP BY 1, 2, 3, 6;
