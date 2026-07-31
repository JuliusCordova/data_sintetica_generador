# Capa Bronze para cuadratura

## Propósito

El dataset `${PROJECT_ID}.seguros_bronce` representa la zona de aterrizaje de los datos sintéticos provenientes de `seguros_origen`.

Su objetivo es permitir demostraciones reproducibles de:

- control de archivos y lotes;
- conteo de registros entre origen y destino;
- cuadratura de importes;
- detección de faltantes y duplicados;
- comparación de hashes;
- integridad referencial;
- trazabilidad de excepciones.

## Flujo

```text
seguros_origen
      │
      │ snapshot sintético
      ▼
seguros_bronce
      ├── catálogos y clientes
      ├── pólizas
      ├── pagos de primas
      ├── siniestros
      ├── movimientos de siniestro
      ├── manifiesto_carga
      ├── control_totales
      ├── vw_resultado_cuadratura
      ├── vw_excepciones_cuadratura
      └── vw_resumen_cuadratura
```

## Tablas Bronze

| Tabla | Comportamiento de carga |
|---|---|
| `cat_ramo_seguro` | Copia exacta con metadatos Bronze |
| `cat_producto` | Copia exacta con metadatos Bronze |
| `cat_canal` | Copia exacta con metadatos Bronze |
| `cat_estado_poliza` | Copia exacta con metadatos Bronze |
| `cat_estado_siniestro` | Copia exacta con metadatos Bronze |
| `cat_tipo_siniestro` | Copia exacta con metadatos Bronze |
| `clientes` | Copia exacta de 100,000 filas |
| `polizas` | Copia exacta de 150,000 filas |
| `pagos_primas` | Carga con diferencias controladas |
| `siniestros` | Carga con diferencias controladas |
| `movimientos_siniestro` | Copia exacta; conserva movimientos de siniestros faltantes |

## Metadatos de ingesta

Las tablas principales incorporan:

| Campo | Descripción |
|---|---|
| `bronze_registro_id` | Identificador único de la fila aterrizada |
| `bronze_carga_id` | Identificador del lote Bronze |
| `bronze_fecha_ingesta` | Timestamp reproducible de ingesta |
| `bronze_archivo_origen` | Archivo lógico que originó la fila |
| `bronze_numero_fila_origen` | Posición determinística en el archivo |
| `bronze_hash_origen` | Hash SHA-256 de la fila original |
| `bronze_hash_registro` | Hash de los valores aterrizados relevantes |
| `bronze_estado_registro` | Estado técnico de la fila |
| `bronze_motivo_observacion` | Explicación del defecto controlado |

## Escenario de diferencias controladas

### Pagos de primas

| Excepción | Cantidad | Regla determinística |
|---|---:|---|
| Faltantes | 25 | `MOD(numero_origen, 48000) = 17` |
| Duplicados | 15 | `MOD(numero_origen, 80000) = 43` |
| Importe alterado | 20 | `MOD(numero_origen, 60000) = 29` |

Volumetría resultante:

```text
Origen:  1,200,000
Bronze:  1,199,990
```

### Siniestros

| Excepción | Cantidad | Regla determinística |
|---|---:|---|
| Faltantes | 10 | `MOD(numero_origen, 10000) = 17` |
| Duplicados | 5 | `MOD(numero_origen, 20000) = 43` |
| Reserva alterada | 8 | `MOD(numero_origen, 12500) = 29` |

Volumetría resultante:

```text
Origen:  100,000
Bronze:   99,995
```

Como cada siniestro posee tres movimientos, los 10 siniestros faltantes producen 30 movimientos huérfanos en Bronze.

## Controles de cuadratura

`control_totales` registra métricas por:

- capa: `ORIGEN` o `BRONCE`;
- tabla;
- mes;
- ramo;
- moneda;
- métrica.

Métricas incluidas:

| Tabla | Métricas |
|---|---|
| `polizas` | cantidad, prima total y suma asegurada |
| `pagos_primas` | cantidad, importe programado e importe pagado |
| `siniestros` | cantidad, monto reclamado, reserva e indemnización |
| `movimientos_siniestro` | cantidad y monto de movimiento |

## Vistas

### `vw_resultado_cuadratura`

Compara los totales de origen y Bronze. Devuelve:

- valor de origen;
- valor Bronze;
- diferencia;
- tolerancia;
- estado `OK` o `DIFERENCIA`.

### `vw_excepciones_cuadratura`

Entrega el detalle por clave para:

- registros faltantes;
- registros extra;
- duplicados;
- montos diferentes;
- movimientos sin siniestro Bronze.

### `vw_resumen_cuadratura`

Agrupa las excepciones por tabla, tipo y severidad, incluyendo su impacto monetario absoluto.

## Ejecución desde Cloud Shell

Para construir origen y Bronze:

```bash
make bronze-all
```

Cuando `seguros_origen` ya existe:

```bash
make bronze-deploy
make bronze-validate
```

## Consultas de demostración

Resumen ejecutivo:

```sql
SELECT *
FROM `proyectopersonal-480420.seguros_bronce.vw_resumen_cuadratura`
ORDER BY tabla, tipo_excepcion;
```

Controles agregados con diferencia:

```sql
SELECT *
FROM `proyectopersonal-480420.seguros_bronce.vw_resultado_cuadratura`
WHERE estado_cuadratura = 'DIFERENCIA'
ORDER BY tabla, periodo, ramo_id, moneda, metrica;
```

Detalle de excepciones críticas:

```sql
SELECT *
FROM `proyectopersonal-480420.seguros_bronce.vw_excepciones_cuadratura`
WHERE severidad = 'ALTA'
ORDER BY tabla, tipo_excepcion, clave_registro;
```

## Resultado esperado

La validación debe encontrar exactamente:

```text
25 pagos faltantes
15 pagos duplicados
20 pagos con monto diferente
10 siniestros faltantes
 5 siniestros duplicados
 8 siniestros con reserva diferente
30 movimientos huérfanos
--------------------------------
113 excepciones detalladas
```

Estas diferencias son intencionales. Cualquier cantidad distinta indica un cambio no controlado en los datos o en las reglas de carga.
