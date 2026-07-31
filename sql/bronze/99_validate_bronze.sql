ASSERT (
  SELECT COUNT(*) = 1
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.manifiesto_carga`
  WHERE carga_id = '${BRONZE_LOAD_ID}'
    AND estado = 'COMPLETADA'
) AS 'Debe existir un manifiesto de carga Bronze completado';

ASSERT (
  SELECT COUNT(*) = 100000
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.clientes`
) AS 'Bronze clientes debe contener 100000 filas';

ASSERT (
  SELECT COUNT(*) = 150000
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.polizas`
) AS 'Bronze polizas debe contener 150000 filas';

ASSERT (
  SELECT COUNT(*) = 1199990
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.pagos_primas`
) AS 'Bronze pagos_primas debe contener 1199990 filas por el escenario controlado';

ASSERT (
  SELECT COUNT(*) = 99995
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
) AS 'Bronze siniestros debe contener 99995 filas por el escenario controlado';

ASSERT (
  SELECT COUNT(*) = 300000
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.movimientos_siniestro`
) AS 'Bronze movimientos_siniestro debe contener 300000 filas';

ASSERT (
  SELECT COUNT(*) = 20
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.pagos_primas`
  WHERE bronze_estado_registro = 'MONTO_ALTERADO_CONTROLADO'
) AS 'Deben existir 20 pagos con monto alterado controlado';

ASSERT (
  SELECT COUNT(*) = 15
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.pagos_primas`
  WHERE bronze_estado_registro = 'DUPLICADO_CONTROLADO'
) AS 'Deben existir 15 pagos duplicados controlados';

ASSERT (
  SELECT COUNT(*) = 8
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
  WHERE bronze_estado_registro = 'MONTO_ALTERADO_CONTROLADO'
) AS 'Deben existir 8 siniestros con reserva alterada controlada';

ASSERT (
  SELECT COUNT(*) = 5
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
  WHERE bronze_estado_registro = 'DUPLICADO_CONTROLADO'
) AS 'Deben existir 5 siniestros duplicados controlados';

ASSERT (
  SELECT COUNT(*) = 25
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
  WHERE tabla = 'pagos_primas'
    AND tipo_excepcion = 'FALTANTE_BRONCE'
) AS 'La cuadratura debe detectar 25 pagos faltantes';

ASSERT (
  SELECT COUNT(*) = 15
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
  WHERE tabla = 'pagos_primas'
    AND tipo_excepcion = 'DUPLICADO_BRONCE'
) AS 'La cuadratura debe detectar 15 pagos duplicados';

ASSERT (
  SELECT COUNT(*) = 20
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
  WHERE tabla = 'pagos_primas'
    AND tipo_excepcion = 'MONTO_DIFERENTE'
) AS 'La cuadratura debe detectar 20 pagos con monto diferente';

ASSERT (
  SELECT COUNT(*) = 10
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
  WHERE tabla = 'siniestros'
    AND tipo_excepcion = 'FALTANTE_BRONCE'
) AS 'La cuadratura debe detectar 10 siniestros faltantes';

ASSERT (
  SELECT COUNT(*) = 5
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
  WHERE tabla = 'siniestros'
    AND tipo_excepcion = 'DUPLICADO_BRONCE'
) AS 'La cuadratura debe detectar 5 siniestros duplicados';

ASSERT (
  SELECT COUNT(*) = 8
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
  WHERE tabla = 'siniestros'
    AND tipo_excepcion = 'MONTO_DIFERENTE'
) AS 'La cuadratura debe detectar 8 siniestros con reserva diferente';

ASSERT (
  SELECT COUNT(*) = 30
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
  WHERE tabla = 'movimientos_siniestro'
    AND tipo_excepcion = 'SINIESTRO_FALTANTE_BRONCE'
) AS 'La cuadratura debe detectar 30 movimientos huérfanos';

ASSERT (
  SELECT COUNT(*) = 113
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_excepciones_cuadratura`
) AS 'La demo debe producir exactamente 113 excepciones detalladas';

ASSERT (
  SELECT COUNTIF(estado_cuadratura = 'OK') > 0
     AND COUNTIF(estado_cuadratura = 'DIFERENCIA') > 0
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_resultado_cuadratura`
) AS 'El resultado agregado debe contener controles cuadrados y descuadrados';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.pagos_primas`
  WHERE bronze_carga_id IS NULL
     OR bronze_fecha_ingesta IS NULL
     OR bronze_hash_origen IS NULL
     OR bronze_hash_registro IS NULL
) AS 'Todos los pagos Bronze deben tener trazabilidad completa';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.siniestros`
  WHERE bronze_carga_id IS NULL
     OR bronze_fecha_ingesta IS NULL
     OR bronze_hash_origen IS NULL
     OR bronze_hash_registro IS NULL
) AS 'Todos los siniestros Bronze deben tener trazabilidad completa';

SELECT
  tabla,
  tipo_excepcion,
  severidad,
  cantidad_excepciones,
  impacto_monetario_absoluto,
  carga_id
FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_resumen_cuadratura`
ORDER BY tabla, tipo_excepcion;

SELECT
  tabla,
  metrica,
  COUNTIF(estado_cuadratura = 'OK') AS controles_ok,
  COUNTIF(estado_cuadratura = 'DIFERENCIA') AS controles_con_diferencia,
  ROUND(SUM(ABS(diferencia)), 2) AS diferencia_absoluta
FROM `${PROJECT_ID}.${BRONZE_DATASET_ID}.vw_resultado_cuadratura`
GROUP BY 1, 2
ORDER BY tabla, metrica;
