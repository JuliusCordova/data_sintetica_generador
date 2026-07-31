CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.siniestros`
PARTITION BY fecha_ocurrencia
CLUSTER BY poliza_id, estado_siniestro_id, tipo_siniestro_id AS
WITH links AS (
  SELECT
    n,
    FORMAT(
      'POL-%09d',
      1 + MOD(ABS(FARM_FINGERPRINT(CONCAT('POL-SIN-', CAST(n AS STRING)))), 150000)
    ) AS poliza_id
  FROM UNNEST(GENERATE_ARRAY(1, 100000)) AS n
),
joined AS (
  SELECT l.n, p.*
  FROM links AS l
  JOIN `${PROJECT_ID}.${DATASET_ID}.polizas` AS p
    ON l.poliza_id = p.poliza_id
),
classified AS (
  SELECT
    *,
    CASE ramo_id
      WHEN 'RAM-VEH' THEN CONCAT('TS-V0', CAST(1 + MOD(n, 3) AS STRING))
      WHEN 'RAM-SAL' THEN CONCAT('TS-S0', CAST(1 + MOD(n, 3) AS STRING))
      WHEN 'RAM-VID' THEN CONCAT('TS-L0', CAST(1 + MOD(n, 3) AS STRING))
      ELSE CONCAT('TS-H0', CAST(1 + MOD(n, 3) AS STRING))
    END AS tipo_siniestro_id,
    CASE
      WHEN MOD(n, 100) < 8 THEN 'ES-01'
      WHEN MOD(n, 100) < 23 THEN 'ES-02'
      WHEN MOD(n, 100) < 33 THEN 'ES-03'
      WHEN MOD(n, 100) < 48 THEN 'ES-04'
      WHEN MOD(n, 100) < 58 THEN 'ES-05'
      WHEN MOD(n, 100) < 78 THEN 'ES-06'
      ELSE 'ES-07'
    END AS estado_siniestro_id,
    DATE_ADD(
      fecha_inicio_vigencia,
      INTERVAL MOD(ABS(FARM_FINGERPRINT(CONCAT('OCU-', CAST(n AS STRING)))), 300) DAY
    ) AS fecha_ocurrencia
  FROM joined
),
amounts AS (
  SELECT
    *,
    DATE_ADD(fecha_ocurrencia, INTERVAL MOD(n, 10) DAY) AS fecha_reporte,
    CAST(
      CASE ramo_id
        WHEN 'RAM-VEH' THEN 1500 + MOD(ABS(FARM_FINGERPRINT(CONCAT('MTO-', CAST(n AS STRING)))), 98501)
        WHEN 'RAM-SAL' THEN 500 + MOD(ABS(FARM_FINGERPRINT(CONCAT('MTO-', CAST(n AS STRING)))), 149501)
        WHEN 'RAM-VID' THEN 25000 + MOD(ABS(FARM_FINGERPRINT(CONCAT('MTO-', CAST(n AS STRING)))), 975001)
        ELSE 1000 + MOD(ABS(FARM_FINGERPRINT(CONCAT('MTO-', CAST(n AS STRING)))), 299001)
      END AS NUMERIC
    ) AS monto_reclamado
  FROM classified
)
SELECT
  FORMAT('SIN-%09d', n) AS siniestro_id,
  poliza_id,
  cliente_id,
  ramo_id,
  tipo_siniestro_id,
  estado_siniestro_id,
  fecha_ocurrencia,
  fecha_reporte,
  moneda,
  monto_reclamado,
  ROUND(
    monto_reclamado *
    CASE
      WHEN MOD(n, 100) = 0 THEN CAST(1.75 AS NUMERIC)
      ELSE CAST(70 + MOD(n, 31) AS NUMERIC) / 100
    END,
    2
  ) AS monto_reserva,
  CASE
    WHEN estado_siniestro_id IN ('ES-04', 'ES-06', 'ES-07')
      THEN ROUND(monto_reclamado * (CAST(75 + MOD(n, 26) AS NUMERIC) / 100), 2)
    WHEN estado_siniestro_id = 'ES-05' THEN CAST(0 AS NUMERIC)
    ELSE CAST(NULL AS NUMERIC)
  END AS monto_indemnizado,
  ROUND(CAST(MOD(ABS(FARM_FINGERPRINT(CONCAT('FRA-', CAST(n AS STRING)))), 1001) AS NUMERIC) / 1000, 3) AS score_fraude,
  CASE MOD(n, 5)
    WHEN 0 THEN 'LIMA'
    WHEN 1 THEN 'AREQUIPA'
    WHEN 2 THEN 'LA_LIBERTAD'
    WHEN 3 THEN 'PIURA'
    ELSE 'CUSCO'
  END AS departamento_evento,
  CONCAT('Evento sintético de ', LOWER(ramo_id), ' asociado a la póliza ', poliza_id) AS descripcion_evento,
  'SYNTHETIC_INSURANCE_CORE' AS sistema_origen,
  CONCAT('${GENERATION_VERSION}', '-initial') AS lote_id,
  TIMESTAMP '2026-07-31 00:00:00+00' AS fecha_carga,
  TRUE AS es_sintetico,
  '${GENERATION_VERSION}' AS version_generador
FROM amounts;
