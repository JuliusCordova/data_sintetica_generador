#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
SQL_FILE="${ROOT_DIR}/sql/bronze/99_validate_bronze.sql"
TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

log() {
  printf '[bronze-validate] %s\n' "$*"
}

fail() {
  printf '[bronze-validate][ERROR] %s\n' "$*" >&2
  exit 1
}

[[ -f "${ENV_FILE}" ]] || fail "No existe .env. Ejecuta: make bootstrap"
[[ -f "${SQL_FILE}" ]] || fail "No existe ${SQL_FILE}"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${PROJECT_ID:?PROJECT_ID es obligatorio}"
: "${DATASET_ID:?DATASET_ID es obligatorio}"
: "${BRONZE_DATASET_ID:?BRONZE_DATASET_ID es obligatorio}"
: "${BQ_LOCATION:?BQ_LOCATION es obligatorio}"
: "${BRONZE_LOAD_ID:?BRONZE_LOAD_ID es obligatorio}"

log "Renderizando validaciones Bronze"
envsubst '${PROJECT_ID} ${DATASET_ID} ${BRONZE_DATASET_ID} ${BQ_LOCATION} ${BRONZE_LOAD_ID}' \
  < "${SQL_FILE}" > "${TMP_FILE}"

log "Ejecutando controles de volumetría, integridad y cuadratura"
bq query \
  --project_id="${PROJECT_ID}" \
  --location="${BQ_LOCATION}" \
  --use_legacy_sql=false \
  --format=prettyjson \
  < "${TMP_FILE}"

log "Validación Bronze completada"
