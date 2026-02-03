#!/bin/bash
#############################################
# Phase 6: GX10 Dashboard Installation
# Installs the web-based monitoring dashboard
#
# Features:
#   - Real-time system monitoring (CPU, Memory, GPU)
#   - Brain mode switching (Code/Vision)
#   - Ollama model status
#   - WebSocket live updates
#
# Requirements:
#   - Node.js 20 LTS (installed via NVM)
#   - Git
#   - Port 9000 available
#
# Author: omc-developer
# Created: 2026-02-03
#############################################

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null || true
source "$SCRIPT_DIR/lib/error-handler.sh" 2>/dev/null || true

# Configuration
DASHBOARD_REPO="https://github.com/holee9/gx10-dashboard.git"
DASHBOARD_DIR="$HOME/workspace/gx10-dashboard"
DASHBOARD_PORT=9000
LOG_FILE="/gx10/runtime/logs/dashboard-install.log"

echo "=========================================="
echo "Phase 6: GX10 Dashboard Installation"
echo "=========================================="
echo ""

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ==========================================
# Step 1: Check/Install Node.js
# ==========================================
log "Step 1: Checking Node.js..."

install_nodejs() {
  log "Installing Node.js via NVM..."

  # Install NVM if not present
  if [ ! -d "$HOME/.nvm" ]; then
    log "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi

  # Load NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install Node.js 20 LTS
  nvm install 20
  nvm use 20
  nvm alias default 20

  log "Node.js $(node -v) installed"
}

# Check if Node.js is available
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
  if [ "$NODE_VERSION" -ge 18 ]; then
    log "Node.js $(node -v) found - OK"
  else
    log "Node.js version too old, upgrading..."
    install_nodejs
  fi
else
  install_nodejs
fi

# Ensure NVM is loaded for this session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ==========================================
# Step 2: Clone/Update Dashboard Repository
# ==========================================
log "Step 2: Setting up dashboard repository..."

mkdir -p "$HOME/workspace"

if [ -d "$DASHBOARD_DIR" ]; then
  log "Dashboard directory exists, updating..."
  cd "$DASHBOARD_DIR"
  git fetch origin
  git reset --hard origin/main
else
  log "Cloning dashboard repository..."
  git clone "$DASHBOARD_REPO" "$DASHBOARD_DIR"
  cd "$DASHBOARD_DIR"
fi

log "Dashboard repository ready at $DASHBOARD_DIR"

# ==========================================
# Step 3: Install Dependencies
# ==========================================
log "Step 3: Installing dependencies..."

cd "$DASHBOARD_DIR"

# Root dependencies
npm install

# Server dependencies
cd "$DASHBOARD_DIR/server"
npm install

# Client dependencies
cd "$DASHBOARD_DIR/client"
npm install

log "Dependencies installed"

# ==========================================
# Step 4: Build Dashboard
# ==========================================
log "Step 4: Building dashboard..."

# Build client
cd "$DASHBOARD_DIR/client"
npm run build

# Build server
cd "$DASHBOARD_DIR/server"
npm run build

log "Dashboard built successfully"

# ==========================================
# Step 5: Create systemd service
# ==========================================
log "Step 5: Creating systemd service..."

SERVICE_FILE="/etc/systemd/system/gx10-dashboard.service"

# Create service file (requires sudo from Phase 0 sudoers)
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=GX10 System Monitoring Dashboard
After=network.target ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$DASHBOARD_DIR/server
ExecStart=$(which node) $DASHBOARD_DIR/server/dist/index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=$DASHBOARD_PORT

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable gx10-dashboard

log "Systemd service created and enabled"

# ==========================================
# Step 6: Configure Firewall
# ==========================================
log "Step 6: Configuring firewall..."

# Open port 9000
sudo iptables -I INPUT -p tcp --dport $DASHBOARD_PORT -j ACCEPT 2>/dev/null || true

log "Port $DASHBOARD_PORT opened"

# ==========================================
# Step 7: Start Dashboard
# ==========================================
log "Step 7: Starting dashboard service..."

sudo systemctl start gx10-dashboard

# Wait for service to start
sleep 3

# Verify service is running
if curl -s http://localhost:$DASHBOARD_PORT/api/health > /dev/null 2>&1; then
  log "Dashboard service started successfully!"
else
  log "WARNING: Dashboard service may not have started properly"
  log "Check: sudo systemctl status gx10-dashboard"
fi

# ==========================================
# Summary
# ==========================================
echo ""
echo "=========================================="
echo "Phase 6: Dashboard Installation Complete!"
echo "=========================================="
echo ""
echo "Dashboard URLs:"
echo "  Local:    http://localhost:$DASHBOARD_PORT"
echo "  Network:  http://$(hostname -I | awk '{print $1}'):$DASHBOARD_PORT"
echo ""
echo "Service Management:"
echo "  Start:    sudo systemctl start gx10-dashboard"
echo "  Stop:     sudo systemctl stop gx10-dashboard"
echo "  Status:   sudo systemctl status gx10-dashboard"
echo "  Logs:     sudo journalctl -u gx10-dashboard -f"
echo ""
echo "Features:"
echo "  - Real-time CPU/Memory/GPU monitoring"
echo "  - Brain mode switching (Code/Vision)"
echo "  - Ollama model status"
echo "  - WebSocket live updates (2s interval)"
echo ""

log "Phase 6 completed"
