# Read This First

This is a fork of [jamiepine/voicebox](https://github.com/jamiepine/voicebox) — an AI voice synthesis app powered by Qwen3-TTS.

---

## What's different in this fork

- **Fully Dockerized** — the entire app (backend + frontend) runs in a single container
- **CUDA support** — configured for NVIDIA GPU inference on Windows via Docker Desktop
- `backend/main.py` modified to serve the React web UI from the same port as the API (port 17493)
- `.gitignore` updated to exclude model weights, local data, and generated audio

---

## Do not run this natively

The original repo is designed as a Tauri desktop app. This fork is Docker-only.  
Running the Python backend or Bun frontend directly is not supported here.

---

## Requirements

- Docker Desktop (Windows, WSL2 backend)
- NVIDIA GPU strongly recommended — CPU mode works but TTS generation is very slow

---

## Quick start

```powershell
# Clone the repo
git clone https://github.com/sergio-caracas/voicebox
cd voicebox

# Start with GPU support (recommended)
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up -d
```

Then open **http://localhost:17493** in your browser.

> The first time you generate speech, the Qwen3-TTS model (~4 GB) will download automatically.  
> This only happens once — it is cached in a Docker volume for all future runs.

---

## Full setup guide

See **[README_DOCKER.md](README_DOCKER.md)** for complete instructions including:
- Volume management
- Environment variables
- Troubleshooting
- How to rebuild after code changes
