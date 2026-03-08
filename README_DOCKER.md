# Voicebox — Docker Setup Guide

This guide covers running **voicebox** in Docker on Windows with an NVIDIA GPU (CUDA).  
The container runs both the FastAPI backend and serves the React web UI on a single port.

---

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with the **WSL2 backend** enabled
- Windows 10/11 with an NVIDIA GPU
- Docker Desktop Settings → **Resources → Enable GPU** (no extra toolkit needed on Windows)

---

## Quick Start (CPU only)

```powershell
docker-compose up -d
```

Access the app at **http://localhost:17493**

> ⚠️ CPU mode is very slow for TTS generation. Use the CUDA method below if you have an NVIDIA GPU.

---

## Quick Start (NVIDIA GPU / CUDA) — Recommended

```powershell
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up -d
```

Verify the GPU is detected:

```powershell
docker logs voicebox --tail 15
```

You should see a line like:
```
GPU available: CUDA (NVIDIA GeForce RTX XXXX)
```

---

## Stopping the Container

```powershell
docker-compose down
```

Your data (voice profiles, generation history, database, cached models) is stored in Docker volumes and **persists across restarts**.

---

## Rebuilding After Code Changes

```powershell
# CPU
docker-compose up -d --build

# CUDA (recommended)
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up -d --build
```

---

## First Run — Model Download

The Qwen3-TTS model is **not bundled** in the image. It downloads automatically from HuggingFace on the first generation request (~4 GB for the 1.7B model). This only happens once — the model is cached in the `voicebox-hf-cache` Docker volume.

Watch the download progress:

```powershell
docker logs voicebox -f
```

---

## Access Points

| URL | Description |
|-----|-------------|
| http://localhost:17493 | Web UI |
| http://localhost:17493/docs | FastAPI interactive API docs |
| http://localhost:17493/health | Health check endpoint |

---

## Volume Management

Two named volumes store persistent data:

| Volume | Contents |
|--------|----------|
| `voicebox_voicebox-data` | Database, voice profiles, generated audio |
| `voicebox_voicebox-hf-cache` | Downloaded HuggingFace models |

### List volumes
```powershell
docker volume ls
```

### Delete all data and start fresh
```powershell
docker-compose down -v
```

> ⚠️ This deletes all your voice profiles, history, and cached models permanently.

### Delete only the model cache (force re-download)
```powershell
docker volume rm voicebox_voicebox-hf-cache
```

---

## Environment Variables

Copy `.env.example` to `.env` to customise behaviour:

```powershell
copy .env.example .env
```

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `/app/data` | Path inside container for app data |
| `HF_HOME` | `/app/hf_cache` | HuggingFace cache directory |
| `DEFAULT_MODEL` | `Qwen/Qwen3-TTS-0.6B` | TTS model to use |
| `CUDA_VISIBLE_DEVICES` | `0` | GPU index (CUDA compose only) |

---

## Checking GPU Usage During Generation

While a generation is running:

```powershell
docker exec voicebox nvidia-smi
```

You should see GPU memory being consumed during inference.

---

## Troubleshooting

### Container starts but GPU not detected
- Open Docker Desktop → Settings → Resources → check GPU is enabled
- Restart Docker Desktop
- Re-run with the CUDA compose files

### Port already in use
```powershell
# Find what's using port 17493
netstat -ano | findstr :17493
```

### View full container logs
```powershell
docker logs voicebox
```

### Restart without rebuilding
```powershell
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml restart
```

### Shell into the running container
```powershell
docker exec -it voicebox bash
```

---

## Docker Compose File Reference

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Base service definition (CPU) |
| `docker-compose.cuda.yml` | CUDA GPU override — layer on top of base |

Always use **both files together** for GPU support:
```powershell
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml <command>
```
