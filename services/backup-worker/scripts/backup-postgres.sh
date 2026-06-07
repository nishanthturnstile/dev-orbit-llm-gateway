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
backup_tier="${BACKUP_TIER:-daily}"
case "${backup_tier}" in
  daily|weekly|monthly) ;;
  *)
    echo "BACKUP_TIER must be one of: daily, weekly, monthly" >&2
    exit 2
    ;;
esac

backup_prefix="litellm-postgres-${timestamp}-${backup_tier}"
backup_name="${backup_prefix}.dump.enc"
manifest_name="${backup_prefix}.manifest.json"
destination="${BACKUP_RCLONE_DESTINATION%/}"

umask 077
tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

encrypted_path="${tmp_dir}/${backup_name}"
manifest_path="${tmp_dir}/${manifest_name}"

pg_dump \
  --format=custom \
  --compress=6 \
  --no-owner \
  --no-acl \
  --dbname="${LITELLM_DATABASE_URL}" \
  | openssl enc -aes-256-cbc -pbkdf2 -salt -pass env:BACKUP_ENCRYPTION_KEY -out "${encrypted_path}"

encrypted_sha256="$(sha256sum "${encrypted_path}" | awk '{print $1}')"
encrypted_size_bytes="$(wc -c < "${encrypted_path}" | tr -d '[:space:]')"

cat >"${manifest_path}" <<EOF
{"artifact":"${backup_name}","environment":"${ENVIRONMENT:-unknown}","tier":"${backup_tier}","created_at":"${timestamp}","dump_format":"postgres-custom","compression":"pg_dump-custom-compress-6","encryption":"openssl-aes-256-cbc-pbkdf2","encrypted_size_bytes":${encrypted_size_bytes},"encrypted_sha256":"${encrypted_sha256}"}
EOF

rclone copyto "${encrypted_path}" "${destination}/${backup_name}"
rclone copyto "${manifest_path}" "${destination}/${manifest_name}"

if [[ -n "${BACKUP_RETENTION_DAYS:-}" ]]; then
  rclone delete "${destination}" --min-age "${BACKUP_RETENTION_DAYS}d" --include "litellm-postgres-*.dump.enc" --include "litellm-postgres-*.manifest.json"
fi

echo "{\"event\":\"backup_uploaded\",\"artifact\":\"${backup_name}\",\"manifest\":\"${manifest_name}\",\"environment\":\"${ENVIRONMENT:-unknown}\",\"tier\":\"${backup_tier}\",\"encrypted_size_bytes\":${encrypted_size_bytes},\"encrypted_sha256\":\"${encrypted_sha256}\"}"
