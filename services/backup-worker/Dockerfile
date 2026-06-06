FROM alpine:3.20@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc

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
