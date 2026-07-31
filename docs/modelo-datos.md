# Modelo de datos sintético de seguros

## Alcance

El dataset `seguros_origen` simula un sistema operacional asegurador multiproducto. Todos los objetos —catálogos, maestros y transacciones— permanecen en un único dataset de BigQuery.

## Dominios incluidos

- Vehicular
- Salud
- Vida
- Hogar

## Relaciones principales

```text
cat_ramo_seguro 1 ── N cat_producto
cat_producto    1 ── N polizas
clientes        1 ── N polizas
polizas         1 ── N pagos_primas
polizas         1 ── N siniestros
siniestros      1 ── N movimientos_siniestro
```

## Catálogos

### `cat_ramo_seguro`

Identifica el ramo de negocio: vehicular, salud, vida y hogar.

### `cat_producto`

Productos comerciales asociados a un ramo. Incluye moneda, periodicidad y prima base referencial.

### `cat_canal`

Canales de venta y atención: web, app, agencia, corredor, call center, fuerza de ventas, aliados y banca seguros.

### `cat_estado_poliza`

Estados operacionales de una póliza: vigente, vencida, cancelada, suspendida, pendiente y renovada.

### `cat_estado_siniestro`

Estados del ciclo de atención: reportado, en evaluación, observado, aprobado, rechazado, pagado y cerrado.

### `cat_tipo_siniestro`

Tipologías de evento por ramo, por ejemplo choque, robo, hospitalización, fallecimiento o daño estructural.

## Maestros

### `clientes`

Una fila por cliente sintético. Contiene atributos demográficos, contacto, ubicación y metadatos técnicos.

Clave primaria lógica: `cliente_id`.

## Transacciones

### `polizas`

Contrato de seguro emitido para un cliente y producto.

Claves lógicas:

- `poliza_id`
- `cliente_id`
- `producto_id`
- `canal_id`
- `estado_poliza_id`

Partición: `fecha_emision`.

Clustering: `cliente_id`, `producto_id`, `estado_poliza_id`.

### `pagos_primas`

Cuotas y pagos asociados a pólizas. Incluye vencimiento, fecha de pago, importe, moneda y situación de cobranza.

Partición: `fecha_vencimiento`.

Clustering: `poliza_id`, `estado_pago`.

### `siniestros`

Eventos reportados contra pólizas. Incluye fechas, importes reclamados, reservas, estado y tipo de siniestro.

Partición: `fecha_ocurrencia`.

Clustering: `poliza_id`, `estado_siniestro_id`, `tipo_siniestro_id`.

### `movimientos_siniestro`

Historial operacional de cada siniestro: registro, asignación, evaluación, reserva, aprobación, rechazo, pago o cierre.

Partición: `fecha_movimiento`.

Clustering: `siniestro_id`, `tipo_movimiento`.

## Columnas técnicas comunes

Las tablas principales incorporan:

- `sistema_origen`
- `lote_id`
- `fecha_carga`
- `es_sintetico`
- `version_generador`

## Volumetría objetivo

| Tabla | Filas |
|---|---:|
| `clientes` | 100,000 |
| `polizas` | 150,000 |
| `pagos_primas` | 1,200,000 |
| `siniestros` | 100,000 |
| `movimientos_siniestro` | 300,000 |

## Uso esperado

Este modelo funciona como sistema fuente para demos posteriores de ingesta, perfilamiento, calidad, reconciliación, procesamiento Bronze-to-Silver, analítica y agentes sobre BigQuery.
