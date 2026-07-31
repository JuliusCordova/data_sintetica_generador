CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.pagos_primas`
PARTITION BY fecha_vencimiento
CLUSTER BY poliza_id, estado_pago AS
WITH expanded AS (
  SELECT
    p.*,
    cuota,
    ((CAST(SUBSTR(p.poliza_id, 5) AS INT64) - 1) * 8) + cuota AS pago_num,
    DATE_ADD(p.fecha_inicio_vigencia, INTERVAL cuota - 1 MONTH) AS fecha_vencimiento
  FROM `${PROJECT_ID}.${DATASET_ID}.polizas` AS p
  CROSS JOIN UNNEST(GENERATE_ARRAY(1, 8)) AS cuota
),
prepared AS (
  SELECT
    *,
    CASE
      WHEN MOD(pago_num, 50) = 0 THEN CAST(NULL AS DATE)
      ELSE DATE_ADD(fecha_vencimiento, INTERVAL MOD(pago_num, 15) - 5 DAY)
    END AS fecha_pago
  FROM expanded
)
SELECT
  FORMAT('PAG-%010d', pago_num) AS pago_id,
  poliza_id,
  cuota AS numero_cuota,
  fecha_vencimiento,
  fecha_pago,
  CASE
    WHEN fecha_pago IS NOT NULL THEN 'PAGADO'
    WHEN fecha_vencimiento <= DATE '2026-06-30' THEN 'VENCIDO'
    ELSE 'PENDIENTE'
  END AS estado_pago,
  moneda,
  ROUND(prima_total / 8, 2) AS importe_programado,
  CASE
    WHEN fecha_pago IS NULL THEN CAST(0 AS NUMERIC)
    ELSE ROUND(prima_total / 8, 2)
  END AS importe_pagado,
  CASE MOD(pago_num, 6)
    WHEN 0 THEN 'TARJETA_CREDITO'
    WHEN 1 THEN 'TARJETA_DEBITO'
    WHEN 2 THEN 'TRANSFERENCIA'
    WHEN 3 THEN 'DEBITO_AUTOMATICO'
    WHEN 4 THEN 'BANCA_MOVIL'
    ELSE 'VENTANILLA'
  END AS medio_pago,
  CONCAT('OPE-', FORMAT('%012d', ABS(FARM_FINGERPRINT(CONCAT('OPE-', CAST(pago_num AS STRING)))))) AS numero_operacion,
  'SYNTHETIC_INSURANCE_CORE' AS sistema_origen,
  CONCAT('${GENERATION_VERSION}', '-initial') AS lote_id,
  TIMESTAMP '2026-07-31 00:00:00+00' AS fecha_carga,
  TRUE AS es_sintetico,
  '${GENERATION_VERSION}' AS version_generador
FROM prepared;
