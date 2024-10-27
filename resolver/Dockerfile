# Dockerfile for Resolver

FROM python:3.9

WORKDIR /app

COPY . .

RUN pip install fastapi requests

CMD ["uvicorn", "resolver:app", "--host", "0.0.0.0", "--port", "8080"]
