CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.cat_ramo_seguro` AS
SELECT * FROM UNNEST([
  STRUCT('RAM-VEH' AS ramo_id, 'Vehicular' AS nombre_ramo, TRUE AS activo),
  STRUCT('RAM-SAL', 'Salud', TRUE),
  STRUCT('RAM-VID', 'Vida', TRUE),
  STRUCT('RAM-HOG', 'Hogar', TRUE)
]);

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.cat_producto` AS
SELECT * FROM UNNEST([
  STRUCT('PROD-VEH-01' AS producto_id, 'RAM-VEH' AS ramo_id, 'Auto Esencial' AS nombre_producto, 'PEN' AS moneda, 'MENSUAL' AS periodicidad, CAST(1200.00 AS NUMERIC) AS prima_base),
  STRUCT('PROD-VEH-02', 'RAM-VEH', 'Auto Integral', 'PEN', 'MENSUAL', CAST(1850.00 AS NUMERIC)),
  STRUCT('PROD-VEH-03', 'RAM-VEH', 'Auto Premium', 'USD', 'ANUAL', CAST(950.00 AS NUMERIC)),
  STRUCT('PROD-SAL-01', 'RAM-SAL', 'Salud Familiar', 'PEN', 'MENSUAL', CAST(2400.00 AS NUMERIC)),
  STRUCT('PROD-SAL-02', 'RAM-SAL', 'Salud Plus', 'PEN', 'MENSUAL', CAST(3900.00 AS NUMERIC)),
  STRUCT('PROD-SAL-03', 'RAM-SAL', 'Salud Senior', 'PEN', 'MENSUAL', CAST(5200.00 AS NUMERIC)),
  STRUCT('PROD-VID-01', 'RAM-VID', 'Vida Temporal', 'PEN', 'MENSUAL', CAST(780.00 AS NUMERIC)),
  STRUCT('PROD-VID-02', 'RAM-VID', 'Vida Protección', 'USD', 'ANUAL', CAST(620.00 AS NUMERIC)),
  STRUCT('PROD-VID-03', 'RAM-VID', 'Vida Ahorro', 'USD', 'ANUAL', CAST(1100.00 AS NUMERIC)),
  STRUCT('PROD-HOG-01', 'RAM-HOG', 'Hogar Básico', 'PEN', 'ANUAL', CAST(680.00 AS NUMERIC)),
  STRUCT('PROD-HOG-02', 'RAM-HOG', 'Hogar Integral', 'PEN', 'ANUAL', CAST(1250.00 AS NUMERIC)),
  STRUCT('PROD-HOG-03', 'RAM-HOG', 'Hogar Premium', 'USD', 'ANUAL', CAST(780.00 AS NUMERIC))
]);

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.cat_canal` AS
SELECT * FROM UNNEST([
  STRUCT('CAN-01' AS canal_id, 'Web' AS nombre_canal, 'DIGITAL' AS tipo_canal),
  STRUCT('CAN-02', 'Aplicación móvil', 'DIGITAL'),
  STRUCT('CAN-03', 'Agencia', 'PRESENCIAL'),
  STRUCT('CAN-04', 'Corredor', 'INTERMEDIARIO'),
  STRUCT('CAN-05', 'Call center', 'REMOTO'),
  STRUCT('CAN-06', 'Fuerza de ventas', 'PRESENCIAL'),
  STRUCT('CAN-07', 'Aliados comerciales', 'INTERMEDIARIO'),
  STRUCT('CAN-08', 'Banca seguros', 'INTERMEDIARIO')
]);

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.cat_estado_poliza` AS
SELECT * FROM UNNEST([
  STRUCT('EP-01' AS estado_poliza_id, 'VIGENTE' AS nombre_estado, TRUE AS activo),
  STRUCT('EP-02', 'VENCIDA', TRUE),
  STRUCT('EP-03', 'CANCELADA', TRUE),
  STRUCT('EP-04', 'SUSPENDIDA', TRUE),
  STRUCT('EP-05', 'PENDIENTE', TRUE),
  STRUCT('EP-06', 'RENOVADA', TRUE)
]);

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.cat_estado_siniestro` AS
SELECT * FROM UNNEST([
  STRUCT('ES-01' AS estado_siniestro_id, 'REPORTADO' AS nombre_estado, TRUE AS activo),
  STRUCT('ES-02', 'EN_EVALUACION', TRUE),
  STRUCT('ES-03', 'OBSERVADO', TRUE),
  STRUCT('ES-04', 'APROBADO', TRUE),
  STRUCT('ES-05', 'RECHAZADO', TRUE),
  STRUCT('ES-06', 'PAGADO', TRUE),
  STRUCT('ES-07', 'CERRADO', TRUE)
]);

CREATE OR REPLACE TABLE `${PROJECT_ID}.${DATASET_ID}.cat_tipo_siniestro` AS
SELECT * FROM UNNEST([
  STRUCT('TS-V01' AS tipo_siniestro_id, 'RAM-VEH' AS ramo_id, 'Choque' AS nombre_tipo),
  STRUCT('TS-V02', 'RAM-VEH', 'Robo total'),
  STRUCT('TS-V03', 'RAM-VEH', 'Daño a terceros'),
  STRUCT('TS-S01', 'RAM-SAL', 'Hospitalización'),
  STRUCT('TS-S02', 'RAM-SAL', 'Emergencia'),
  STRUCT('TS-S03', 'RAM-SAL', 'Cirugía'),
  STRUCT('TS-L01', 'RAM-VID', 'Fallecimiento'),
  STRUCT('TS-L02', 'RAM-VID', 'Invalidez'),
  STRUCT('TS-L03', 'RAM-VID', 'Enfermedad grave'),
  STRUCT('TS-H01', 'RAM-HOG', 'Incendio'),
  STRUCT('TS-H02', 'RAM-HOG', 'Robo domiciliario'),
  STRUCT('TS-H03', 'RAM-HOG', 'Daño por agua')
]);
