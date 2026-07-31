ASSERT (
  SELECT COUNT(*) = 4
  FROM `${PROJECT_ID}.${DATASET_ID}.cat_ramo_seguro`
) AS 'cat_ramo_seguro debe contener 4 filas';

ASSERT (
  SELECT COUNT(*) = 12
  FROM `${PROJECT_ID}.${DATASET_ID}.cat_producto`
) AS 'cat_producto debe contener 12 filas';

ASSERT (
  SELECT COUNT(*) = 100000
  FROM `${PROJECT_ID}.${DATASET_ID}.clientes`
) AS 'clientes debe contener 100000 filas';

ASSERT (
  SELECT COUNT(*) = 150000
  FROM `${PROJECT_ID}.${DATASET_ID}.polizas`
) AS 'polizas debe contener 150000 filas';

ASSERT (
  SELECT COUNT(*) = 1200000
  FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas`
) AS 'pagos_primas debe contener 1200000 filas';

ASSERT (
  SELECT COUNT(*) = 100000
  FROM `${PROJECT_ID}.${DATASET_ID}.siniestros`
) AS 'siniestros debe contener 100000 filas';

ASSERT (
  SELECT COUNT(*) = 300000
  FROM `${PROJECT_ID}.${DATASET_ID}.movimientos_siniestro`
) AS 'movimientos_siniestro debe contener 300000 filas';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `${PROJECT_ID}.${DATASET_ID}.polizas` AS p
  LEFT JOIN `${PROJECT_ID}.${DATASET_ID}.clientes` AS c
    ON p.cliente_id = c.cliente_id
  WHERE c.cliente_id IS NULL
) AS 'No deben existir pólizas sin cliente';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas` AS pp
  LEFT JOIN `${PROJECT_ID}.${DATASET_ID}.polizas` AS p
    ON pp.poliza_id = p.poliza_id
  WHERE p.poliza_id IS NULL
) AS 'No deben existir pagos sin póliza';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `${PROJECT_ID}.${DATASET_ID}.siniestros` AS s
  LEFT JOIN `${PROJECT_ID}.${DATASET_ID}.polizas` AS p
    ON s.poliza_id = p.poliza_id
  WHERE p.poliza_id IS NULL
) AS 'No deben existir siniestros sin póliza';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `${PROJECT_ID}.${DATASET_ID}.movimientos_siniestro` AS m
  LEFT JOIN `${PROJECT_ID}.${DATASET_ID}.siniestros` AS s
    ON m.siniestro_id = s.siniestro_id
  WHERE s.siniestro_id IS NULL
) AS 'No deben existir movimientos sin siniestro';

ASSERT (
  SELECT COUNT(*) = 0
  FROM (
    SELECT es_sintetico FROM `${PROJECT_ID}.${DATASET_ID}.clientes`
    UNION ALL
    SELECT es_sintetico FROM `${PROJECT_ID}.${DATASET_ID}.polizas`
    UNION ALL
    SELECT es_sintetico FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas`
    UNION ALL
    SELECT es_sintetico FROM `${PROJECT_ID}.${DATASET_ID}.siniestros`
    UNION ALL
    SELECT es_sintetico FROM `${PROJECT_ID}.${DATASET_ID}.movimientos_siniestro`
  )
  WHERE es_sintetico IS NOT TRUE
) AS 'Todos los registros deben estar marcados como sintéticos';

SELECT 'clientes' AS tabla, COUNT(*) AS filas
FROM `${PROJECT_ID}.${DATASET_ID}.clientes`
UNION ALL
SELECT 'polizas', COUNT(*)
FROM `${PROJECT_ID}.${DATASET_ID}.polizas`
UNION ALL
SELECT 'pagos_primas', COUNT(*)
FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas`
UNION ALL
SELECT 'siniestros', COUNT(*)
FROM `${PROJECT_ID}.${DATASET_ID}.siniestros`
UNION ALL
SELECT 'movimientos_siniestro', COUNT(*)
FROM `${PROJECT_ID}.${DATASET_ID}.movimientos_siniestro`
ORDER BY tabla;

SELECT
  (SELECT COUNT(*) FROM `${PROJECT_ID}.${DATASET_ID}.clientes` WHERE NOT REGEXP_CONTAINS(correo, r'^[^@]+@[^@]+\.[^@]+$')) AS correos_invalidos,
  (SELECT COUNT(*) FROM `${PROJECT_ID}.${DATASET_ID}.clientes` WHERE telefono IS NULL) AS telefonos_nulos,
  (SELECT COUNT(*) FROM `${PROJECT_ID}.${DATASET_ID}.polizas` WHERE fecha_fin_vigencia <= fecha_inicio_vigencia) AS polizas_fecha_inconsistente,
  (SELECT COUNT(*) FROM `${PROJECT_ID}.${DATASET_ID}.pagos_primas` WHERE estado_pago = 'VENCIDO') AS pagos_vencidos,
  (SELECT COUNT(*) FROM `${PROJECT_ID}.${DATASET_ID}.siniestros` WHERE monto_reserva > monto_reclamado) AS reservas_atipicas;
