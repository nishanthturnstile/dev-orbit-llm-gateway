#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  LITELLM_DATABASE_URL
  BACKUP_ENCRYPTION_KEY
  BACKUP_RCLONE_DESTINATION
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required environment variable: ${var}" >&2
    exit 2
  fi
done

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_name="litellm-postgres-${timestamp}.dump.enc"

umask 077
tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

encrypted_path="${tmp_dir}/${backup_name}"

pg_dump \
  --format=custom \
  --no-owner \
  --no-acl \
  --dbname="${LITELLM_DATABASE_URL}" \
  | openssl enc -aes-256-cbc -pbkdf2 -salt -pass env:BACKUP_ENCRYPTION_KEY -out "${encrypted_path}"

rclone copyto "${encrypted_path}" "${BACKUP_RCLONE_DESTINATION%/}/${backup_name}"

if [[ -n "${BACKUP_RETENTION_DAYS:-}" ]]; then
  rclone delete "${BACKUP_RCLONE_DESTINATION}" --min-age "${BACKUP_RETENTION_DAYS}d" --include "litellm-postgres-*.dump.enc"
fi

echo "Backup uploaded: ${backup_name}"
