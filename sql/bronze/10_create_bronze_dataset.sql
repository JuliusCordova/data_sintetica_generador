CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${BRONZE_DATASET_ID}`
OPTIONS (
  location = '${BQ_LOCATION}',
  description = 'Capa Bronze sintética del dominio seguros, preparada para perfilamiento, calidad y cuadratura'
);

CREATE OR REPLACE TABLE `${PROJECT_ID}.${BRONZE_DATASET_ID}.manifiesto_carga`
PARTITION BY DATE(fecha_inicio)
CLUSTER BY estado, dataset_origen AS
SELECT
  '${BRONZE_LOAD_ID}' AS carga_id,
  '${PROJECT_ID}' AS proyecto_id,
  '${DATASET_ID}' AS dataset_origen,
  '${BRONZE_DATASET_ID}' AS dataset_destino,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS fecha_inicio,
  TIMESTAMP '${BRONZE_LOAD_TIMESTAMP}' AS fecha_fin,
  'COMPLETADA' AS estado,
  'FULL_SNAPSHOT' AS tipo_carga,
  '${GENERATION_VERSION}' AS version_generador,
  TRUE AS contiene_diferencias_controladas,
  'Carga sintética reproducible para demostración de cuadratura' AS observacion;
