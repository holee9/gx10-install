# GX10 Monitoring Integration Guide

This guide explains how to integrate GX10 Dashboard with Prometheus and Grafana for comprehensive system monitoring.

## Overview

The GX10 Dashboard exposes system metrics in Prometheus OpenMetrics format at the `/metrics` endpoint. This allows you to:

- Collect historical metrics data with Prometheus
- Visualize metrics with Grafana dashboards
- Set up alerting rules for critical thresholds
- Monitor multiple GX10 systems from a central location

## Prerequisites

- GX10 Dashboard server running (default: `http://localhost:9000`)
- Docker and Docker Compose (recommended for Prometheus/Grafana)
- Or standalone Prometheus and Grafana installations

## Metrics Endpoint

The GX10 Dashboard exposes metrics at:

```
GET http://<gx10-host>:9000/metrics
```

### Available Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `gx10_cpu_usage_percent` | gauge | CPU usage percentage |
| `gx10_cpu_cores_total` | gauge | Total number of CPU cores |
| `gx10_cpu_temperature_celsius` | gauge | CPU temperature in Celsius |
| `gx10_memory_used_bytes` | gauge | Memory used in bytes |
| `gx10_memory_total_bytes` | gauge | Total memory in bytes |
| `gx10_memory_free_bytes` | gauge | Free memory in bytes |
| `gx10_memory_usage_percent` | gauge | Memory usage percentage |
| `gx10_disk_used_bytes` | gauge | Disk space used (labeled by mountpoint) |
| `gx10_disk_total_bytes` | gauge | Total disk space (labeled by mountpoint) |
| `gx10_disk_usage_percent` | gauge | Disk usage percentage (labeled by mountpoint) |
| `gx10_gpu_utilization_percent` | gauge | GPU utilization percentage |
| `gx10_gpu_memory_used_bytes` | gauge | GPU memory used in bytes |
| `gx10_gpu_memory_total_bytes` | gauge | GPU memory total in bytes |
| `gx10_gpu_temperature_celsius` | gauge | GPU temperature in Celsius |
| `gx10_gpu_power_watts` | gauge | GPU power draw in watts |
| `gx10_gpu_power_limit_watts` | gauge | GPU power limit in watts |
| `gx10_gpu_fan_speed_percent` | gauge | GPU fan speed percentage |
| `gx10_gpu_info` | gauge | GPU information labels (name, driver, cuda) |
| `gx10_brain_active` | gauge | Active brain (1=code, 2=vision) |
| `gx10_brain_mode` | gauge | Brain mode (labeled by mode) |
| `gx10_brain_uptime_seconds` | counter | Brain uptime in seconds |
| `gx10_ollama_up` | gauge | Ollama service status (1=running, 0=stopped) |
| `gx10_server_uptime_seconds` | counter | Dashboard server uptime |

## Prometheus Setup

### Option 1: Docker Compose (Recommended)

Create a `docker-compose.monitoring.yml` file:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: gx10-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/rules:/etc/prometheus/rules
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
      - '--storage.tsdb.retention.time=30d'
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"

  grafana:
    image: grafana/grafana:10.2.2
    container_name: gx10-grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

### Prometheus Configuration

Create `prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  # GX10 Dashboard metrics
  - job_name: 'gx10-dashboard'
    static_configs:
      - targets: ['host.docker.internal:9000']
    metrics_path: /metrics
    scrape_interval: 5s
    scrape_timeout: 5s

  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

For multiple GX10 systems:

```yaml
scrape_configs:
  - job_name: 'gx10-systems'
    static_configs:
      - targets:
          - 'gx10-workstation-1:9000'
          - 'gx10-workstation-2:9000'
          - 'gx10-server:9000'
        labels:
          environment: 'production'
```

### Option 2: Standalone Prometheus

Add to your existing `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'gx10-dashboard'
    static_configs:
      - targets: ['<gx10-ip>:9000']
    metrics_path: /metrics
    scrape_interval: 5s
```

Reload Prometheus configuration:

```bash
curl -X POST http://localhost:9090/-/reload
```

## Grafana Setup

### Data Source Configuration

1. Open Grafana (default: `http://localhost:3000`)
2. Navigate to **Configuration > Data Sources**
3. Click **Add data source**
4. Select **Prometheus**
5. Configure:
   - **URL**: `http://prometheus:9090` (Docker) or `http://localhost:9090` (standalone)
   - **Access**: Server (default)
6. Click **Save & Test**

### Dashboard Import

1. Navigate to **Dashboards > Import**
2. Click **Upload JSON file**
3. Select `grafana/gx10-dashboard.json` from this repository
4. Select your Prometheus data source
5. Click **Import**

### Auto-Provisioning (Docker)

Create `grafana/provisioning/datasources/datasources.yml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

Create `grafana/provisioning/dashboards/dashboards.yml`:

```yaml
apiVersion: 1

providers:
  - name: 'GX10 Dashboards'
    orgId: 1
    folder: 'GX10'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
```

Copy the dashboard file:

```bash
cp grafana/gx10-dashboard.json grafana/dashboards/
```

## Alert Rules

### Prometheus Alert Rules

Create `prometheus/rules/gx10-alerts.yml`:

```yaml
groups:
  - name: gx10-alerts
    rules:
      # High CPU Usage
      - alert: GX10HighCPUUsage
        expr: gx10_cpu_usage_percent > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on GX10"
          description: "CPU usage is {{ $value }}% (threshold: 90%)"

      # Critical CPU Usage
      - alert: GX10CriticalCPUUsage
        expr: gx10_cpu_usage_percent > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Critical CPU usage on GX10"
          description: "CPU usage is {{ $value }}% (threshold: 95%)"

      # High Memory Usage
      - alert: GX10HighMemoryUsage
        expr: gx10_memory_usage_percent > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on GX10"
          description: "Memory usage is {{ $value }}% (threshold: 85%)"

      # Critical Memory Usage
      - alert: GX10CriticalMemoryUsage
        expr: gx10_memory_usage_percent > 95
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Critical memory usage on GX10"
          description: "Memory usage is {{ $value }}% (threshold: 95%)"

      # High GPU Temperature
      - alert: GX10HighGPUTemperature
        expr: gx10_gpu_temperature_celsius > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High GPU temperature on GX10"
          description: "GPU temperature is {{ $value }}C (threshold: 80C)"

      # Critical GPU Temperature
      - alert: GX10CriticalGPUTemperature
        expr: gx10_gpu_temperature_celsius > 90
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Critical GPU temperature on GX10"
          description: "GPU temperature is {{ $value }}C (threshold: 90C)"

      # High GPU Utilization (might indicate runaway process)
      - alert: GX10HighGPUUtilization
        expr: gx10_gpu_utilization_percent > 95
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "Sustained high GPU utilization on GX10"
          description: "GPU utilization has been above 95% for 30 minutes"

      # Low Disk Space
      - alert: GX10LowDiskSpace
        expr: gx10_disk_usage_percent > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on GX10"
          description: "Disk {{ $labels.mountpoint }} is {{ $value }}% full"

      # Critical Disk Space
      - alert: GX10CriticalDiskSpace
        expr: gx10_disk_usage_percent > 95
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Critical disk space on GX10"
          description: "Disk {{ $labels.mountpoint }} is {{ $value }}% full"

      # Ollama Service Down
      - alert: GX10OllamaDown
        expr: gx10_ollama_up == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Ollama service is down on GX10"
          description: "Ollama has been down for more than 5 minutes"

      # Dashboard Server Down
      - alert: GX10DashboardDown
        expr: up{job="gx10-dashboard"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "GX10 Dashboard is unreachable"
          description: "Cannot scrape metrics from GX10 Dashboard"

      # High GPU Power Draw
      - alert: GX10HighGPUPower
        expr: gx10_gpu_power_watts > 400
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High GPU power draw on GX10"
          description: "GPU power draw is {{ $value }}W"
```

### Grafana Alerting

For Grafana-native alerting:

1. Navigate to **Alerting > Alert rules**
2. Click **New alert rule**
3. Configure:
   - **Name**: `GX10 High CPU Usage`
   - **Query**: `gx10_cpu_usage_percent`
   - **Condition**: Is above 90
   - **Evaluate every**: 1m
   - **For**: 5m
4. Add notification policy and contact points as needed

## Quick Start

1. Clone or download the monitoring configuration:

```bash
mkdir -p gx10-monitoring/{prometheus/rules,grafana/provisioning/datasources,grafana/provisioning/dashboards,grafana/dashboards}
```

2. Create the configuration files as shown above

3. Copy the GX10 dashboard:

```bash
cp /path/to/gx10-install/grafana/gx10-dashboard.json gx10-monitoring/grafana/dashboards/
```

4. Start the monitoring stack:

```bash
cd gx10-monitoring
docker-compose -f docker-compose.monitoring.yml up -d
```

5. Access the services:
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (admin/admin)

6. Import the GX10 dashboard in Grafana if not auto-provisioned

## Verification

### Check Prometheus Targets

1. Open Prometheus: http://localhost:9090
2. Navigate to **Status > Targets**
3. Verify `gx10-dashboard` target is **UP**

### Test Metrics Query

In Prometheus, run these queries:

```promql
# CPU usage
gx10_cpu_usage_percent

# Memory usage
gx10_memory_usage_percent

# GPU metrics
gx10_gpu_utilization_percent
gx10_gpu_temperature_celsius

# All GX10 metrics
{__name__=~"gx10_.*"}
```

### Verify Grafana Dashboard

1. Open Grafana: http://localhost:3000
2. Navigate to **Dashboards**
3. Open **GX10 System Monitor**
4. Verify all panels show data

## Troubleshooting

### Metrics Not Appearing

1. Check if GX10 Dashboard is running:
   ```bash
   curl http://localhost:9000/metrics
   ```

2. Check Prometheus target status:
   - Open http://localhost:9090/targets
   - Look for error messages

3. Verify network connectivity:
   ```bash
   # From Prometheus container
   docker exec gx10-prometheus wget -qO- http://host.docker.internal:9000/metrics
   ```

### Connection Refused

If using Docker, ensure proper host access:

```yaml
# In docker-compose.yml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Or use the host IP address directly in Prometheus config.

### GPU Metrics Missing

If GPU metrics are missing:

1. Verify NVIDIA drivers are installed:
   ```bash
   nvidia-smi
   ```

2. Check if GPU info is available in the metrics:
   ```bash
   curl http://localhost:9000/metrics | grep gpu
   ```

### Dashboard Shows "No Data"

1. Verify the data source is configured correctly
2. Check the time range (default: last 1 hour)
3. Ensure Prometheus is scraping data:
   ```promql
   count({job="gx10-dashboard"})
   ```

## Advanced Configuration

### Retention and Storage

Adjust Prometheus retention in docker-compose:

```yaml
command:
  - '--storage.tsdb.retention.time=90d'
  - '--storage.tsdb.retention.size=50GB'
```

### High Availability

For production environments, consider:

- Prometheus federation for multiple instances
- Thanos or Cortex for long-term storage
- Grafana Enterprise for advanced features

### Security

For exposed endpoints:

1. Use reverse proxy with authentication
2. Enable TLS/HTTPS
3. Configure firewall rules
4. Use Grafana authentication providers

## Related Documentation

- [GX10 Dashboard API Reference](./api-reference.md)
- [GX10 Troubleshooting Guide](./troubleshooting.md)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
