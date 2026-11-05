FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SOAR_DATA_DIR=/app/data

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN groupadd --gid 10001 soar \
    && useradd --uid 10001 --gid soar --no-create-home soar \
    && mkdir /app/data \
    && chown soar:soar /app/data

COPY --chown=soar:soar app.py actions.py recovery.py rule_engine.py rules.json ./

USER soar

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "4", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "app:app"]