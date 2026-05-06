# Hermes HUD Web UI — Dockerfile
# Build on compile machine → push to registry → pull on NAS → docker compose up

# ── Stage 1: Build frontend ────────────────────────────────────────────────
FROM python:3.12-slim AS frontend-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download hermes-hudui source (no git needed)
RUN curl -sL https://github.com/joeynyc/hermes-hudui/archive/refs/heads/main.tar.gz \
    | tar xz --strip-components=1

# Build frontend
WORKDIR /app/frontend
RUN npm ci && npm run build

# ── Stage 2: Backend dependencies ───────────────────────────────────────────
FROM python:3.12-slim AS backend-deps

WORKDIR /app

COPY --from=frontend-builder /app/pyproject.toml .

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir fastapi "uvicorn[standard]" pyyaml watchfiles

# ── Stage 3: Runtime ───────────────────────────────────────────────────────
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Copy venv, backend source, and built frontend
COPY --from=backend-deps /opt/venv /opt/venv
COPY --from=frontend-builder /app/backend/static /app/backend/static
COPY --from=frontend-builder /app/backend /app/backend

WORKDIR /app

ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV HERMES_HOME=/data/.hermes

EXPOSE 3001

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "3001"]
