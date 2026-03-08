# Running Voicebox in Docker

This guide covers running Voicebox as a Docker container on **Linux or Windows** with CPU or CUDA GPU inference. The container runs the Python FastAPI backend and serves the web UI — no desktop app or Rust build required.

> **Apple Silicon (M1/M2/M3)?** The MLX backend that gives 4–5× faster inference only works on macOS natively. Use the [macOS desktop app](https://github.com/jamiepine/voicebox/releases) instead.

---

## What the container includes

| Component | Details |
|-----------|---------|
| FastAPI backend | Python 3.11, port **17493** |
| Web frontend | Built React/Vite SPA, served as static files by FastAPI |
| Voice model | Qwen3-TTS — auto-downloaded from HuggingFace on first use |
| Transcription | Whisper (PyTorch) |
| Inference backend | PyTorch CPU by default; CUDA GPU via override (see below) |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) ≥ 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) ≥ 1.29
- **RAM:** 8 GB minimum, 16 GB recommended (the 1.7B model needs ~6 GB)
- **Disk:** 10 GB free (model weights + build layers)
- **GPU (optional):** NVIDIA GPU + [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

---

## Quick start (CPU)

```bash
# 1. Clone your fork
git clone https://github.com/sergio-caracas/voicebox.git
cd voicebox

# 2. Build the image and start the container
docker-compose up -d --build

# 3. Stream logs to watch the startup (first run downloads the model)
docker-compose logs -f

# 4. Open the app
#    Web UI:  http://localhost:17493
#    API docs: http://localhost:17493/docs
```

The first startup will download the Qwen3-TTS model (~4 GB) from HuggingFace. Subsequent starts use the cached weights from the `voicebox-hf-cache` volume and boot in seconds.

---

## GPU acceleration (CUDA)

Layer the CUDA override on top of the base compose file:

```bash
# Requires nvidia-container-toolkit on the host
docker-compose -f docker-compose.yml -f docker-compose.cuda.yml up -d --build

# Verify the GPU is visible inside the container
docker-compose exec voicebox nvidia-smi
```

Install nvidia-container-toolkit (Ubuntu/Debian):
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

---

## Managing the container

```bash
# Stop the container
docker-compose down

# Stop and remove all volumes (DELETES voice profiles and generated audio!)
docker-compose down -v

# Rebuild after a code change
docker-compose up -d --build

# Open a shell inside the running container
docker-compose exec voicebox bash
```

---

## Data persistence

Docker named volumes keep your data safe across container restarts:

| Volume | Path inside container | Contents |
|--------|-----------------------|----------|
| `voicebox-data` | `/app/data` | SQLite DB, voice profiles, generated audio, prompt cache |
| `voicebox-hf-cache` | `/app/hf_cache` | Downloaded Qwen3-TTS and Whisper model weights |

```bash
# List volumes
docker volume ls | grep voicebox

# Back up your voice profiles and generated audio
docker run --rm \
  -v voicebox_voicebox-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/voicebox-data-backup.tar.gz -C /data .

# Restore from backup
docker run --rm \
  -v voicebox_voicebox-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/voicebox-data-backup.tar.gz -C /data
```

---

## Environment variables

Copy `.env.example` to `.env` to override defaults:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `/app/data` | Where voicebox stores its database and audio |
| `HF_HOME` | `/app/hf_cache` | HuggingFace model download cache |
| `DEFAULT_MODEL` | *(auto)* | Pre-select a model: `Qwen/Qwen3-TTS-12Hz-1.7B-Base` or `Qwen/Qwen3-TTS-12Hz-0.6B-Base` |
| `CUDA_VISIBLE_DEVICES` | *(unset)* | GPU index (CUDA override only) |

---

## Troubleshooting

**Container exits immediately**
```bash
docker-compose logs voicebox   # Check the error message
```

**Port 17493 already in use**
```bash
# Find what's using it
lsof -i :17493       # Linux/macOS
netstat -ano | findstr 17493   # Windows

# Or change the host port in docker-compose.yml:
ports:
  - "8080:17493"   # Access at http://localhost:8080 instead
```

**Model download times out or fails**
The model is downloaded at runtime on the first generation request, not at container startup. If the download fails mid-way, it will resume from the volume cache on the next attempt. Check logs with `docker-compose logs -f` and wait — it can take several minutes on slow connections.

**Out of memory during inference**
Use the smaller 0.6B model by setting `DEFAULT_MODEL=Qwen/Qwen3-TTS-12Hz-0.6B-Base` in your `.env` file.

**GPU not detected**
```bash
# Confirm toolkit is installed
docker run --rm --gpus all nvidia/cuda:12.1-base-ubuntu22.04 nvidia-smi
```

---

## API usage

Once running, the backend exposes a full REST API:

```bash
# Generate speech
curl -X POST http://localhost:17493/generate \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Docker", "profile_id": "abc123", "language": "en"}'

# List voice profiles
curl http://localhost:17493/profiles

# Health check
curl http://localhost:17493/health
```

Full interactive API docs: **http://localhost:17493/docs**
