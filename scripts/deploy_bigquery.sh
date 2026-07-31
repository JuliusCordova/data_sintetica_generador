#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
SQL_DIR="${ROOT_DIR}/sql"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

log() {
  printf '[deploy] %s\n' "$*"
}

fail() {
  printf '[deploy][ERROR] %s\n' "$*" >&2
  exit 1
}

[[ -f "${ENV_FILE}" ]] || fail "No existe .env. Ejecuta: make bootstrap"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${PROJECT_ID:?PROJECT_ID es obligatorio}"
: "${DATASET_ID:?DATASET_ID es obligatorio}"
: "${BQ_LOCATION:?BQ_LOCATION es obligatorio}"
: "${GENERATION_VERSION:?GENERATION_VERSION es obligatorio}"

mapfile -t SQL_FILES < <(find "${SQL_DIR}" -maxdepth 1 -type f -name '*.sql' ! -name '07_validate.sql' | sort)
[[ ${#SQL_FILES[@]} -gt 0 ]] || fail "No se encontraron archivos SQL de despliegue"

for sql_file in "${SQL_FILES[@]}"; do
  file_name="$(basename "${sql_file}")"
  rendered_file="${TMP_DIR}/${file_name}"

  log "Renderizando ${file_name}"
  envsubst '${PROJECT_ID} ${DATASET_ID} ${BQ_LOCATION} ${GENERATION_VERSION}' \
    < "${sql_file}" > "${rendered_file}"

  log "Ejecutando ${file_name}"
  bq query \
    --project_id="${PROJECT_ID}" \
    --location="${BQ_LOCATION}" \
    --use_legacy_sql=false \
    --format=none \
    < "${rendered_file}"
done

log "Despliegue completado: ${PROJECT_ID}.${DATASET_ID}"
log "Ejecuta 'make validate' para verificar volumetría e integridad"
