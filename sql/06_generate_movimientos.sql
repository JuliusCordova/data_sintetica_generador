CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.movimientos_siniestro`
PARTITION BY fecha_movimiento
CLUSTER BY siniestro_id, tipo_movimiento AS
WITH expanded AS (
  SELECT
    s.*,
    paso,
    ((CAST(SUBSTR(s.siniestro_id, 5) AS INT64) - 1) * 3) + paso AS movimiento_num
  FROM `${PROJECT_ID}.${DATASET_ID}.siniestros` AS s
  CROSS JOIN UNNEST(GENERATE_ARRAY(1, 3)) AS paso
)
SELECT
  FORMAT('MSI-%010d', movimiento_num) AS movimiento_id,
  siniestro_id,
  poliza_id,
  CASE
    WHEN paso = 1 THEN 'REGISTRO'
    WHEN paso = 2 AND estado_siniestro_id = 'ES-03' THEN 'OBSERVACION'
    WHEN paso = 2 THEN 'EVALUACION'
    WHEN estado_siniestro_id = 'ES-04' THEN 'APROBACION'
    WHEN estado_siniestro_id = 'ES-05' THEN 'RECHAZO'
    WHEN estado_siniestro_id = 'ES-06' THEN 'PAGO'
    WHEN estado_siniestro_id = 'ES-07' THEN 'CIERRE'
    ELSE 'SEGUIMIENTO'
  END AS tipo_movimiento,
  DATE_ADD(fecha_reporte, INTERVAL (paso - 1) * (1 + MOD(movimiento_num, 7)) DAY) AS fecha_movimiento,
  CASE
    WHEN paso = 1 THEN 'Siniestro registrado por el canal de atención'
    WHEN paso = 2 THEN 'Evaluación técnica y actualización de reserva'
    ELSE 'Actualización del estado operacional del siniestro'
  END AS descripcion_movimiento,
  CASE
    WHEN paso = 2 THEN monto_reserva
    WHEN paso = 3 THEN monto_indemnizado
    ELSE CAST(NULL AS NUMERIC)
  END AS monto_movimiento,
  CONCAT('USR-', FORMAT('%04d', 1 + MOD(movimiento_num, 500))) AS usuario_responsable,
  CASE MOD(movimiento_num, 4)
    WHEN 0 THEN 'AJUSTADOR'
    WHEN 1 THEN 'ANALISTA_SINIESTROS'
    WHEN 2 THEN 'MEDICO_AUDITOR'
    ELSE 'SUPERVISOR'
  END AS rol_responsable,
  'SYNTHETIC_INSURANCE_CORE' AS sistema_origen,
  CONCAT('${GENERATION_VERSION}', '-initial') AS lote_id,
  TIMESTAMP '2026-07-31 00:00:00+00' AS fecha_carga,
  TRUE AS es_sintetico,
  '${GENERATION_VERSION}' AS version_generador
FROM expanded;
