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

latest_backup="$(rclone lsf "${BACKUP_RCLONE_DESTINATION}" --files-only --include "litellm-postgres-*.dump.enc" | sort | tail -n 1)"
if [[ -z "${latest_backup}" ]]; then
  echo "No encrypted LiteLLM Postgres backups found" >&2
  exit 3
fi

umask 077
tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

encrypted_path="${tmp_dir}/${latest_backup}"
dump_path="${tmp_dir}/${latest_backup%.enc}"

rclone copyto "${BACKUP_RCLONE_DESTINATION%/}/${latest_backup}" "${encrypted_path}"
openssl enc -d -aes-256-cbc -pbkdf2 -pass env:BACKUP_ENCRYPTION_KEY -in "${encrypted_path}" -out "${dump_path}"
pg_restore --list "${dump_path}" >/dev/null

echo "Restore check passed: ${latest_backup}"
