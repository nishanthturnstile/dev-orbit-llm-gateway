FROM postgres:18-alpine@sha256:15b46a9c5a6b361eb4c0ce8d689365bf49fbf6802e615dce4e5e2326b3213e15

RUN apk add --no-cache \
    bash \
    ca-certificates \
    openssl \
    rclone \
    tzdata

WORKDIR /app

COPY services/backup-worker/scripts/backup-postgres.sh /app/backup-postgres.sh
COPY services/backup-worker/scripts/restore-check.sh /app/restore-check.sh

RUN chmod +x /app/backup-postgres.sh /app/restore-check.sh

CMD ["/app/backup-postgres.sh"]
