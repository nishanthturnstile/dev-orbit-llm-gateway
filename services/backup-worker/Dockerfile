FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    ca-certificates \
    openssl \
    postgresql-client \
    rclone \
    tzdata

WORKDIR /app

COPY services/backup-worker/scripts/backup-postgres.sh /app/backup-postgres.sh
COPY services/backup-worker/scripts/restore-check.sh /app/restore-check.sh

RUN chmod +x /app/backup-postgres.sh /app/restore-check.sh

CMD ["/app/backup-postgres.sh"]
