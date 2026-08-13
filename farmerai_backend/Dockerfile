FROM python:3.11-slim

WORKDIR /code

# Copy requirements and install dependencies
COPY requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /code/requirements.txt

# Copy all application code and model files
COPY . /code

# Render uses a dynamic $PORT; fallback to 10000 for local runs
EXPOSE 10000

# Start FastAPI — PORT is injected by Render at runtime
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-10000}
