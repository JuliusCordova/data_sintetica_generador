#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
SQL_DIR="${ROOT_DIR}/sql/bronze"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

log() {
  printf '[bronze-deploy] %s\n' "$*"
}

fail() {
  printf '[bronze-deploy][ERROR] %s\n' "$*" >&2
  exit 1
}

[[ -f "${ENV_FILE}" ]] || fail "No existe .env. Ejecuta: make bootstrap"
[[ -d "${SQL_DIR}" ]] || fail "No existe el directorio ${SQL_DIR}"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${PROJECT_ID:?PROJECT_ID es obligatorio}"
: "${DATASET_ID:?DATASET_ID es obligatorio}"
: "${BRONZE_DATASET_ID:?BRONZE_DATASET_ID es obligatorio}"
: "${BQ_LOCATION:?BQ_LOCATION es obligatorio}"
: "${GENERATION_VERSION:?GENERATION_VERSION es obligatorio}"
: "${BRONZE_LOAD_ID:?BRONZE_LOAD_ID es obligatorio}"
: "${BRONZE_LOAD_TIMESTAMP:?BRONZE_LOAD_TIMESTAMP es obligatorio}"

if [[ "${DATASET_ID}" == "${BRONZE_DATASET_ID}" ]]; then
  fail "DATASET_ID y BRONZE_DATASET_ID deben ser diferentes"
fi

mapfile -t SQL_FILES < <(
  find "${SQL_DIR}" -maxdepth 1 -type f -name '*.sql' ! -name '99_validate_bronze.sql' | sort
)
[[ ${#SQL_FILES[@]} -gt 0 ]] || fail "No se encontraron archivos SQL de Bronze"

for sql_file in "${SQL_FILES[@]}"; do
  file_name="$(basename "${sql_file}")"
  rendered_file="${TMP_DIR}/${file_name}"

  log "Renderizando ${file_name}"
  envsubst '${PROJECT_ID} ${DATASET_ID} ${BRONZE_DATASET_ID} ${BQ_LOCATION} ${GENERATION_VERSION} ${BRONZE_LOAD_ID} ${BRONZE_LOAD_TIMESTAMP}' \
    < "${sql_file}" > "${rendered_file}"

  log "Ejecutando ${file_name}"
  bq query \
    --project_id="${PROJECT_ID}" \
    --location="${BQ_LOCATION}" \
    --use_legacy_sql=false \
    --format=none \
    < "${rendered_file}"
done

log "Carga Bronze completada: ${PROJECT_ID}.${BRONZE_DATASET_ID}"
log "Ejecuta 'make bronze-validate' para comprobar la cuadratura"
