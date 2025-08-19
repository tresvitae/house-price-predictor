FROM python:3.9-slim

WORKDIR /app

# Copy and install dependencies first (for better caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and configuration
COPY app.py .
COPY .streamlit .streamlit/

EXPOSE 8501

# Health check using Python requests (already installed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8501/', timeout=5)" || exit 1

CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0"]