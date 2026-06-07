#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  BACKUP_ENCRYPTION_KEY
  BACKUP_RCLONE_DESTINATION
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required environment variable: ${var}" >&2
    exit 2
  fi
done

if [[ -n "${RESTORE_DATABASE_URL:-}" ]]; then
  if [[ -n "${LITELLM_DATABASE_URL:-}" && "${RESTORE_DATABASE_URL}" == "${LITELLM_DATABASE_URL}" ]]; then
    echo "RESTORE_DATABASE_URL must not match LITELLM_DATABASE_URL" >&2
    exit 6
  fi
  if [[ "${RESTORE_TARGET_CONFIRMED:-}" != "fresh-restore-drill" ]]; then
    echo "Set RESTORE_TARGET_CONFIRMED=fresh-restore-drill to restore into a fresh drill database" >&2
    exit 7
  fi
fi

destination="${BACKUP_RCLONE_DESTINATION%/}"
latest_backup="$(rclone lsf "${destination}" --files-only --include "litellm-postgres-*.dump.enc" | sort | tail -n 1)"
if [[ -z "${latest_backup}" ]]; then
  echo "No encrypted LiteLLM Postgres backups found" >&2
  exit 3
fi

manifest_name="${latest_backup%.dump.enc}.manifest.json"

umask 077
tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

encrypted_path="${tmp_dir}/${latest_backup}"
dump_path="${tmp_dir}/${latest_backup%.enc}"
manifest_path="${tmp_dir}/${manifest_name}"

rclone copyto "${destination}/${latest_backup}" "${encrypted_path}"

if [[ -n "$(rclone lsf "${destination}" --files-only --include "${manifest_name}")" ]]; then
  rclone copyto "${destination}/${manifest_name}" "${manifest_path}"
  expected_sha256="$(sed -n 's/.*"encrypted_sha256":"\([a-f0-9]\{64\}\)".*/\1/p' "${manifest_path}")"
  if [[ -z "${expected_sha256}" ]]; then
    echo "Backup manifest is missing encrypted_sha256: ${manifest_name}" >&2
    exit 4
  fi
  actual_sha256="$(sha256sum "${encrypted_path}" | awk '{print $1}')"
  if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
    echo "Encrypted backup checksum mismatch: ${latest_backup}" >&2
    exit 5
  fi
fi

openssl enc -d -aes-256-cbc -pbkdf2 -pass env:BACKUP_ENCRYPTION_KEY -in "${encrypted_path}" -out "${dump_path}"
pg_restore --list "${dump_path}" >/dev/null

if [[ -n "${RESTORE_DATABASE_URL:-}" ]]; then
  pg_restore \
    --clean \
    --if-exists \
    --no-owner \
    --no-acl \
    --dbname="${RESTORE_DATABASE_URL}" \
    "${dump_path}"
  echo "{\"event\":\"restore_completed\",\"artifact\":\"${latest_backup}\",\"environment\":\"${ENVIRONMENT:-unknown}\",\"mode\":\"database\"}"
else
  echo "{\"event\":\"restore_check_passed\",\"artifact\":\"${latest_backup}\",\"environment\":\"${ENVIRONMENT:-unknown}\",\"mode\":\"archive-list\"}"
fi
