FROM python:3.11-slim

WORKDIR /app

COPY src/api/* .
COPY models/trained/*.pkl models/trained/.

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
