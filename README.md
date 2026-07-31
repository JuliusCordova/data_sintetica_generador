# Generador de datos sintéticos de seguros

Proyecto para generar y desplegar datos sintéticos del sector seguros en Google BigQuery desde Google Cloud Shell.

## Objetivo

Crear el dataset fuente:

```text
proyectopersonal-480420.seguros_origen
```

El dataset contiene catálogos, maestros y tablas transaccionales con datos ficticios para demostraciones de:

- perfilamiento y calidad de datos;
- reconciliación y cuadratura;
- transformación Bronze-to-Silver;
- analítica y Customer 360;
- agentes de IA y consultas NL-to-SQL.

> Todos los registros son sintéticos. No deben incorporarse datos personales o productivos reales.

## Volumetría inicial

| Tabla | Tipo | Filas esperadas |
|---|---|---:|
| `cat_ramo_seguro` | Catálogo | 4 |
| `cat_producto` | Catálogo | 12 |
| `cat_canal` | Catálogo | 8 |
| `cat_estado_poliza` | Catálogo | 6 |
| `cat_estado_siniestro` | Catálogo | 7 |
| `cat_tipo_siniestro` | Catálogo | 12 |
| `clientes` | Maestro | 100,000 |
| `polizas` | Transaccional | 150,000 |
| `pagos_primas` | Transaccional | 1,200,000 |
| `siniestros` | Transaccional | 100,000 |
| `movimientos_siniestro` | Transaccional | 300,000 |

## Estructura

```text
.
├── config/
│   └── env.example
├── docs/
│   ├── modelo-datos.md
│   ├── reglas-generacion.md
│   └── cloud-shell-bigquery.md
├── scripts/
│   ├── bootstrap.sh
│   ├── deploy_bigquery.sh
│   └── validate_bigquery.sh
├── sql/
│   ├── 00_create_dataset.sql
│   ├── 01_create_catalogos.sql
│   ├── 02_generate_clientes.sql
│   ├── 03_generate_polizas.sql
│   ├── 04_generate_pagos_primas.sql
│   ├── 05_generate_siniestros.sql
│   ├── 06_generate_movimientos.sql
│   └── 07_validate.sql
└── Makefile
```

## Ejecución rápida en Cloud Shell

```bash
git clone https://github.com/JuliusCordova/data_sintetica_generador.git
cd data_sintetica_generador

cp config/env.example .env
# Editar .env si se requiere otro proyecto, dataset o ubicación.

make bootstrap
make deploy
make validate
```

Valores predeterminados:

```text
PROJECT_ID=proyectopersonal-480420
DATASET_ID=seguros_origen
BQ_LOCATION=US
```

## Principios

1. La generación debe ser reproducible y determinística.
2. Los scripts deben ser idempotentes y seguros para múltiples ejecuciones.
3. Catálogos, maestros y transacciones permanecen en `seguros_origen`.
4. Las tablas transaccionales principales tienen al menos 100,000 filas.
5. Los defectos de calidad se introducen de forma controlada y documentada.
6. Cada tabla incorpora metadatos técnicos de carga y origen sintético.
7. Ningún secreto, credencial o archivo `.env` debe versionarse.

## Licencia y uso

Repositorio de demostración y aprendizaje. La información generada no representa clientes, pólizas ni siniestros reales.
