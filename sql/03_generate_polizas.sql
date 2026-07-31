CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.polizas`
PARTITION BY fecha_emision
CLUSTER BY cliente_id, producto_id, estado_poliza_id AS
WITH base AS (
  SELECT
    n,
    MOD(n - 1, 20) AS ramo_bucket,
    DATE_ADD(
      DATE '2023-01-01',
      INTERVAL MOD(ABS(FARM_FINGERPRINT(CONCAT('EMI-', CAST(n AS STRING)))), 1095) DAY
    ) AS fecha_emision
  FROM UNNEST(GENERATE_ARRAY(1, 150000)) AS n
),
classified AS (
  SELECT
    *,
    CASE
      WHEN ramo_bucket < 7 THEN 'RAM-VEH'
      WHEN ramo_bucket < 13 THEN 'RAM-SAL'
      WHEN ramo_bucket < 17 THEN 'RAM-VID'
      ELSE 'RAM-HOG'
    END AS ramo_id
  FROM base
),
prepared AS (
  SELECT
    *,
    CASE ramo_id
      WHEN 'RAM-VEH' THEN CONCAT('PROD-VEH-0', CAST(1 + MOD(n, 3) AS STRING))
      WHEN 'RAM-SAL' THEN CONCAT('PROD-SAL-0', CAST(1 + MOD(n, 3) AS STRING))
      WHEN 'RAM-VID' THEN CONCAT('PROD-VID-0', CAST(1 + MOD(n, 3) AS STRING))
      ELSE CONCAT('PROD-HOG-0', CAST(1 + MOD(n, 3) AS STRING))
    END AS producto_id,
    DATE_ADD(fecha_emision, INTERVAL 1 + MOD(n, 15) DAY) AS fecha_inicio_vigencia
  FROM classified
)
SELECT
  FORMAT('POL-%09d', x.n) AS poliza_id,
  FORMAT(
    'CLI-%06d',
    1 + MOD(ABS(FARM_FINGERPRINT(CONCAT('CLI-POL-', CAST(x.n AS STRING)))), 100000)
  ) AS cliente_id,
  x.ramo_id,
  x.producto_id,
  CONCAT('CAN-0', CAST(1 + MOD(ABS(FARM_FINGERPRINT(CONCAT('CAN-', CAST(x.n AS STRING)))), 8) AS STRING)) AS canal_id,
  CASE
    WHEN MOD(x.n, 100) < 65 THEN 'EP-01'
    WHEN MOD(x.n, 100) < 75 THEN 'EP-06'
    WHEN MOD(x.n, 100) < 85 THEN 'EP-02'
    WHEN MOD(x.n, 100) < 92 THEN 'EP-03'
    WHEN MOD(x.n, 100) < 96 THEN 'EP-04'
    ELSE 'EP-05'
  END AS estado_poliza_id,
  x.fecha_emision,
  x.fecha_inicio_vigencia,
  CASE
    WHEN MOD(x.n, 200) = 0 THEN DATE_SUB(x.fecha_inicio_vigencia, INTERVAL 1 DAY)
    ELSE DATE_ADD(x.fecha_inicio_vigencia, INTERVAL 364 DAY)
  END AS fecha_fin_vigencia,
  p.moneda,
  ROUND(
    p.prima_base * (CAST(85 + MOD(ABS(FARM_FINGERPRINT(CONCAT('PRI-', CAST(x.n AS STRING)))), 31) AS NUMERIC) / 100),
    2
  ) AS prima_total,
  CAST(
    CASE x.ramo_id
      WHEN 'RAM-VEH' THEN 35000 + MOD(ABS(FARM_FINGERPRINT(CONCAT('SUM-', CAST(x.n AS STRING)))), 120001)
      WHEN 'RAM-SAL' THEN 50000 + MOD(ABS(FARM_FINGERPRINT(CONCAT('SUM-', CAST(x.n AS STRING)))), 450001)
      WHEN 'RAM-VID' THEN 100000 + MOD(ABS(FARM_FINGERPRINT(CONCAT('SUM-', CAST(x.n AS STRING)))), 900001)
      ELSE 80000 + MOD(ABS(FARM_FINGERPRINT(CONCAT('SUM-', CAST(x.n AS STRING)))), 520001)
    END AS NUMERIC
  ) AS suma_asegurada,
  CAST(
    CASE x.ramo_id
      WHEN 'RAM-VEH' THEN 500 + MOD(x.n, 2501)
      WHEN 'RAM-SAL' THEN 100 + MOD(x.n, 901)
      WHEN 'RAM-HOG' THEN 300 + MOD(x.n, 1701)
      ELSE 0
    END AS NUMERIC
  ) AS deducible,
  CASE WHEN MOD(x.n, 5) = 0 THEN 'ANUAL' ELSE 'MENSUAL' END AS frecuencia_pago,
  'SYNTHETIC_INSURANCE_CORE' AS sistema_origen,
  CONCAT('${GENERATION_VERSION}', '-initial') AS lote_id,
  TIMESTAMP '2026-07-31 00:00:00+00' AS fecha_carga,
  TRUE AS es_sintetico,
  '${GENERATION_VERSION}' AS version_generador
FROM prepared AS x
JOIN `${PROJECT_ID}.${DATASET_ID}.cat_producto` AS p
  ON x.producto_id = p.producto_id;
