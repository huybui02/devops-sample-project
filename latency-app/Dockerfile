FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ app/

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 5000

CMD ["python", "app/main.py"]
