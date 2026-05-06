# Hermes HUD Web UI — Dockerfile
# Multi-stage build: build frontend inside container, run only backend at runtime
# Build on compile machine → push to registry → pull on NAS → docker compose up

FROM python:3.12-slim AS builder

# Install Node.js for frontend build
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone Hermes HUD
RUN git clone https://github.com/joeynyc/hermes-hudui.git . \
    || echo "Cloning failed, will copy source instead"

# Create venv and install backend dependencies only
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -e .

# Build frontend
WORKDIR /app/frontend
RUN npm ci && npm run build

# Runtime stage — minimal footprint
FROM python:3.12-slim

# Install runtime deps only
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Copy venv from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy built frontend static files
COPY --from=builder /app/backend/static /app/backend/static

WORKDIR /app

# Pre-copy source for wsgi server
COPY --from=builder /app/backend /app/backend

ENV PYTHONUNBUFFERED=1
EXPOSE 3001

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "3001"]
