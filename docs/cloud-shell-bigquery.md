# Sincronización Cloud Shell → BigQuery

## Prerrequisitos

- Acceso al proyecto GCP de destino.
- BigQuery API habilitada.
- Permisos para crear datasets, tablas y ejecutar jobs.
- Google Cloud Shell o una terminal con `gcloud`, `bq`, `git`, `make` y `envsubst`.

Roles mínimos recomendados para un entorno de demostración:

- `roles/bigquery.jobUser` a nivel de proyecto;
- `roles/bigquery.dataEditor` sobre el dataset o proyecto;
- `roles/bigquery.user` cuando se requiera crear el dataset.

## 1. Abrir Cloud Shell

Desde Google Cloud Console, seleccionar el proyecto:

```text
proyectopersonal-480420
```

Abrir Cloud Shell y validar la cuenta activa:

```bash
gcloud auth list
gcloud config get-value project
```

## 2. Clonar el repositorio

```bash
git clone https://github.com/JuliusCordova/data_sintetica_generador.git
cd data_sintetica_generador
```

Para sincronizar cambios posteriores:

```bash
git switch main
git pull --ff-only origin main
```

No usar `git reset --hard` sobre una carpeta con cambios locales sin revisar previamente `git status`.

## 3. Configurar el entorno

```bash
cp config/env.example .env
nano .env
```

Configuración predeterminada:

```bash
PROJECT_ID=proyectopersonal-480420
DATASET_ID=seguros_origen
BQ_LOCATION=US
GENERATION_VERSION=v1
```

El archivo `.env` es local y está excluido de Git.

## 4. Preparar Cloud Shell

```bash
make bootstrap
```

El comando:

1. carga las variables de `.env`;
2. selecciona el proyecto GCP;
3. verifica las herramientas requeridas;
4. valida la autenticación;
5. habilita BigQuery API cuando el usuario tiene permisos.

## 5. Desplegar a BigQuery

```bash
make deploy
```

Los archivos SQL se ejecutan en orden lexicográfico. Antes de enviarlos a BigQuery, `envsubst` reemplaza:

- `${PROJECT_ID}`
- `${DATASET_ID}`
- `${BQ_LOCATION}`
- `${GENERATION_VERSION}`

El despliegue es idempotente: las tablas se recrean con la misma distribución sintética.

## 6. Validar

```bash
make validate
```

También puede ejecutarse directamente:

```bash
bq query \
  --project_id=proyectopersonal-480420 \
  --location=US \
  --use_legacy_sql=false \
  'SELECT table_name, row_count
   FROM `proyectopersonal-480420.seguros_origen.INFORMATION_SCHEMA.TABLE_STORAGE`
   ORDER BY table_name;'
```

## 7. Ejecución completa

```bash
make all
```

## 8. Flujo de actualización recomendado

```bash
cd ~/data_sintetica_generador
git status
git pull --ff-only origin main
make deploy
make validate
```

## 9. Recuperación ante errores

### Proyecto incorrecto

```bash
gcloud config set project proyectopersonal-480420
```

### Dataset en otra ubicación

BigQuery no permite mover un dataset entre regiones. Ajustar `BQ_LOCATION` o eliminar y recrear el dataset únicamente cuando sea seguro hacerlo.

### Falta de permisos

```bash
bq show --format=prettyjson proyectopersonal-480420:seguros_origen
```

Si falla, revisar IAM con el administrador del proyecto.

### SQL inválido

El script informa el archivo exacto que falló y termina inmediatamente con código distinto de cero. Corregir el archivo, confirmar los cambios en Git y volver a ejecutar `make deploy`.

## 10. Seguridad

- No versionar `.env`, llaves JSON, tokens o credenciales.
- Preferir identidad de usuario o service account administrada por GCP.
- No usar datos reales en este repositorio.
- Mantener el dataset claramente etiquetado como sintético y de demostración.
