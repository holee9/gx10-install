DGX OS 7.2.3 Installation Guide for ASUS Ascent GX10


Installation Guide
***Notice: DGX OS comes pre-installed on ASUS Ascent GX10***
***Notice: This guide covers the initial setup and configuration after first boot***

## First Boot Setup

1. **Power on GX10**
   - DGX OS will boot automatically
   - Wait for initial startup (may take 5-10 minutes)

2. **Wi-Fi Hotspot Connection**
   - GX10 creates a Wi-Fi hotspot on first boot
   - SSID: `DGX-Spark-XXXX` (check Quick Start Guide for exact SSID)
   - Password: Provided in Quick Start Guide

3. **Access DGX Dashboard**
   - Connect to the Wi-Fi hotspot
   - Open browser: `http://spark-xxxx.local`
   - Follow the setup wizard:
     - Set hostname (e.g., `gx10-brain`)
     - Create admin username/password
     - Configure network (DHCP or static IP)
     - Set timezone
   - System will update and reboot automatically

## Post-Installation Configuration

### DGX OS Overview

**What is DGX OS?**
- Custom Ubuntu 24.04 LTS distribution by NVIDIA
- Optimized for AI/ML workloads
- Pre-configured with NVIDIA drivers, CUDA, Docker
- Includes DGX Dashboard for system management

**Key Features:**
- **Kernel**: Linux 6.8.x (optimized for DGX hardware)
- **NVIDIA Drivers**: Pre-installed and configured
- **CUDA Toolkit**: Pre-installed (typically CUDA 12.x)
- **Docker**: Pre-installed with NVIDIA Container Toolkit
- **NVIDIA DGX Dashboard**: Web-based management interface

### System Verification

```bash
# Check DGX OS version
cat /etc/os-release
# Should show: Ubuntu 24.04 LTS with DGX branding

# Check kernel
uname -r
# Should show: 6.8.x-dgx

# Verify NVIDIA drivers
nvidia-smi
# Should show GB10 GPU information

# Check CUDA
nvcc --version
# Should show CUDA 12.x

# Check Docker
docker --version
# Should be pre-installed

# Check NVIDIA Container Toolkit
nvidia-ctk --version
# Should be pre-installed
```

### Python Environment

**Important: DGX OS implements PEP 668**

```bash
# Check Python version
python3 --version
# Python 3.12.x

# Python development tools
sudo apt install -y python3-pip python3-venv python3-dev

# Create virtual environment (recommended)
python3 -m venv ~/myenv
source ~/myenv/bin/activate
pip install <package>
```

**Note:** DGX OS maintains system Python integrity. Always use virtual environments.

### Pre-Installed Components

DGX OS includes:

| Component | Version | Status |
|-----------|---------|--------|
| NVIDIA Driver | Latest for DGX | ✅ Pre-installed |
| CUDA Toolkit | 12.x | ✅ Pre-installed |
| Docker | Latest | ✅ Pre-installed |
| NVIDIA Container Toolkit | Latest | ✅ Pre-installed |
| cuDNN | Latest | ✅ Pre-installed |
| NCCL | Latest | ✅ Pre-installed |

### System Updates

```bash
# Update DGX OS (use DGX Dashboard or CLI)
sudo apt update && sudo apt upgrade -y

# DGX OS may have custom repositories
# Check /etc/apt/sources.list.d/ for DGX-specific repos
```

### DGX Dashboard

**Access DGX Dashboard:**
- URL: `https://<gx10-ip>:6789` (or check documentation)
- Provides:
  - System metrics (GPU, memory, network)
  - Container management
  - User management
  - System updates
  - Logs and diagnostics

### Network Configuration

**Static IP (Recommended):**

```bash
# Via DGX Dashboard (recommended)
# Or manually:
sudo nmcli connection show
sudo nmcli connection modify "Wired connection 1" \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8 8.8.4.4" \
  ipv4.method manual
sudo nmcli connection up "Wired connection 1"
```

### SSH Access

```bash
# SSH is pre-installed and enabled
# Verify:
sudo systemctl status ssh

# If needed, enable:
sudo systemctl enable ssh
sudo systemctl start ssh
```

## Differences from Standard Ubuntu 24.04

**DGX OS vs Ubuntu 24.04:**

| Feature | DGX OS | Standard Ubuntu |
|---------|--------|-----------------|
| Base | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| Kernel | 6.8.x-dgx (optimized) | 6.8.x (generic) |
| NVIDIA Drivers | Pre-installed, custom | Manual install via repo |
| CUDA | Pre-installed | Manual install |
| Docker | Pre-installed + NCTK | Manual install |
| Repositories | Custom DGX repos | Standard Ubuntu repos |
| Management | DGX Dashboard | Manual/systemd |
| Support | NVIDIA Enterprise Support | Community |

### Important Notes

1. **Don't remove DGX repositories** - Maintains compatibility
2. **Use DGX Dashboard for updates** when possible
3. **DGX OS is optimized for AI workloads** - custom kernel tuning
4. **NVIDIA drivers are managed by DGX OS** - don't manually update
5. **Container support is pre-configured** - just use it

### Troubleshooting

**DGX Dashboard not accessible:**
```bash
# Check dashboard service
sudo systemctl status dgx-dashboard

# Restart if needed
sudo systemctl restart dgx-dashboard
```

**NVIDIA driver issues:**
```bash
# DGX OS manages drivers - check status
nvidia-smi

# If issues, use DGX support channels
# Don't manually reinstall drivers
```

**Docker GPU access:**
```bash
# Test NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu24.04 nvidia-smi

# Should work out of the box on DGX OS
```

---

## 📝 문서 정보

**작성자**:

- (작성자 정보 없음 - 공식 NVIDIA/ASUS DGX OS 설치 가이드)

**리뷰어**:

- drake

**수정자**:
- 수정일: 2026-02-01
- 수정 내용: 문서 형식 표준화 및 작성자 정보 보완 (omc-planner)

---

<!-- alfrad review:
  ✅ 작성자 정보에 "(공식 NVIDIA/ASUS DGX OS 설치 가이드)" 명시하여 출처 명확함
  ✅ 수정자 섹션 추가로 변경 추적 가능성 개선
  ✅ 문서 형식 표준화 유지
  💡 제안: 추후 원문 출처 URL이나 문서 번호 추가 권장
-->

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-02 | 1.1 | DGX OS 7.2.3 설명 보강 (Ubuntu 24.04 기반 커스텀 OS임 명확화) | drake |
| 2026-02-01 | 1.0 | DGX OS 기본 설치 가이드 작성 | drake |
