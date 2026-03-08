<p align="center">
  <img src="./icon-dark.png" alt="Voicebox" width="160" height="160" />
</p>

<h1 align="center">Voicebox — Docker Edition</h1>

<p align="center">
  A Docker containerization fork of <a href="https://github.com/jamiepine/voicebox"><strong>jamiepine/voicebox</strong></a>
  for NVIDIA GPU users on Windows.<br/>
  Runs the full app (backend + web UI) in a single container with CUDA acceleration.
</p>

<p align="center">
  <a href="https://github.com/jamiepine/voicebox/releases/latest">
    <img src="https://img.shields.io/github/v/release/jamiepine/voicebox?style=flat&label=upstream" alt="Upstream Release" />
  </a>
  <a href="https://github.com/jamiepine/voicebox/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/jamiepine/voicebox?style=flat" alt="License" />
  </a>
  <img src="https://img.shields.io/badge/CUDA-12.x-green?style=flat&logo=nvidia" alt="CUDA" />
  <img src="https://img.shields.io/badge/Docker-ready-blue?style=flat&logo=docker" alt="Docker" />
</p>

---

> **⚠️ This is not the original project.**  
> This fork adds Docker support for NVIDIA GPU users. If you want the native desktop app for macOS or Windows, go to [jamiepine/voicebox](https://github.com/jamiepine/voicebox).

---

## What this fork adds

| | Original | This fork |
|---|---|---|
| Deployment | Tauri desktop app | Docker container |
| Platform | macOS / Windows native | Windows + Docker Desktop |
| GPU | MLX (Apple Silicon) / PyTorch | CUDA via NVIDIA GPU |
| Web UI | Embedded in desktop app | Served by FastAPI at port 17493 |
| Setup | Install app + Python | `docker-compose up` |

**Changes made to the upstream source:**

- Added `Dockerfile` — multi-stage build (Bun frontend → Python runtime)
- Added `docker-compose.yml` — base CPU service definition
- Added `docker-compose.cuda.yml` — NVIDIA GPU overlay
- Modified `backend/main.py` — serves the React web UI from the same FastAPI port
- Updated `.gitignore` — excludes model weights, local data, and generated audio

---

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with WSL2 backend enabled
- Windows 10/11
- NVIDIA GPU (tested on RTX 5070 Ti, 12 GB VRAM)
- Docker Desktop → Settings → Resources → **Enable GPU**

> CPU-only mode works but TTS generation will be very slow.

---

## Quick start

```powershell
git clone https://github.com/sergio-caracas/voicebox-docker.git

cd voicebox-docker

# Start with NVIDIA GPU acceleration (recommended)
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up -d
```

Open **http://localhost:17493** in your browser.

> **First run:** The Qwen3-TTS model (~4 GB) downloads automatically on your first generation request.  
> It is cached in a Docker volume and will not re-download on subsequent starts.

---

## Access points

| URL | Description |
|-----|-------------|
| http://localhost:17493 | Web UI |
| http://localhost:17493/docs | FastAPI interactive API docs |
| http://localhost:17493/health | Health check |

---

## Stopping and restarting

```powershell
# Stop (data is preserved in Docker volumes)
docker-compose down

# Restart with GPU
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up -d

# Rebuild after code changes
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up -d --build
```

---

## Full documentation

See **[README_DOCKER.md](README_DOCKER.md)** for complete instructions:
- Volume management and data persistence
- Environment variables
- GPU verification
- Troubleshooting

---

## Credits

All credit for the original application goes to **[Jamie Pine](https://github.com/jamiepine)** and contributors.  
This fork only adds containerization. The core app, AI models, and all features are from the upstream project.

- Upstream repo: [jamiepine/voicebox](https://github.com/jamiepine/voicebox)
- Original README: preserved in [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md)
- License: [MIT](LICENSE)

---

<p align="center">
  <a href="https://voicebox.sh">voicebox.sh</a>
</p>
