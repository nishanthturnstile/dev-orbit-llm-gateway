FROM docker.litellm.ai/berriai/litellm-database:main-stable@sha256:bc57f7cdc09f29d8251846e4f4ae20503760c3c03fc5ae3a9e49eb87cc9fd0f0

COPY services/litellm/config.yaml /app/config.yaml
COPY services/litellm/scripts/phase5_validate_litellm.py /app/phase5_validate_litellm.py
COPY services/litellm/scripts/start_litellm.py /app/start_litellm.py
COPY services/litellm/sitecustomize.py /app/sitecustomize.py

ENV PYTHONPATH=/app

EXPOSE 4000

ENTRYPOINT ["python", "/app/start_litellm.py"]
CMD ["--config", "/app/config.yaml", "--host", "0.0.0.0", "--port", "4000"]
