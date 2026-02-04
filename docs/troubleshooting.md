# GX10 Troubleshooting Guide

This guide provides solutions for common issues encountered during GX10 installation and operation.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Model Download Problems](#model-download-problems)
- [Brain Switching Failures](#brain-switching-failures)
- [Performance Issues](#performance-issues)
- [Dashboard Problems](#dashboard-problems)
- [Network and Access Issues](#network-and-access-issues)
- [GPU and CUDA Issues](#gpu-and-cuda-issues)
- [Docker Issues](#docker-issues)
- [Diagnostic Commands](#diagnostic-commands)

---

## Installation Issues

### Pre-flight Check Failures

#### Disk Space Insufficient

**Symptom**: Pre-flight check shows disk space below 500GB requirement.

**Diagnosis**:
```bash
df -h /gx10
df -h /
```

**Solutions**:
1. Free up disk space by removing unused files
2. Clean Docker cache: `docker system prune -a`
3. Remove old model versions: `ollama rm <old-model-name>`
4. Mount additional storage to `/gx10`

#### Memory Below Minimum

**Symptom**: Pre-flight check shows memory below 100GB requirement.

**Diagnosis**:
```bash
free -h
cat /proc/meminfo | grep MemTotal
```

**Solutions**:
1. Close unnecessary applications
2. Reduce swap usage: `sudo swapoff -a && sudo swapon -a`
3. Upgrade system RAM (hardware solution)

#### Phase 0 Not Completed

**Symptom**: `/gx10` directory structure not found.

**Diagnosis**:
```bash
ls -la /gx10/
ls -la /gx10/brains/
```

**Solutions**:
1. Run Phase 0 with sudo:
   ```bash
   cd scripts/install
   sudo ./00-sudo-prereqs.sh
   ```
2. Verify Ollama installation: `ollama --version`
3. Re-login or run `newgrp docker` after Phase 0

### Script Permission Errors

**Symptom**: Permission denied when running scripts.

**Solutions**:
```bash
# Make all scripts executable
chmod +x scripts/install/*.sh
chmod +x scripts/install/lib/*.sh

# Verify permissions
ls -la scripts/install/
```

### Library Source Errors

**Symptom**: `source: not found` or library loading failures.

**Diagnosis**:
```bash
ls -la scripts/install/lib/
cat scripts/install/lib/config.sh | head -20
```

**Solutions**:
1. Ensure you're running from the correct directory
2. Check for DOS line endings: `file scripts/install/lib/*.sh`
3. Convert if needed: `dos2unix scripts/install/lib/*.sh`

---

## Model Download Problems

### Download Timeout

**Symptom**: Model download hangs or times out.

**Diagnosis**:
```bash
# Check Ollama service
systemctl status ollama

# Check network
curl -s https://ollama.com/api/tags | head -5
```

**Solutions**:
1. Restart Ollama service:
   ```bash
   sudo systemctl restart ollama
   ```
2. Check internet connectivity
3. Try downloading manually:
   ```bash
   ollama pull qwen2.5-coder:7b
   ```
4. Check disk space for model storage

### Model Verification Failed

**Symptom**: Downloaded model fails integrity check.

**Diagnosis**:
```bash
ollama list
ollama show <model-name> --modelfile
```

**Solutions**:
1. Remove and re-download the model:
   ```bash
   ollama rm qwen2.5-coder:32b
   ollama pull qwen2.5-coder:32b
   ```
2. Check available disk space
3. Verify OLLAMA_MODELS environment variable

### Out of Disk Space During Download

**Symptom**: Download fails with disk space error.

**Diagnosis**:
```bash
df -h /gx10/brains/code/models/
du -sh /gx10/brains/code/models/*
```

**Solutions**:
1. Remove unused models
2. Clean Ollama cache:
   ```bash
   rm -rf ~/.ollama/tmp/*
   ```
3. Expand disk partition or mount additional storage

---

## Brain Switching Failures

### Switch Command Fails

**Symptom**: `switch.sh` command returns error.

**Diagnosis**:
```bash
# Check current brain state
cat /gx10/runtime/active_brain.json

# Check switch logs
tail -50 /gx10/runtime/logs/brain-switch.log
```

**Solutions**:
1. Run with sudo:
   ```bash
   sudo /gx10/api/switch.sh code
   ```
2. Check Ollama service:
   ```bash
   sudo systemctl restart ollama
   ```
3. Stop conflicting containers:
   ```bash
   docker stop gx10-vision-brain
   ```

### Vision Brain Container Won't Start

**Symptom**: Vision brain switch fails, container won't start.

**Diagnosis**:
```bash
docker ps -a | grep vision
docker logs gx10-vision-brain --tail 50
```

**Solutions**:
1. Check GPU availability:
   ```bash
   nvidia-smi
   docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi
   ```
2. Rebuild Vision Brain image:
   ```bash
   cd scripts/install
   ./02-vision-brain-build.sh
   ```
3. Check Docker GPU runtime:
   ```bash
   docker info | grep -i runtime
   ```

### Switch Takes Too Long

**Symptom**: Brain switch exceeds 30-second timeout.

**Diagnosis**:
```bash
# Monitor during switch
watch -n 1 'docker ps; nvidia-smi'
```

**Solutions**:
1. Wait for GPU memory to clear (especially after heavy model usage)
2. Manually stop services before switching:
   ```bash
   docker stop gx10-vision-brain
   sudo systemctl stop ollama
   # Wait 10 seconds
   sudo /gx10/api/switch.sh code
   ```
3. Increase timeout in config (if frequently needed)

---

## Performance Issues

### Slow Model Response

**Symptom**: Model takes too long to respond or low tokens/sec.

**Diagnosis**:
```bash
# Check GPU utilization
nvidia-smi -l 1

# Check model loading
curl -s http://localhost:11434/api/ps | jq .
```

**Solutions**:
1. Ensure model is loaded in GPU:
   ```bash
   ollama run qwen2.5-coder:32b "test" --verbose
   ```
2. Check for GPU memory pressure:
   ```bash
   nvidia-smi --query-gpu=memory.used,memory.total --format=csv
   ```
3. Use smaller model for faster responses:
   ```bash
   # Use 7b instead of 32b for quick tasks
   ollama run qwen2.5-coder:7b "Hello"
   ```
4. Adjust Ollama settings in `/etc/systemd/system/ollama.service`:
   ```ini
   Environment="OLLAMA_NUM_GPU=1"
   Environment="OLLAMA_GPU_OVERHEAD=0"
   ```

### GPU Not Being Used

**Symptom**: Model runs on CPU instead of GPU.

**Diagnosis**:
```bash
# Check GPU memory usage during inference
nvidia-smi -l 1
# Should show memory usage increase when running model
```

**Solutions**:
1. Verify NVIDIA drivers:
   ```bash
   nvidia-smi
   ```
2. Check Ollama GPU settings:
   ```bash
   cat /etc/systemd/system/ollama.service | grep GPU
   ```
3. Restart Ollama:
   ```bash
   sudo systemctl restart ollama
   ```
4. Force GPU layers:
   ```bash
   OLLAMA_NUM_GPU=999 ollama run qwen2.5-coder:32b "test"
   ```

### High GPU Temperature

**Symptom**: GPU temperature exceeds 75C warning threshold.

**Diagnosis**:
```bash
nvidia-smi --query-gpu=temperature.gpu --format=csv -l 1
```

**Solutions**:
1. Improve case cooling
2. Lower power limit:
   ```bash
   sudo nvidia-smi -pl 300  # Reduce from default
   ```
3. Increase fan speed (if supported)
4. Reduce concurrent model loading

---

## Dashboard Problems

### Dashboard Service Not Starting

**Symptom**: Dashboard service fails to start.

**Diagnosis**:
```bash
systemctl status gx10-dashboard
journalctl -u gx10-dashboard -n 50
```

**Solutions**:
1. Check Node.js installation:
   ```bash
   node --version  # Should be v18+
   npm --version
   ```
2. Reinstall dependencies:
   ```bash
   cd ~/workspace/gx10-dashboard
   rm -rf node_modules
   npm install
   ```
3. Check port availability:
   ```bash
   lsof -i :9000
   ```
4. Restart service:
   ```bash
   sudo systemctl restart gx10-dashboard
   ```

### Dashboard Not Showing Data

**Symptom**: Dashboard loads but shows no metrics.

**Diagnosis**:
```bash
# Test API endpoints
curl -s http://localhost:9000/api/health | jq .
curl -s http://localhost:9000/api/status | jq .
curl -s http://localhost:9000/api/brain | jq .
```

**Solutions**:
1. Check brain status file:
   ```bash
   cat /gx10/runtime/active_brain.json
   ```
2. Verify file permissions:
   ```bash
   ls -la /gx10/runtime/
   ```
3. Check WebSocket connection in browser developer tools
4. Restart dashboard service

### Dashboard External Access Blocked

**Symptom**: Cannot access dashboard from other machines.

**Diagnosis**:
```bash
# Check if listening on all interfaces
netstat -tlnp | grep 9000

# Check firewall
sudo ufw status
sudo iptables -L | grep 9000
```

**Solutions**:
1. Allow port in firewall:
   ```bash
   sudo ufw allow 9000/tcp
   ```
2. Check if bound to 0.0.0.0 (not just localhost)
3. Verify no proxy or VPN blocking

---

## Network and Access Issues

### Open WebUI Not Accessible

**Symptom**: Cannot connect to Open WebUI on port 8080.

**Diagnosis**:
```bash
docker ps | grep webui
docker logs open-webui --tail 20
curl -s http://localhost:8080 | head -5
```

**Solutions**:
1. Restart container:
   ```bash
   docker restart open-webui
   ```
2. Check port mapping:
   ```bash
   docker port open-webui
   ```
3. Recreate container:
   ```bash
   ./04-webui-install.sh
   ```

### Ollama API Not Responding

**Symptom**: API calls to localhost:11434 fail.

**Diagnosis**:
```bash
systemctl status ollama
curl -s http://localhost:11434/api/version
ss -tlnp | grep 11434
```

**Solutions**:
1. Restart Ollama:
   ```bash
   sudo systemctl restart ollama
   ```
2. Check for port conflicts:
   ```bash
   lsof -i :11434
   ```
3. Check Ollama logs:
   ```bash
   journalctl -u ollama -n 100
   ```

### External Access Denied

**Symptom**: Cannot access GX10 services from network.

**Diagnosis**:
```bash
ip addr show
hostname -I
curl http://$(hostname -I | awk '{print $1}'):9000/api/health
```

**Solutions**:
1. Configure firewall:
   ```bash
   sudo ufw allow 9000/tcp   # Dashboard
   sudo ufw allow 8080/tcp   # WebUI
   sudo ufw allow 11434/tcp  # Ollama (if needed)
   ```
2. Check network interface bindings
3. Verify no IP-based access restrictions

---

## GPU and CUDA Issues

### nvidia-smi Not Found

**Symptom**: nvidia-smi command not found.

**Solutions**:
1. Install NVIDIA drivers:
   ```bash
   ubuntu-drivers devices
   sudo apt install nvidia-driver-535
   sudo reboot
   ```
2. Check driver installation:
   ```bash
   dpkg -l | grep nvidia
   ```

### CUDA Version Mismatch

**Symptom**: Container fails with CUDA errors.

**Diagnosis**:
```bash
nvidia-smi  # Shows driver CUDA version
docker run --rm --gpus all nvidia/cuda:12.1-base nvcc --version
```

**Solutions**:
1. Update NVIDIA Container Toolkit:
   ```bash
   sudo apt-get update
   sudo apt-get install -y nvidia-container-toolkit
   sudo systemctl restart docker
   ```
2. Rebuild Vision Brain with matching CUDA version

### GPU Memory Exhausted

**Symptom**: Out of memory errors during model loading.

**Diagnosis**:
```bash
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

**Solutions**:
1. Unload unused models:
   ```bash
   curl http://localhost:11434/api/generate -d '{"model":"qwen2.5-coder:32b","keep_alive":0}'
   ```
2. Use smaller model:
   ```bash
   ollama run qwen2.5-coder:7b
   ```
3. Reduce context length in Ollama settings
4. Switch brains to free GPU memory

---

## Docker Issues

### Docker Permission Denied

**Symptom**: Cannot access Docker without sudo.

**Solutions**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes (either method)
newgrp docker
# OR
# Log out and log back in
```

### Docker Daemon Not Running

**Symptom**: Docker commands fail with daemon error.

**Solutions**:
```bash
sudo systemctl start docker
sudo systemctl enable docker
systemctl status docker
```

### Container Build Fails

**Symptom**: Vision Brain Docker build fails.

**Diagnosis**:
```bash
docker build --no-cache . 2>&1 | tail -50
```

**Solutions**:
1. Clear Docker cache:
   ```bash
   docker system prune -a
   ```
2. Check Dockerfile syntax
3. Verify network connectivity for package downloads
4. Increase Docker build timeout

---

## Diagnostic Commands

### Quick Health Check

```bash
# All-in-one health check
echo "=== System ===" && free -h && df -h /gx10
echo "=== GPU ===" && nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total --format=csv
echo "=== Ollama ===" && curl -s http://localhost:11434/api/version | jq .
echo "=== Docker ===" && docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "=== Dashboard ===" && curl -s http://localhost:9000/api/health | jq .
```

### View All Logs

```bash
# Installation logs
ls -la /gx10/runtime/logs/

# View specific log
tail -100 /gx10/runtime/logs/05-final-validation.log

# Brain switch history
tail -50 /gx10/runtime/logs/brain-switch.log

# Dashboard logs
journalctl -u gx10-dashboard -n 50

# Ollama logs
journalctl -u ollama -n 50
```

### Status Commands

```bash
# Current brain status
cat /gx10/runtime/active_brain.json | jq .

# Installed models
ollama list

# Running containers
docker ps

# Service status
systemctl status ollama gx10-dashboard

# Network ports
ss -tlnp | grep -E "9000|8080|11434|8000"
```

### Performance Monitoring

```bash
# GPU monitoring
watch -n 1 nvidia-smi

# CPU and memory
htop

# Disk I/O
iotop

# Network connections
netstat -an | grep ESTABLISHED
```

---

## Getting Help

If you cannot resolve an issue using this guide:

1. **Check Logs**: Review `/gx10/runtime/logs/` for detailed error messages
2. **Run Validation**: Execute `./05-final-validation.sh` for comprehensive testing
3. **Document the Issue**: Capture output of diagnostic commands
4. **Report Issue**: File an issue on GitHub with diagnostic output

### Useful Information to Include

When reporting issues, include:
- Output of `nvidia-smi`
- Output of `docker ps -a`
- Contents of `/gx10/runtime/active_brain.json`
- Relevant log entries from `/gx10/runtime/logs/`
- System specs (GPU, RAM, disk space)
- Steps to reproduce the issue
