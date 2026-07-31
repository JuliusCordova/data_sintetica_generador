#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
EXAMPLE_ENV="${ROOT_DIR}/config/env.example"

log() {
  printf '[bootstrap] %s\n' "$*"
}

fail() {
  printf '[bootstrap][ERROR] %s\n' "$*" >&2
  exit 1
}

for command in gcloud bq git make envsubst; do
  command -v "${command}" >/dev/null 2>&1 || fail "No se encontró el comando requerido: ${command}"
done

if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${EXAMPLE_ENV}" "${ENV_FILE}"
  log "Se creó .env desde config/env.example"
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${PROJECT_ID:?PROJECT_ID es obligatorio}"
: "${DATASET_ID:?DATASET_ID es obligatorio}"
: "${BQ_LOCATION:?BQ_LOCATION es obligatorio}"
: "${GENERATION_VERSION:?GENERATION_VERSION es obligatorio}"

ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n 1)"
[[ -n "${ACTIVE_ACCOUNT}" ]] || fail "No existe una cuenta autenticada. Ejecuta: gcloud auth login"

log "Cuenta activa: ${ACTIVE_ACCOUNT}"
log "Configurando proyecto: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}" >/dev/null

log "Verificando acceso al proyecto"
gcloud projects describe "${PROJECT_ID}" --format='value(projectId)' >/dev/null

log "Habilitando BigQuery API si es necesario"
gcloud services enable bigquery.googleapis.com --project="${PROJECT_ID}" >/dev/null

log "Entorno preparado"
log "Destino: ${PROJECT_ID}.${DATASET_ID} (${BQ_LOCATION})"
