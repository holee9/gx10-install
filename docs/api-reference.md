# GX10 Brain API Reference

## Overview

The GX10 Brain API provides shell-based endpoints for managing the dual-brain system architecture. The API scripts are located at `/gx10/api/` and enable programmatic control of brain switching, status monitoring, and system resource management.

The dual-brain architecture supports:
- **Code Brain**: Ollama-based local LLM for coding assistance (qwen2.5-coder:32b)
- **Vision Brain**: Docker-based vision-language model (Qwen2.5-VL-32B)

---

## API Scripts

### status.sh

**Purpose**: Get comprehensive system and brain status information.

**Location**: `/gx10/api/status.sh`

**Usage**:
```bash
bash /gx10/api/status.sh
```

**What it checks**:
- Memory status (RAM and Swap via `free -h`)
- GPU status (nvidia-smi: name, memory, utilization)
- Code Brain (Ollama service status and loaded models)
- Vision Brain (Docker container status)
- Active brain from state file
- Disk usage (root filesystem)
- UMA Memory Health (buffer cache status for DGX OS)

**State File Location**: `/gx10/runtime/active_brain.json`

**State File Format**:
```json
{
  "active_brain": "code",
  "started_at": "2026-02-04T10:30:00+09:00",
  "last_task": null
}
```

**Exit Codes**:
- `0`: Always returns success (status checking mode)

**Dependencies**:
- `nvidia-smi` (optional, for GPU info)
- `ollama` command (optional, for model listing)
- `docker` command (optional, for Vision Brain status)
- `jq` (optional, for JSON parsing; falls back to grep)

---

### switch.sh

**Purpose**: Switch between Code Brain (Ollama) and Vision Brain (Docker).

**Location**: `/gx10/api/switch.sh`

**Usage**:
```bash
bash /gx10/api/switch.sh <target>
```

**Parameters**:
| Parameter | Description |
|-----------|-------------|
| `code` | Switch to Code Brain (starts Ollama service) |
| `vision` | Switch to Vision Brain (starts Docker container via `/gx10/brains/vision/run.sh`) |
| `none` | Stop all brains (unload models, stop services) |

**Switch Process (4 Steps)**:

1. **Stop Current Brains**
   - Unloads all running Ollama models
   - Stops and removes Vision Brain Docker container

2. **Flush Buffer Cache**
   - Runs `sync` and flushes page cache
   - Critical for UMA (Unified Memory Architecture) on DGX systems
   - Requires sudo access

3. **Start Target Brain**
   - `code`: Starts Ollama via systemd, warms up with API call
   - `vision`: Executes `/gx10/brains/vision/run.sh`
   - `none`: Stops Ollama service, leaves system idle

4. **Update State**
   - Writes new state to `/gx10/runtime/active_brain.json`
   - Optionally runs status script to display new state

**Exit Codes**:
| Code | Description |
|------|-------------|
| `0` | Switch completed successfully |
| `1` | Invalid parameter or usage error |

**Example**:
```bash
# Switch to Code Brain
bash /gx10/api/switch.sh code

# Switch to Vision Brain
bash /gx10/api/switch.sh vision

# Stop all brains (free GPU memory)
bash /gx10/api/switch.sh none
```

---

## Service Endpoints

### Ollama (Code Brain)

The Code Brain uses Ollama for local LLM inference.

**Base URL**: `http://localhost:11434`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check (returns "Ollama is running") |
| `/api/version` | GET | Get Ollama version |
| `/api/tags` | GET | List installed models |
| `/api/ps` | GET | List currently loaded/running models |
| `/api/generate` | POST | Generate text completion |
| `/api/chat` | POST | Chat completion |
| `/api/pull` | POST | Pull a model from registry |
| `/api/delete` | DELETE | Delete a model |

**Example - List Models**:
```bash
curl http://localhost:11434/api/tags
```

**Response**:
```json
{
  "models": [
    {
      "name": "qwen2.5-coder:32b",
      "size": 19853023744,
      "digest": "abc123...",
      "modified_at": "2026-02-01T10:00:00Z",
      "details": {
        "format": "gguf",
        "family": "qwen2",
        "parameter_size": "32B",
        "quantization_level": "Q4_K_M"
      }
    }
  ]
}
```

**Example - Generate**:
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:32b",
    "prompt": "Write a Python function to calculate fibonacci",
    "stream": false
  }'
```

**Example - List Running Models**:
```bash
curl http://localhost:11434/api/ps
```

**Response**:
```json
{
  "models": [
    {
      "name": "qwen2.5-coder:32b",
      "model": "qwen2.5-coder:32b",
      "size": 19853023744,
      "digest": "abc123...",
      "expires_at": "2026-02-04T11:30:00Z",
      "size_vram": 19853023744
    }
  ]
}
```

---

### Vision Brain (Docker)

The Vision Brain runs as a Docker container named `gx10-vision`.

**Container Name**: `gx10-vision`

**Docker Commands**:
```bash
# Check container status
docker ps -f name=gx10-vision

# View container logs
docker logs gx10-vision

# Get container stats
docker stats gx10-vision --no-stream

# Stop container
docker stop gx10-vision
```

**Health Check**:
```bash
# Check if container is running
docker inspect gx10-vision --format '{{.State.Running}}'
```

---

## Configuration

### Environment File

**Location**: `/gx10/config/.env`

Environment variables can be used to configure the Brain API behavior.

### State Directory

**Location**: `/gx10/runtime/`

Contains runtime state files:
- `active_brain.json` - Current active brain state

### Script Locations

| Script | Path |
|--------|------|
| Status | `/gx10/api/status.sh` |
| Switch | `/gx10/api/switch.sh` |
| Vision Run | `/gx10/brains/vision/run.sh` |

---

## Integration with Dashboard

The GX10 Dashboard server at `http://localhost:9000` provides a REST API wrapper around these shell scripts. See [Dashboard API Reference](./dashboard-api.md) for the HTTP API documentation.

The Dashboard provides:
- REST endpoints for brain status and switching
- WebSocket for real-time metrics
- Automatic brain state synchronization

---

## Troubleshooting

### Common Issues

**Ollama Service Not Starting**:
```bash
# Check service status
systemctl status ollama

# View service logs
journalctl -u ollama -f

# Manual start
sudo systemctl start ollama
```

**Vision Container Not Starting**:
```bash
# Check Docker status
docker ps -a

# View container logs
docker logs gx10-vision

# Check GPU availability
nvidia-smi
```

**Insufficient GPU Memory**:
```bash
# Flush buffer cache
sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'

# Check current GPU memory usage
nvidia-smi

# Stop all brains to free memory
bash /gx10/api/switch.sh none
```

**State File Not Updating**:
```bash
# Check directory permissions
ls -la /gx10/runtime/

# Create directory if missing
sudo mkdir -p /gx10/runtime
sudo chown $USER:$USER /gx10/runtime
```

---

## Security Considerations

- The switch script requires sudo access for cache flushing
- State files are world-readable by default
- Docker socket access required for Vision Brain management
- Ollama API is bound to localhost only

---

## Version Compatibility

| Component | Version |
|-----------|---------|
| DGX OS | 7.2.3+ |
| Ollama | 0.3.0+ |
| Docker | 24.0+ |
| NVIDIA Driver | 550+ |
| CUDA | 12.4+ |
