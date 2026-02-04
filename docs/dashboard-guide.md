# GX10 Dashboard User Guide

A comprehensive guide for the GX10 System Monitoring Dashboard.

---

## Overview

The GX10 Dashboard is a web-based real-time monitoring interface for the ASUS Ascent GX10 local AI development environment. It provides comprehensive system monitoring, GPU metrics, Brain mode management, and Ollama integration in a single unified interface.

### Purpose

- Monitor system health and resource utilization in real-time
- Track GPU performance and temperature for AI workloads
- Manage Code Brain and Vision Brain switching
- Monitor Ollama model status and loaded models

### Real-time Monitoring Capabilities

The dashboard provides live updates every 2 seconds via WebSocket connection, ensuring you always have current system information without manual refresh.

### Access URL

| Access Location | URL |
|-----------------|-----|
| Local (on GX10) | http://localhost:9000 |
| Same Network | http://[GX10-IP]:9000 |
| Via Tailscale | http://[Tailscale-IP]:9000 |

To find your GX10 IP address:

```bash
# Local network IP
hostname -I | awk '{print $1}'

# Tailscale IP (if configured)
tailscale ip -4
```

---

## Features

### System Monitoring

The dashboard displays comprehensive system information including:

| Metric | Description |
|--------|-------------|
| Hostname | System hostname for identification |
| Uptime | Time since last system boot |
| OS | Operating system name and version |
| Kernel | Linux kernel version |
| Architecture | CPU architecture (aarch64 for GX10) |

#### CPU Monitoring

| Metric | Description |
|--------|-------------|
| Usage | Current CPU utilization percentage |
| Cores | Number of CPU cores (20 for GX10) |
| Temperature | CPU temperature in Celsius (if available) |

#### Memory Monitoring

| Metric | Description |
|--------|-------------|
| Total | Total system memory (128GB for GX10) |
| Used | Currently used memory |
| Free | Available memory |
| Percentage | Memory utilization percentage |

#### Disk Space Monitoring

| Metric | Description |
|--------|-------------|
| Total | Total disk capacity |
| Used | Used disk space |
| Free | Available disk space |
| Percentage | Disk utilization percentage |
| Mount Point | Filesystem mount location (/, /home) |

### GPU Monitoring

The dashboard provides detailed NVIDIA GPU metrics:

| Metric | Description |
|--------|-------------|
| Name | GPU model name (NVIDIA GB10 for GX10) |
| Utilization | GPU compute utilization percentage |
| VRAM Total | Total GPU memory |
| VRAM Used | Currently used GPU memory |
| VRAM Free | Available GPU memory |
| Temperature | GPU temperature in Celsius |
| Power Draw | Current power consumption in Watts |
| Power Limit | Maximum power limit |
| Fan Speed | Fan speed percentage (if available) |
| Driver Version | NVIDIA driver version |
| CUDA Version | Installed CUDA version |

**Note**: Some GPU metrics (like VRAM usage) may show "N/A" on certain GPU models like the GB10 that do not support memory queries via nvidia-smi.

### Brain Status

The Two Brain architecture allows switching between Code Brain and Vision Brain:

| Mode | Description | Engine | Use Case |
|------|-------------|--------|----------|
| Code Brain | Native Ollama mode | Ollama (systemd) | Coding, text generation |
| Vision Brain | Docker container mode | PyTorch Container | Vision tasks, image processing |

The dashboard displays:

| Information | Description |
|-------------|-------------|
| Active Brain | Currently active brain mode |
| Started At | When the current brain was activated |
| Uptime | How long the current brain has been running |
| Scripts Available | Whether brain switching scripts are installed |

#### Brain Switching

You can switch between brains directly from the dashboard or via API:

**Via Dashboard**: Click the brain mode toggle button in the Brain Status section.

**Via API**:

```bash
# Switch to Code Brain
curl -X POST http://localhost:9000/api/brain/switch \
  -H "Content-Type: application/json" \
  -d '{"target": "code"}'

# Switch to Vision Brain
curl -X POST http://localhost:9000/api/brain/switch \
  -H "Content-Type: application/json" \
  -d '{"target": "vision"}'
```

**Via Command Line**:

```bash
sudo /gx10/api/switch.sh code    # Switch to Code Brain
sudo /gx10/api/switch.sh vision  # Switch to Vision Brain
```

**Important**: Only one brain can be active at a time. Switching typically takes 5-17 seconds.

### Ollama Integration

When Code Brain is active, the dashboard shows Ollama status:

| Information | Description |
|-------------|-------------|
| Status | Running or stopped |
| Version | Ollama version number |
| Installed Models | List of all installed models |
| Loaded Models | Currently loaded models in memory |

---

## Alert System

The dashboard includes a real-time alert system that monitors key metrics and notifies you when thresholds are exceeded.

### Alert Types

| Alert Type | Warning Threshold | Critical Threshold |
|------------|------------------|-------------------|
| CPU Usage | > 80% | > 90% |
| GPU Temperature | > 75C | > 85C |
| Memory Usage | > 80% | > 90% |
| Disk Space | > 85% | > 95% |

### Alert Severity Levels

| Severity | Description | Action Required |
|----------|-------------|-----------------|
| Warning | Metric approaching dangerous levels | Monitor closely |
| Critical | Metric at dangerous levels | Immediate attention required |

### Configuring Thresholds

Alert thresholds can be customized via the API:

```bash
# Get current thresholds
curl http://localhost:9000/api/alerts/thresholds

# Update thresholds (example)
curl -X POST http://localhost:9000/api/alerts/thresholds \
  -H "Content-Type: application/json" \
  -d '{
    "cpu": {"warning": 85, "critical": 95},
    "gpu_temp": {"warning": 80, "critical": 90},
    "memory": {"warning": 85, "critical": 95},
    "disk": {"warning": 90, "critical": 98}
  }'

# Reset to default thresholds
curl -X POST http://localhost:9000/api/alerts/reset
```

### Alert Notifications

Alerts are delivered in real-time through the WebSocket connection. Each alert contains:

| Field | Description |
|-------|-------------|
| type | Alert category (cpu, gpu_temp, memory, disk) |
| severity | Warning or critical |
| message | Human-readable description |
| value | Current metric value |
| threshold | Threshold that was exceeded |

### Alert History

View recent alerts via the WebSocket stream. Alerts are included with each metrics update:

```json
{
  "type": "metrics",
  "data": { ... },
  "alerts": [
    {
      "type": "cpu",
      "severity": "warning",
      "message": "CPU usage (82.5%) exceeds warning threshold",
      "value": 82.5,
      "threshold": 80
    }
  ]
}
```

---

## Metrics Interpretation

### Understanding CPU Metrics

| Range | Status | Interpretation |
|-------|--------|----------------|
| 0-50% | Normal | System running efficiently |
| 50-80% | Moderate | Normal for AI workloads |
| 80-90% | High | Consider monitoring closely |
| > 90% | Critical | May indicate resource contention |

**GX10 Specifics**: With 20 CPU cores (10x Cortex-X925 + 10x Cortex-A725), the GX10 can handle high CPU utilization efficiently. Sustained high usage is normal during AI model inference.

### Understanding GPU Metrics

#### Temperature Safe Ranges

| Range | Status | Action |
|-------|--------|--------|
| < 60C | Cool | Optimal operating temperature |
| 60-75C | Normal | Expected during active workloads |
| 75-85C | Warning | Monitor closely, ensure cooling |
| > 85C | Critical | Reduce workload or improve cooling |

#### Power Draw Expectations

The NVIDIA GB10 GPU in GX10 operates efficiently within its power envelope. Power draw varies based on workload:

| Workload | Expected Power |
|----------|----------------|
| Idle | Low power consumption |
| Light inference | Moderate power |
| Heavy inference | Near power limit |

#### VRAM Usage Guidelines

| Usage | Interpretation |
|-------|----------------|
| < 50% | Plenty of headroom for larger models |
| 50-80% | Healthy utilization |
| 80-95% | Consider model size or batch size |
| > 95% | Risk of out-of-memory errors |

**Note**: GX10 uses unified memory (128GB LPDDR5x shared between CPU and GPU), so traditional VRAM metrics may not apply directly.

### Understanding Memory Metrics

| Range | Status | Interpretation |
|-------|--------|----------------|
| < 50% | Normal | Plenty of available memory |
| 50-70% | Moderate | Normal for loaded AI models |
| 70-80% | High | Models and caches using memory efficiently |
| 80-90% | Warning | Memory pressure increasing |
| > 90% | Critical | Risk of swap usage or OOM |

**Expected Usage Patterns**:
- Ollama models (30-40GB): Code Brain typically uses 30-40GB for loaded models
- Vision Brain (70-90GB): Docker container may use more memory
- System overhead: 2-4GB for OS and services

---

## Troubleshooting

### Common Issues

#### Dashboard Not Loading

**Symptoms**: Browser shows connection error or blank page.

**Solutions**:

```bash
# Check if dashboard service is running
sudo systemctl status gx10-dashboard

# Check if port 9000 is listening
ss -tlnp | grep 9000

# Check service logs for errors
sudo journalctl -u gx10-dashboard -n 50
```

#### WebSocket Disconnection

**Symptoms**: Dashboard shows "Disconnected" status, metrics stop updating.

**Solutions**:

1. Refresh the browser page
2. Check network connectivity
3. Verify the service is running:

```bash
sudo systemctl status gx10-dashboard
```

4. Check for WebSocket errors in browser developer tools (F12 > Network > WS)

#### Missing GPU Data

**Symptoms**: GPU section shows "N/A" or no data.

**Solutions**:

```bash
# Check if nvidia-smi is working
nvidia-smi

# Check specific queries
nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv

# For GB10, memory queries may not be supported
nvidia-smi --query-gpu=memory.total --format=csv,noheader
# Output [N/A] indicates memory query not supported
```

#### Dashboard Not Accessible Externally

**Symptoms**: Can access from localhost but not from other machines.

**Solutions**:

```bash
# Open firewall port
sudo iptables -I INPUT -p tcp --dport 9000 -j ACCEPT

# Or using ufw
sudo ufw allow 9000/tcp

# Verify port is accessible
curl http://$(hostname -I | awk '{print $1}'):9000/api/health
```

### Service Management Commands

```bash
# Start dashboard service
sudo systemctl start gx10-dashboard

# Stop dashboard service
sudo systemctl stop gx10-dashboard

# Restart dashboard service
sudo systemctl restart gx10-dashboard

# Check service status
sudo systemctl status gx10-dashboard

# View real-time logs
sudo journalctl -u gx10-dashboard -f

# View last 100 log lines
sudo journalctl -u gx10-dashboard -n 100

# Enable service on boot
sudo systemctl enable gx10-dashboard

# Disable service on boot
sudo systemctl disable gx10-dashboard
```

### Process Management

```bash
# Check what process is using port 9000
lsof -ti:9000

# Kill process on port 9000 (if stuck)
lsof -ti:9000 | xargs kill -9

# Check all Node.js processes
ps aux | grep node
```

---

## API Reference

### Endpoints Overview

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/health | Health check |
| GET | /api/status | Full system status |
| GET | /api/status/system | System info only |
| GET | /api/status/gpu | GPU info with processes |
| GET | /api/brain | Brain status |
| POST | /api/brain/switch | Switch brain mode |
| GET | /api/brain/history | Brain switch history |
| GET | /api/metrics | Quick metrics |
| GET | /api/ollama | Ollama status |
| GET | /api/ollama/models | Installed models |
| GET | /api/ollama/ps | Running models |
| WS | /ws | Real-time metrics stream |

### Endpoint Details

#### GET /api/health

Health check endpoint for monitoring.

```bash
curl http://localhost:9000/api/health
```

Response:

```json
{
  "status": "ok",
  "timestamp": "2026-02-03T10:00:00.000Z",
  "uptime": 3600
}
```

#### GET /api/status

Full system status including all metrics.

```bash
curl http://localhost:9000/api/status
```

Response includes: timestamp, system info, CPU, memory, disk, GPU, brain status, and Ollama status.

#### GET /api/metrics

Quick metrics for lightweight polling.

```bash
curl http://localhost:9000/api/metrics
```

Response includes: timestamp, CPU usage, memory percentage, GPU utilization, brain mode, and loaded models.

#### GET /api/brain

Current brain status.

```bash
curl http://localhost:9000/api/brain
```

Response:

```json
{
  "active": "code",
  "started_at": "2026-02-03T08:00:00.000Z",
  "uptime_seconds": 7200,
  "scripts_available": {
    "statusScript": true,
    "switchScript": true
  }
}
```

#### POST /api/brain/switch

Switch between brain modes.

```bash
curl -X POST http://localhost:9000/api/brain/switch \
  -H "Content-Type: application/json" \
  -d '{"target": "vision"}'
```

Response:

```json
{
  "success": true,
  "previous": "code",
  "current": "vision",
  "duration_ms": 5230
}
```

#### GET /api/brain/history

View recent brain switch history.

```bash
curl http://localhost:9000/api/brain/history
```

Response:

```json
{
  "history": [
    {
      "timestamp": "2026-02-03T10:00:00.000Z",
      "from": "code",
      "to": "vision",
      "duration_ms": 5230
    }
  ]
}
```

#### WebSocket /ws

Real-time metrics stream with 2-second update interval.

Connect using WebSocket client:

```javascript
const ws = new WebSocket('ws://localhost:9000/ws');

ws.onmessage = (event) => {
  const { type, data, alerts } = JSON.parse(event.data);
  console.log('Metrics:', data);
  console.log('Alerts:', alerts);
};
```

Message format:

```json
{
  "type": "metrics",
  "data": {
    "timestamp": "2026-02-03T10:00:00.000Z",
    "cpu": { "usage": 25.5, "temperature": null },
    "memory": { "used": 34359738368, "percentage": 25.0 },
    "gpu": {
      "utilization": 45,
      "memory_used": null,
      "temperature": 55,
      "power_draw": 30.5
    },
    "brain": { "active": "code" },
    "ollama": { "models_loaded": ["qwen2.5-coder:32b"] }
  },
  "alerts": []
}
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 9000 | Dashboard server port |
| OLLAMA_API_URL | http://localhost:11434 | Ollama API endpoint |
| NODE_ENV | production | Node.js environment |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-02-03 | Added alert system with configurable thresholds |
| 1.0 | 2026-02-03 | Initial release with system/GPU monitoring, Brain management, Ollama integration |

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [Implementation Guide](implementation-guide.md) | Complete GX10 implementation details |
| [Two Brain Architecture](two-brain-architecture.md) | Code/Vision Brain architecture |
| [External Access Guide](external-access.md) | Remote access via Tailscale |
| [GX10 Dashboard README](https://github.com/holee9/gx10-dashboard) | Dashboard source repository |

---

## Technical Stack

### Backend

| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 20 LTS | Runtime environment |
| Express.js | 4.x | HTTP server framework |
| TypeScript | 5.x | Type-safe JavaScript |
| ws | - | WebSocket support |

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18 | UI framework |
| Vite | 6 | Build tool |
| TypeScript | 5.x | Type-safe JavaScript |
| Tailwind CSS | 3 | Styling |
| Recharts | - | Charts and graphs |
| Zustand | - | State management |

---

**Document Version**: 1.0.0
**Last Updated**: 2026-02-03
**Author**: MoAI-ADK Documentation System
