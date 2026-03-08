# =============================================================================
# Voicebox Docker Container
# Runs the Python FastAPI backend (port 17493) with PyTorch inference.
# For Apple Silicon / MLX, use the native macOS app instead.
# For CUDA GPU support, use: docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up
# =============================================================================

# ── Stage 1: Build the web frontend ──────────────────────────────────────────
FROM oven/bun:1-alpine AS web-builder

WORKDIR /app

# Copy root package.json and lockfile (bun workspaces)
COPY package.json bun.lock ./

# Copy only the packages needed to build the web app
COPY app/ ./app/
COPY web/ ./web/

# Install deps and build the web frontend
# The web app is a Vite/React SPA that talks to the backend API
WORKDIR /app/web
RUN bun install --frozen-lockfile
RUN bun run build
# Built output ends up in /app/web/dist


# ── Stage 2: Backend runtime ──────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# ── System dependencies ───────────────────────────────────────────────────────
# ffmpeg: audio encoding/decoding for voice samples and generated audio
# libsndfile1: used by librosa / soundfile for WAV I/O
# curl: used by Docker HEALTHCHECK
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg \
        libsndfile1 \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ── Python dependencies ───────────────────────────────────────────────────────
COPY requirements.txt ./
# NOTE: torch is pulled in by requirements.txt; it targets CPU by default.
# For CUDA, override with docker-compose.cuda.yml which sets the pip index URL.
RUN pip install --no-cache-dir -r requirements.txt

# Install Qwen3-TTS directly from the official source (not yet on PyPI)
RUN pip install --no-cache-dir \
        git+https://github.com/QwenLM/Qwen3-TTS.git

# ── Copy application code ─────────────────────────────────────────────────────
COPY backend/ ./backend/

# Copy the built web frontend into the backend's static folder so FastAPI
# can serve it at the root URL alongside the /docs and /api routes.
COPY --from=web-builder /app/web/dist ./backend/static/

# ── Data directory ────────────────────────────────────────────────────────────
# This is where voicebox stores the SQLite DB, voice profiles, generated
# audio, and prompt cache. Mount a volume here to persist data across
# container restarts.
RUN mkdir -p /app/data/profiles /app/data/generations /app/data/cache /app/data/projects

# ── Hugging Face model cache ──────────────────────────────────────────────────
# Qwen3-TTS models (~2-4 GB) are downloaded here on first use.
# Mount a volume to avoid re-downloading every time the container restarts.
ENV HF_HOME=/app/hf_cache
RUN mkdir -p /app/hf_cache

# ── Environment defaults ──────────────────────────────────────────────────────
ENV PYTHONUNBUFFERED=1 \
    DATA_DIR=/app/data

# ── Exposed port ──────────────────────────────────────────────────────────────
# 17493 is the voicebox backend port (matches the upstream project default)
EXPOSE 17493

# ── Health check ──────────────────────────────────────────────────────────────
# Polls the /health endpoint every 30 s; gives the server 60 s to start
# (model loading takes time on first boot).
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:17493/health || exit 1

# ── Start the server ──────────────────────────────────────────────────────────
# Run from the repo root so Python resolves `backend.main` correctly.
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "17493"]
