#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
VALIDATION_SQL="${ROOT_DIR}/sql/07_validate.sql"
TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

fail() {
  printf '[validate][ERROR] %s\n' "$*" >&2
  exit 1
}

[[ -f "${ENV_FILE}" ]] || fail "No existe .env. Ejecuta: make bootstrap"
[[ -f "${VALIDATION_SQL}" ]] || fail "No existe sql/07_validate.sql"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${PROJECT_ID:?PROJECT_ID es obligatorio}"
: "${DATASET_ID:?DATASET_ID es obligatorio}"
: "${BQ_LOCATION:?BQ_LOCATION es obligatorio}"
: "${GENERATION_VERSION:?GENERATION_VERSION es obligatorio}"

envsubst '${PROJECT_ID} ${DATASET_ID} ${BQ_LOCATION} ${GENERATION_VERSION}' \
  < "${VALIDATION_SQL}" > "${TMP_FILE}"

printf '[validate] Validando %s.%s\n' "${PROJECT_ID}" "${DATASET_ID}"

bq query \
  --project_id="${PROJECT_ID}" \
  --location="${BQ_LOCATION}" \
  --use_legacy_sql=false \
  --format=pretty \
  < "${TMP_FILE}"

printf '[validate] Validación completada sin errores\n'
