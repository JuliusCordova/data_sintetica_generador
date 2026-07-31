CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.cat_ramo_seguro` AS
SELECT
  src.*,
  CONCAT('BR-', src.ramo_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'cat_ramo_seguro.parquet' AS bronze_archivo_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  'RECIBIDO' AS bronze_estado_registro
FROM `${PROJECT_ID}.${DATASET_ID}.cat_ramo_seguro` AS src;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.cat_producto` AS
SELECT
  src.*,
  CONCAT('BR-', src.producto_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'cat_producto.parquet' AS bronze_archivo_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  'RECIBIDO' AS bronze_estado_registro
FROM `${PROJECT_ID}.${DATASET_ID}.cat_producto` AS src;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.cat_canal` AS
SELECT
  src.*,
  CONCAT('BR-', src.canal_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'cat_canal.parquet' AS bronze_archivo_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  'RECIBIDO' AS bronze_estado_registro
FROM `${PROJECT_ID}.${DATASET_ID}.cat_canal` AS src;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.cat_estado_poliza` AS
SELECT
  src.*,
  CONCAT('BR-', src.estado_poliza_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'cat_estado_poliza.parquet' AS bronze_archivo_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  'RECIBIDO' AS bronze_estado_registro
FROM `${PROJECT_ID}.${DATASET_ID}.cat_estado_poliza` AS src;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.cat_estado_siniestro` AS
SELECT
  src.*,
  CONCAT('BR-', src.estado_siniestro_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'cat_estado_siniestro.parquet' AS bronze_archivo_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  'RECIBIDO' AS bronze_estado_registro
FROM `${PROJECT_ID}.${DATASET_ID}.cat_estado_siniestro` AS src;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.cat_tipo_siniestro` AS
SELECT
  src.*,
  CONCAT('BR-', src.tipo_siniestro_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'cat_tipo_siniestro.parquet' AS bronze_archivo_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  'RECIBIDO' AS bronze_estado_registro
FROM `${PROJECT_ID}.${DATASET_ID}.cat_tipo_siniestro` AS src;

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.clientes`
CLUSTER BY cliente_id AS
SELECT
  src.*,
  CONCAT('BR-', src.cliente_id) AS bronze_registro_id,
  '${BRONZE_LOAD_ID}' AS bronze_carga_id,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS bronze_fecha_ingesta,
  'clientes_0001.parquet' AS bronze_archivo_origen,
  CAST(SUBSTR(src.cliente_id, 5) AS INT64) AS bronze_numero_fila_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_origen,
  TO_HEX(SHA256(TO_JSON_STRING(src))) AS bronze_hash_registro,
  'RECIBIDO' AS bronze_estado_registro,
  CAST(NULL AS STRING) AS bronze_motivo_observacion
FROM `${PROJECT_ID}.${DATASET_ID}.clientes` AS src;
