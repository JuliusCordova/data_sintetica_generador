# Reglas canónicas de generación

## 1. Naturaleza de los datos

Toda la información generada es ficticia. No se permite copiar, transformar o combinar datos reales de clientes, asegurados, pólizas, pagos o siniestros.

## 2. Reproducibilidad

La generación debe ser determinística. Se utiliza `FARM_FINGERPRINT` con identificadores estables en lugar de depender exclusivamente de `RAND()`.

Una nueva ejecución de la misma versión debe producir:

- las mismas claves lógicas;
- la misma distribución funcional;
- la misma cantidad de filas;
- los mismos defectos de calidad controlados.

## 3. Idempotencia

Todos los scripts utilizan `CREATE OR REPLACE TABLE` o `CREATE SCHEMA IF NOT EXISTS`. Ejecutar nuevamente el despliegue reemplaza la versión anterior sin duplicar registros.

## 4. Dataset de origen

Todos los catálogos, maestros y transacciones se crean en:

```text
${PROJECT_ID}.${DATASET_ID}
```

Configuración predeterminada:

```text
proyectopersonal-480420.seguros_origen
```

## 5. Distribución por ramo

Distribución objetivo de pólizas:

| Ramo | Participación |
|---|---:|
| Vehicular | 35 % |
| Salud | 30 % |
| Vida | 20 % |
| Hogar | 15 % |

La selección se deriva del identificador secuencial de la póliza para conservar estabilidad.

## 6. Integridad lógica

Salvo los defectos expresamente documentados:

- toda póliza debe referenciar un cliente existente;
- todo producto debe pertenecer a un ramo existente;
- todo pago debe referenciar una póliza existente;
- todo siniestro debe referenciar una póliza existente;
- todo movimiento debe referenciar un siniestro existente;
- las fechas deben respetar la secuencia temporal del negocio.

## 7. Temporalidad

La historia sintética cubre desde enero de 2023 hasta junio de 2026.

Reglas principales:

- `fecha_inicio_vigencia >= fecha_emision`;
- `fecha_fin_vigencia > fecha_inicio_vigencia`;
- `fecha_vencimiento` se calcula desde la vigencia de la póliza;
- `fecha_ocurrencia` debe encontrarse dentro o cerca de la vigencia;
- `fecha_reporte >= fecha_ocurrencia`;
- `fecha_movimiento >= fecha_reporte`.

## 8. Importes

- PEN es la moneda predominante.
- Algunos productos de vida se expresan en USD.
- `prima_total` se deriva de la prima base del producto con una variación determinística.
- `monto_reclamado` depende del ramo y del tipo de evento.
- `monto_reserva` representa una estimación operacional.
- Los importes se redondean a dos decimales.

## 9. Defectos controlados de calidad

Los defectos permiten demostrar perfilamiento, reglas y reconciliación.

| Regla | Tasa aproximada |
|---|---:|
| Correo inválido | 2.0 % |
| Teléfono nulo | 1.5 % |
| Documento con longitud inválida | 1.0 % |
| Póliza con fecha inconsistente | 0.5 % |
| Pago vencido no cancelado | 2.0 % |
| Siniestro con reserva superior atípica | 1.0 % |
| Diferencia reserva versus monto final | 2.0 % |

Los defectos deben ser identificables mediante condiciones determinísticas basadas en `MOD`.

## 10. Claves

Convenciones:

```text
CLI-000001
POL-000000001
PAG-0000000001
SIN-000000001
MSI-0000000001
```

Las claves son sintéticas, estables, legibles y no contienen información personal.

## 11. Metadatos técnicos

Valores predeterminados:

```text
sistema_origen = 'SYNTHETIC_INSURANCE_CORE'
es_sintetico = TRUE
version_generador = ${GENERATION_VERSION}
```

`lote_id` identifica la ejecución lógica y `fecha_carga` registra el momento de despliegue.

## 12. Criterios de aceptación

El despliegue se considera válido cuando:

1. existen todas las tablas esperadas;
2. las tablas transaccionales cumplen la volumetría mínima;
3. no existen claves nulas en identificadores principales;
4. las relaciones principales cumplen los umbrales definidos;
5. todos los registros están marcados como sintéticos;
6. las consultas de validación terminan sin error.
