# GX10 Dashboard API Reference

## Overview

The GX10 Dashboard provides a comprehensive REST API and WebSocket interface for monitoring and managing the GX10 system. The server is built with Express.js and TypeScript.

**Server Port**: 9000 (configurable via `PORT` environment variable)

**Base URL**: `http://localhost:9000/api`

**WebSocket URL**: `ws://localhost:9000/ws`

---

## Authentication

No authentication is required. The Dashboard is designed for local network access only.

**Security Note**: The Dashboard should not be exposed to the public internet without additional security measures.

---

## Health Check

### GET /api/health

Health check endpoint for monitoring server availability.

**Response** `200 OK`:
```json
{
  "status": "ok",
  "timestamp": "2026-02-04T12:00:00.000Z",
  "uptime": 3600.5
}
```

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Always "ok" if server is responding |
| `timestamp` | string | ISO 8601 timestamp |
| `uptime` | number | Server uptime in seconds |

---

## System Status

### GET /api/status

Get comprehensive system status including all metrics.

**Response** `200 OK`:
```json
{
  "timestamp": "2026-02-04T12:00:00.000Z",
  "system": {
    "hostname": "gx10-workstation",
    "uptime": 86400,
    "os": "DGX OS 7.2.3",
    "kernel": "6.14.0-1015-nvidia",
    "arch": "x64"
  },
  "cpu": {
    "usage": 25.5,
    "cores": 24,
    "temperature": 45
  },
  "memory": {
    "total": 137438953472,
    "used": 48103556710,
    "free": 89335396762,
    "percentage": 35.0
  },
  "disk": [
    {
      "mountPoint": "/",
      "total": 1000204886016,
      "used": 450092098560,
      "free": 550112787456,
      "percentage": 45.0
    }
  ],
  "gpu": {
    "name": "NVIDIA RTX 4090",
    "memory_total": 25769803776,
    "memory_used": 2576980378,
    "memory_free": 23192823398,
    "utilization": 10,
    "temperature": 42,
    "power_draw": 85.5,
    "power_limit": 450,
    "fan_speed": 30,
    "driver_version": "550.54.14",
    "cuda_version": "12.4"
  },
  "brain": {
    "active": "code",
    "started_at": "2026-02-04T10:00:00.000Z",
    "uptime_seconds": 7200
  },
  "ollama": {
    "status": "running",
    "version": "0.3.12",
    "models_loaded": ["qwen2.5-coder:32b"]
  }
}
```

### GET /api/status/system

Get system information only.

**Response** `200 OK`:
```json
{
  "hostname": "gx10-workstation",
  "uptime": 86400,
  "os": "DGX OS 7.2.3",
  "kernel": "6.14.0-1015-nvidia",
  "arch": "x64"
}
```

### GET /api/status/gpu

Get GPU information with process list.

**Response** `200 OK`:
```json
{
  "gpu": {
    "name": "NVIDIA RTX 4090",
    "memory_total": 25769803776,
    "memory_used": 2576980378,
    "memory_free": 23192823398,
    "utilization": 10,
    "temperature": 42,
    "power_draw": 85.5,
    "power_limit": 450,
    "fan_speed": 30,
    "driver_version": "550.54.14",
    "cuda_version": "12.4"
  },
  "processes": [
    {
      "pid": 3237,
      "name": "/usr/lib/xorg/Xorg",
      "memory_used": 45088768
    },
    {
      "pid": 12345,
      "name": "ollama_llama_server",
      "memory_used": 19853023744
    }
  ]
}
```

---

## Metrics

### GET /api/metrics

Quick metrics for real-time dashboard updates. Lighter payload than full status.

**Response** `200 OK`:
```json
{
  "timestamp": "2026-02-04T12:00:00.000Z",
  "cpu": {
    "usage": 25.5,
    "temperature": 45
  },
  "memory": {
    "used": 48103556710,
    "percentage": 35.0
  },
  "gpu": {
    "utilization": 10,
    "memory_used": 2576980378,
    "temperature": 42,
    "power_draw": 85.5
  }
}
```

### GET /api/metrics/disk

Get disk usage information.

**Response** `200 OK`:
```json
{
  "disk": [
    {
      "mountPoint": "/",
      "total": 1000204886016,
      "used": 450092098560,
      "free": 550112787456,
      "percentage": 45.0
    },
    {
      "mountPoint": "/home",
      "total": 2000409772032,
      "used": 800163908813,
      "free": 1200245863219,
      "percentage": 40.0
    }
  ]
}
```

### GET /api/metrics/storage

Get detailed storage status for all drives (NVMe, SSD, HDD, external).

**Response** `200 OK`:
```json
{
  "disks": [
    {
      "name": "nvme0n1",
      "size": "1.0 TB",
      "type": "nvme",
      "model": "Samsung SSD 990 PRO 1TB",
      "mountPoint": "/",
      "total": 1000204886016,
      "used": 450092098560,
      "available": 550112787456,
      "percentage": 45,
      "health": "Healthy",
      "temperature": 38
    },
    {
      "name": "sda",
      "size": "4.0 TB",
      "type": "hdd",
      "model": "WD Red Pro 4TB",
      "mountPoint": "/data",
      "total": 4000787030016,
      "used": 1600314812006,
      "available": 2400472218010,
      "percentage": 40,
      "health": "Healthy"
    }
  ],
  "totalStorage": 5000991916032,
  "usedStorage": 2050406910566,
  "availableStorage": 2950585005466
}
```

| Disk Type | Description |
|-----------|-------------|
| `nvme` | NVMe SSD (PCIe) |
| `ssd` | SATA SSD |
| `hdd` | Hard disk drive |
| `usb` | USB storage |
| `external` | External/unknown storage |

### GET /api/metrics/network

Get network interface information.

**Response** `200 OK`:
```json
{
  "interfaces": [
    {
      "name": "enP7s7",
      "type": "ethernet",
      "state": "up",
      "mac": "00:11:22:33:44:55",
      "ipv4": "192.168.1.100",
      "ipv6": "2001:db8::1",
      "speed": "1000Mb/s",
      "driver": "r8169",
      "description": "Onboard Ethernet (RJ45)"
    },
    {
      "name": "enp1s0f0np0",
      "type": "sfp",
      "state": "up",
      "mac": "00:11:22:33:44:66",
      "ipv4": "10.0.0.100",
      "ipv6": null,
      "speed": "25000Mb/s",
      "driver": "mlx5_core",
      "description": "ConnectX-7 SFP+ Port",
      "isConnectX": true,
      "pciAddress": "0000:01:00.0"
    },
    {
      "name": "tailscale0",
      "type": "vpn",
      "state": "up",
      "mac": null,
      "ipv4": "100.64.0.1",
      "ipv6": null,
      "speed": null,
      "driver": null,
      "description": "Tailscale VPN"
    }
  ],
  "primaryInterface": "enP7s7",
  "primaryIp": "192.168.1.100",
  "tailscaleIp": "100.64.0.1"
}
```

| Interface Type | Description |
|----------------|-------------|
| `ethernet` | Wired Ethernet (RJ45) |
| `sfp` | SFP/SFP+ fiber port |
| `wifi` | Wireless interface |
| `vpn` | VPN tunnel (Tailscale, etc.) |
| `bridge` | Bridge/Docker network |
| `virtual` | Virtual interface |
| `loopback` | Loopback interface |

---

## Brain Management

### GET /api/brain

Get current brain status.

**Response** `200 OK`:
```json
{
  "active": "code",
  "started_at": "2026-02-04T10:00:00.000Z",
  "uptime_seconds": 7200,
  "scripts_available": {
    "statusScript": true,
    "switchScript": true
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `active` | string | Current active brain: "code" or "vision" |
| `started_at` | string | ISO 8601 timestamp when brain was activated |
| `uptime_seconds` | number | Seconds since brain was activated |
| `scripts_available` | object | Availability of shell scripts |

### POST /api/brain/switch

Switch between brain modes.

**Request Body**:
```json
{
  "target": "code"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `target` | string | Yes | "code" or "vision" |

**Response** `200 OK` (Success):
```json
{
  "success": true,
  "previous": "vision",
  "current": "code",
  "duration_ms": 15230
}
```

**Response** `400 Bad Request` (Invalid target):
```json
{
  "error": "Invalid target",
  "message": "Target must be \"code\" or \"vision\""
}
```

**Response** `500 Internal Server Error` (Switch failed):
```json
{
  "success": false,
  "previous": "code",
  "current": "code",
  "duration_ms": 5000,
  "error": "Failed to start vision brain container"
}
```

### GET /api/brain/history

Get brain switch history (last 100 entries).

**Response** `200 OK`:
```json
{
  "history": [
    {
      "timestamp": "2026-02-04T10:00:00.000Z",
      "from": "vision",
      "to": "code",
      "duration_ms": 15230
    },
    {
      "timestamp": "2026-02-04T08:30:00.000Z",
      "from": "code",
      "to": "vision",
      "duration_ms": 23450
    }
  ]
}
```

---

## Ollama Management

### GET /api/ollama

Get Ollama service status (alias for /api/metrics/ollama).

**Response** `200 OK`:
```json
{
  "status": "running",
  "version": "0.3.12",
  "models": [
    {
      "name": "qwen2.5-coder:32b",
      "size": 19853023744,
      "digest": "sha256:abc123...",
      "modified_at": "2026-02-01T10:00:00Z",
      "details": {
        "format": "gguf",
        "family": "qwen2",
        "parameter_size": "32B",
        "quantization_level": "Q4_K_M"
      }
    }
  ],
  "running_models": [
    {
      "name": "qwen2.5-coder:32b",
      "model": "qwen2.5-coder:32b",
      "size": 19853023744,
      "digest": "sha256:abc123...",
      "expires_at": "2026-02-04T12:30:00Z",
      "size_vram": 19853023744
    }
  ]
}
```

| Status | Description |
|--------|-------------|
| `running` | Ollama service is running and responsive |
| `stopped` | Ollama service is not running |
| `unknown` | Unable to determine status |

### GET /api/ollama/models

Get list of installed Ollama models.

**Response** `200 OK`:
```json
{
  "models": [
    {
      "name": "qwen2.5-coder:32b",
      "size": 19853023744,
      "digest": "sha256:abc123...",
      "modified_at": "2026-02-01T10:00:00Z"
    }
  ]
}
```

### GET /api/ollama/ps

Get list of currently running/loaded models.

**Response** `200 OK`:
```json
{
  "models": [
    {
      "name": "qwen2.5-coder:32b",
      "model": "qwen2.5-coder:32b",
      "size": 19853023744,
      "digest": "sha256:abc123...",
      "expires_at": "2026-02-04T12:30:00Z",
      "size_vram": 19853023744
    }
  ]
}
```

### GET /api/ollama/health

Quick health check for Ollama service.

**Response** `200 OK`:
```json
{
  "healthy": true,
  "status": "running",
  "version": "0.3.12"
}
```

---

## Vision Brain

### GET /api/metrics/vision

Get Vision Brain (Docker container) status.

**Response** `200 OK` (Running):
```json
{
  "status": "running",
  "container_id": "abc123def456",
  "container_name": "gx10-vision",
  "image": "gx10-vision:latest",
  "uptime": "Up 2 hours",
  "gpu_attached": true,
  "memory_usage": "24.5GiB / 128GiB"
}
```

**Response** `200 OK` (Stopped):
```json
{
  "status": "stopped"
}
```

| Status | Description |
|--------|-------------|
| `running` | Container is running |
| `stopped` | Container is not running |
| `error` | Error checking container status |

### GET /api/metrics/vision/models

Get list of Vision Brain models.

**Response** `200 OK`:
```json
{
  "models": [
    {
      "name": "Qwen2.5-VL-32B",
      "type": "Vision-Language",
      "loaded": true
    }
  ]
}
```

---

## Alerts

### GET /api/alerts/thresholds

Get current alert thresholds.

**Response** `200 OK`:
```json
{
  "thresholds": {
    "cpu": { "warning": 80, "critical": 90 },
    "gpu_temp": { "warning": 75, "critical": 85 },
    "memory": { "warning": 80, "critical": 90 },
    "disk": { "warning": 85, "critical": 95 }
  },
  "defaults": {
    "cpu": { "warning": 80, "critical": 90 },
    "gpu_temp": { "warning": 75, "critical": 85 },
    "memory": { "warning": 80, "critical": 90 },
    "disk": { "warning": 85, "critical": 95 }
  }
}
```

### POST /api/alerts/thresholds

Update alert thresholds.

**Request Body** (partial updates supported):
```json
{
  "cpu": { "warning": 70, "critical": 85 },
  "gpu_temp": { "warning": 70, "critical": 80 }
}
```

**Validation Rules**:
- All values must be numbers between 0 and 100
- Warning threshold must be less than critical threshold

**Response** `200 OK`:
```json
{
  "message": "Thresholds updated successfully",
  "thresholds": {
    "cpu": { "warning": 70, "critical": 85 },
    "gpu_temp": { "warning": 70, "critical": 80 },
    "memory": { "warning": 80, "critical": 90 },
    "disk": { "warning": 85, "critical": 95 }
  }
}
```

**Response** `400 Bad Request`:
```json
{
  "error": "Invalid threshold order",
  "message": "cpu warning threshold must be less than critical threshold"
}
```

### POST /api/alerts/thresholds/reset

Reset thresholds to default values.

**Response** `200 OK`:
```json
{
  "message": "Thresholds reset to defaults",
  "thresholds": {
    "cpu": { "warning": 80, "critical": 90 },
    "gpu_temp": { "warning": 75, "critical": 85 },
    "memory": { "warning": 80, "critical": 90 },
    "disk": { "warning": 85, "critical": 95 }
  }
}
```

---

## Settings

### GET /api/settings

Get all dashboard settings.

**Response** `200 OK`:
```json
{
  "config": {
    "server": {
      "port": 9000,
      "updateInterval": 2000
    },
    "alerts": {
      "enabled": true,
      "thresholds": {
        "cpu": { "warning": 80, "critical": 90 },
        "gpu_temp": { "warning": 75, "critical": 85 },
        "memory": { "warning": 80, "critical": 90 },
        "disk": { "warning": 85, "critical": 95 }
      }
    }
  },
  "defaults": {
    "server": {
      "port": 9000,
      "updateInterval": 2000
    },
    "alerts": {
      "enabled": true,
      "thresholds": {
        "cpu": { "warning": 80, "critical": 90 },
        "gpu_temp": { "warning": 75, "critical": 85 },
        "memory": { "warning": 80, "critical": 90 },
        "disk": { "warning": 85, "critical": 95 }
      }
    }
  }
}
```

### PUT /api/settings

Update dashboard settings.

**Request Body** (partial updates supported):
```json
{
  "server": {
    "updateInterval": 1000
  },
  "alerts": {
    "enabled": false
  }
}
```

**Validation Rules**:
- `server.port`: Number between 1 and 65535
- `server.updateInterval`: Number >= 500 (milliseconds)
- Alert thresholds: Same rules as `/api/alerts/thresholds`

**Response** `200 OK`:
```json
{
  "message": "Settings updated successfully",
  "config": {
    "server": {
      "port": 9000,
      "updateInterval": 1000
    },
    "alerts": {
      "enabled": false,
      "thresholds": { ... }
    }
  }
}
```

### POST /api/settings/reset

Reset all settings to defaults.

**Response** `200 OK`:
```json
{
  "message": "Settings reset to defaults",
  "config": {
    "server": {
      "port": 9000,
      "updateInterval": 2000
    },
    "alerts": {
      "enabled": true,
      "thresholds": { ... }
    }
  }
}
```

---

## WebSocket

### Connection

**URL**: `ws://localhost:9000/ws`

The WebSocket connection provides real-time metrics updates.

### Message Format

Messages are JSON-encoded with the following structure:

```json
{
  "type": "metrics",
  "data": {
    "timestamp": "2026-02-04T12:00:00.000Z",
    "cpu": {
      "usage": 25.5,
      "temperature": 45
    },
    "memory": {
      "used": 48103556710,
      "percentage": 35.0
    },
    "gpu": {
      "utilization": 10,
      "memory_used": 2576980378,
      "temperature": 42,
      "power_draw": 85.5
    },
    "brain": {
      "active": "code"
    },
    "ollama": {
      "models_loaded": ["qwen2.5-coder:32b"]
    }
  },
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

### Update Frequency

- Default: Every 2 seconds
- Configurable via `server.updateInterval` setting (minimum 500ms)

### Alert Severities

| Severity | Description |
|----------|-------------|
| `warning` | Value exceeds warning threshold |
| `critical` | Value exceeds critical threshold |

### Alert Types

| Type | Metric | Unit |
|------|--------|------|
| `cpu` | CPU Usage | Percentage |
| `gpu_temp` | GPU Temperature | Celsius |
| `memory` | Memory Usage | Percentage |
| `disk` | Disk Usage | Percentage |

### JavaScript Example

```javascript
const ws = new WebSocket('ws://localhost:9000/ws');

ws.onopen = () => {
  console.log('Connected to GX10 Dashboard');
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);

  if (message.type === 'metrics') {
    console.log('CPU:', message.data.cpu.usage, '%');
    console.log('GPU Temp:', message.data.gpu?.temperature, 'C');

    if (message.alerts.length > 0) {
      message.alerts.forEach(alert => {
        console.warn(`${alert.severity.toUpperCase()}: ${alert.message}`);
      });
    }
  }
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('Disconnected from GX10 Dashboard');
};
```

---

## Error Responses

All error responses follow a consistent format:

```json
{
  "error": "Error type description",
  "message": "Detailed error message"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| `200` | Success |
| `400` | Bad request (invalid parameters) |
| `404` | Not found |
| `500` | Internal server error |

---

## Environment Variables

The Dashboard server can be configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 9000 | Server port |
| `UPDATE_INTERVAL` | 2000 | WebSocket update interval (ms) |
| `ALERTS_ENABLED` | true | Enable/disable alerts |
| `OLLAMA_API_URL` | http://localhost:11434 | Ollama API URL |
| `CPU_WARNING` | 80 | CPU warning threshold |
| `CPU_CRITICAL` | 90 | CPU critical threshold |
| `GPU_TEMP_WARNING` | 75 | GPU temp warning threshold |
| `GPU_TEMP_CRITICAL` | 85 | GPU temp critical threshold |
| `MEMORY_WARNING` | 80 | Memory warning threshold |
| `MEMORY_CRITICAL` | 90 | Memory critical threshold |
| `DISK_WARNING` | 85 | Disk warning threshold |
| `DISK_CRITICAL` | 95 | Disk critical threshold |

---

## API Versioning

Current API version: **v1** (implicit)

The API does not currently use explicit versioning in the URL path. Future breaking changes may introduce `/api/v2/` endpoints while maintaining backward compatibility with `/api/` endpoints.

---

## Rate Limiting

No rate limiting is currently implemented. For production deployments exposed to untrusted networks, consider adding rate limiting middleware.

---

## CORS

CORS is enabled for all origins by default, allowing cross-origin requests from any domain. This is suitable for local development and internal network use.
