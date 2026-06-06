FROM docker.litellm.ai/berriai/litellm-database:main-stable@sha256:bc57f7cdc09f29d8251846e4f4ae20503760c3c03fc5ae3a9e49eb87cc9fd0f0

COPY config/litellm/config.yaml /app/config.yaml

EXPOSE 4000

CMD ["--config", "/app/config.yaml", "--host", "0.0.0.0", "--port", "4000"]
