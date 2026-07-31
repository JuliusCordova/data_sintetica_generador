CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.polizas`
PARTITION BY fecha_emision
CLUSTER BY cliente_id, producto_id, estado_poliza_id AS
SELECT
  src.*,
  CONCAT('BR-', src.poliza_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'polizas_0001.parquet' AS bronze_archivo_origen,
  CAST(SUBSTR(src.poliza_id, 5) AS INT64) AS bronze_numero_fila_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_registro,
  'RECIBIDO' AS bronze_estado_registro,
  CAST(NULL AS STRING) AS bronze_motivo_observacion
FROM `${PROJECT_ID}.${DATASET_ID}.polizas` AS src;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.pagos_primas`
PARTITION BY fecha_vencimiento
CLUSTER BY poliza_id, estado_pago, bronze_estado_registro AS
WITH source_rows AS (
  SELECT
    src.*,
    CAST(SUBSTR(src.pago_id, 5) AS INT64) AS numero_origen,
    TO_HEX(SHA256(TO_JSON_STRING(src))) AS hash_origen
  FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas` AS src
),
regular AS (
  SELECT
    src.* EXCEPT(numero_origen, hash_origen)
      REPLACE (
        CASE
          WHEN MOD(src.numero_origen, 60000) = 29
            THEN ROUND(src.importe_pagado + CAST(1.50 AS NUMERIC), 2)
          ELSE src.importe_pagado
        END AS importe_pagado
      ),
    CONCAT('BR-', src.pago_id) AS bronze_registro_id,
    '${BRONZE_LOAD_ID}' AS bronze_carga_id,
    TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
    'pagos_primas_0001.parquet' AS bronze_archivo_origen,
    src.numero_origen AS bronze_numero_fila_origen,
    src.hash_origen AS bronze_hash_origen,
    TO_HEX(SHA256(CONCAT(
      src.pago_id, '|',
      CAST(
        CASE
          WHEN MOD(src.numero_origen, 60000) = 29
            THEN ROUND(src.importe_pagado + CAST(1.50 AS NUMERIC), 2)
          ELSE src.importe_pagado
        END AS STRING
      )
    ))) AS bronze_hash_registro,
    CASE
      WHEN MOD(src.numero_origen, 60000) = 29 THEN 'MONTO_ALTERADO_CONTROLADO'
      ELSE 'RECIBIDO'
    END AS bronze_estado_registro,
    CASE
      WHEN MOD(src.numero_origen, 60000) = 29
        THEN 'Importe pagado incrementado en PEN/USD 1.50 para la demo de cuadratura'
      ELSE CAST(NULL AS STRING)
    END AS bronze_motivo_observacion
  FROM source_rows AS src
  WHERE MOD(src.numero_origen, 48000) != 17
),
duplicados AS (
  SELECT
    src.* EXCEPT(numero_origen, hash_origen),
    CONCAT('BR-DUP-', src.pago_id) AS bronze_registro_id,
    '${BRONZE_LOAD_ID}' AS bronze_carga_id,
    TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
    'pagos_primas_0001_reproceso.parquet' AS bronze_archivo_origen,
    src.numero_origen AS bronze_numero_fila_origen,
    src.hash_origen AS bronze_hash_origen,
    TO_HEX(SHA256(CONCAT(src.pago_id, '|', CAST(src.importe_pagado AS STRING)))) AS bronze_hash_registro,
    'DUPLICADO_CONTROLADO' AS bronze_estado_registro,
    'Registro repetido por reproceso simulado del archivo' AS bronze_motivo_observacion
  FROM source_rows AS src
  WHERE MOD(src.numero_origen, 80000) = 43
)
SELECT * FROM regular
UNION ALL
SELECT * FROM duplicados;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
PARTITION BY fecha_ocurrencia
CLUSTER BY poliza_id, estado_siniestro_id, bronze_estado_registro AS
WITH source_rows AS (
  SELECT
    src.*,
    CAST(SUBSTR(src.siniestro_id, 5) AS INT64) AS numero_origen,
    TO_HEX(SHA256(TO_JSON_STRING(src))) AS hash_origen
  FROM `${PROJECT_ID}.${DATASET_ID}.siniestros` AS src
),
regular AS (
  SELECT
    src.* EXCEPT(numero_origen, hash_origen)
      REPLACE (
        CASE
          WHEN MOD(src.numero_origen, 12500) = 29
            THEN ROUND(src.monto_reserva + CAST(100.00 AS NUMERIC), 2)
          ELSE src.monto_reserva
        END AS monto_reserva
      ),
    CONCAT('BR-', src.siniestro_id) AS bronze_registro_id,
    '${BRONZE_LOAD_ID}' AS bronze_carga_id,
    TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
    'siniestros_0001.parquet' AS bronze_archivo_origen,
    src.numero_origen AS bronze_numero_fila_origen,
    src.hash_origen AS bronze_hash_origen,
    TO_HEX(SHA256(CONCAT(
      src.siniestro_id, '|',
      CAST(
        CASE
          WHEN MOD(src.numero_origen, 12500) = 29
            THEN ROUND(src.monto_reserva + CAST(100.00 AS NUMERIC), 2)
          ELSE src.monto_reserva
        END AS STRING
      )
    ))) AS bronze_hash_registro,
    CASE
      WHEN MOD(src.numero_origen, 12500) = 29 THEN 'MONTO_ALTERADO_CONTROLADO'
      ELSE 'RECIBIDO'
    END AS bronze_estado_registro,
    CASE
      WHEN MOD(src.numero_origen, 12500) = 29
        THEN 'Reserva incrementada en 100.00 para la demo de cuadratura'
      ELSE CAST(NULL AS STRING)
    END AS bronze_motivo_observacion
  FROM source_rows AS src
  WHERE MOD(src.numero_origen, 10000) != 17
),
duplicados AS (
  SELECT
    src.* EXCEPT(numero_origen, hash_origen),
    CONCAT('BR-DUP-', src.siniestro_id) AS bronze_registro_id,
    '${BRONZE_LOAD_ID}' AS bronze_carga_id,
    TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
    'siniestros_0001_reproceso.parquet' AS bronze_archivo_origen,
    src.numero_origen AS bronze_numero_fila_origen,
    src.hash_origen AS bronze_hash_origen,
    TO_HEX(SHA256(CONCAT(src.siniestro_id, '|', CAST(src.monto_reserva AS STRING)))) AS bronze_hash_registro,
    'DUPLICADO_CONTROLADO' AS bronze_estado_registro,
    'Registro repetido por reproceso simulado del archivo' AS bronze_motivo_observacion
  FROM source_rows AS src
  WHERE MOD(src.numero_origen, 20000) = 43
)
SELECT * FROM regular
UNION ALL
SELECT * FROM duplicados;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.movimientos_siniestro`
PARTITION BY fecha_movimiento
CLUSTER BY siniestro_id, tipo_movimiento AS
SELECT
  src.*,
  CONCAT('BR-', src.movimiento_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'movimientos_siniestro_0001.parquet' AS bronze_archivo_origen,
  CAST(SUBSTR(src.movimiento_id, 5) AS INT64) AS bronze_numero_fila_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_registro,
  'RECIBIDO' AS bronze_estado_registro,
  CAST(NULL AS STRING) AS bronze_motivo_observacion
FROM `${PROJECT_ID}.${DATASET_ID}.movimientos_siniestro` AS src;
