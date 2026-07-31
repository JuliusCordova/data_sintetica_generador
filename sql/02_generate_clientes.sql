CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.clientes`
PARTITION BY fecha_registro
CLUSTER BY departamento, tipo_documento AS
WITH base AS (
  SELECT
    n,
    ['Ana', 'Luis', 'María', 'Carlos', 'Lucía', 'Jorge', 'Valeria', 'Diego', 'Camila', 'Andrés'][OFFSET(MOD(n - 1, 10))] AS nombres,
    ['García', 'Rodríguez', 'López', 'Martínez', 'Sánchez', 'Pérez', 'Torres', 'Flores', 'Ramírez', 'Vargas'][OFFSET(MOD(n * 3, 10))] AS apellido_paterno,
    ['Quispe', 'Rojas', 'Mendoza', 'Castillo', 'Chávez', 'Díaz', 'Romero', 'Silva', 'Cruz', 'Reyes'][OFFSET(MOD(n * 7, 10))] AS apellido_materno,
    ['Lima', 'Arequipa', 'La Libertad', 'Piura', 'Cusco', 'Junín', 'Lambayeque', 'Áncash', 'Ica', 'Cajamarca'][OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('DEP-', CAST(n AS STRING)))), 10))] AS departamento
  FROM UNNEST(GENERATE_ARRAY(1, 100000)) AS n
),
enriched AS (
  SELECT
    *,
    CASE WHEN MOD(n, 20) = 0 THEN 'CE' ELSE 'DNI' END AS tipo_documento,
    DATE_ADD(
      DATE '1950-01-01',
      INTERVAL MOD(ABS(FARM_FINGERPRINT(CONCAT('NAC-', CAST(n AS STRING)))), 19358) DAY
    ) AS fecha_nacimiento,
    DATE_ADD(
      DATE '2023-01-01',
      INTERVAL MOD(ABS(FARM_FINGERPRINT(CONCAT('REG-', CAST(n AS STRING)))), 1277) DAY
    ) AS fecha_registro
  FROM base
)
SELECT
  FORMAT('CLI-%06d', n) AS cliente_id,
  tipo_documento,
  CASE
    WHEN MOD(n, 100) = 0 THEN FORMAT('%07d', MOD(n, 10000000))
    WHEN tipo_documento = 'CE' THEN CONCAT('CE', FORMAT('%07d', MOD(ABS(FARM_FINGERPRINT(CONCAT('DOC-', CAST(n AS STRING)))), 10000000)))
    ELSE FORMAT('%08d', MOD(ABS(FARM_FINGERPRINT(CONCAT('DOC-', CAST(n AS STRING)))), 100000000))
  END AS numero_documento,
  nombres,
  apellido_paterno,
  apellido_materno,
  CASE WHEN MOD(n, 2) = 0 THEN 'F' ELSE 'M' END AS sexo,
  fecha_nacimiento,
  CASE
    WHEN MOD(n, 50) = 0 THEN CONCAT(LOWER(nombres), '.', n, '@correo_invalido')
    ELSE CONCAT(LOWER(nombres), '.', LOWER(apellido_paterno), n, '@demo-seguros.pe')
  END AS correo,
  CASE
    WHEN MOD(n, 67) = 0 THEN CAST(NULL AS STRING)
    ELSE CONCAT('9', FORMAT('%08d', MOD(ABS(FARM_FINGERPRINT(CONCAT('TEL-', CAST(n AS STRING)))), 100000000)))
  END AS telefono,
  departamento,
  CONCAT('Provincia ', departamento) AS provincia,
  CASE MOD(n, 5)
    WHEN 0 THEN 'DEPENDIENTE'
    WHEN 1 THEN 'INDEPENDIENTE'
    WHEN 2 THEN 'EMPRESARIO'
    WHEN 3 THEN 'JUBILADO'
    ELSE 'ESTUDIANTE'
  END AS ocupacion,
  CAST(1200 + MOD(ABS(FARM_FINGERPRINT(CONCAT('ING-', CAST(n AS STRING)))), 18801) AS NUMERIC) AS ingreso_mensual_estimado,
  fecha_registro,
  'SYNTHETIC_INSURANCE_CORE' AS sistema_origen,
  CONCAT('${GENERATION_VERSION}', '-initial') AS lote_id,
  TIMESTAMP '2026-07-31 00:00:00+00' AS fecha_carga,
  TRUE AS es_sintetico,
  '${GENERATION_VERSION}' AS version_generador
FROM enriched;
