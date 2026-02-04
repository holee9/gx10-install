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
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null || true
source "$SCRIPT_DIR/lib/error-handler.sh" 2>/dev/null || true

# Initialize configuration
init_config

# Use centralized configuration
LOG_FILE="$GX10_LOGS_DIR/dashboard-install.log"

echo "=========================================="
echo "Phase 6: GX10 Dashboard Installation"
echo "=========================================="
echo ""

mkdir -p "$GX10_LOGS_DIR"

log_install() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ==========================================
# Step 1: Check/Install Node.js
# ==========================================
log_install "Step 1: Checking Node.js..."

install_nodejs() {
  log_install "Installing Node.js via NVM..."

  # Install NVM if not present
  if [ ! -d "$HOME/.nvm" ]; then
    log_install "Installing NVM..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
  fi

  # Load NVM
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install Node.js LTS
  nvm install "$NODE_VERSION_INSTALL"
  nvm use "$NODE_VERSION_INSTALL"
  nvm alias default "$NODE_VERSION_INSTALL"

  log_install "Node.js $(node -v) installed"
}

# Check if Node.js is available
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
  if [ "$NODE_VERSION" -ge "$NODE_VERSION_MIN" ]; then
    log_install "Node.js $(node -v) found - OK"
  else
    log_install "Node.js version too old, upgrading..."
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
log_install "Step 2: Setting up dashboard repository..."

mkdir -p "$(dirname "$DASHBOARD_DIR")"

if [ -d "$DASHBOARD_DIR" ]; then
  log_install "Dashboard directory exists, updating..."
  cd "$DASHBOARD_DIR"
  git fetch origin
  git reset --hard origin/main
else
  log_install "Cloning dashboard repository..."
  git clone "$DASHBOARD_REPO" "$DASHBOARD_DIR"
  cd "$DASHBOARD_DIR"
fi

log_install "Dashboard repository ready at $DASHBOARD_DIR"

# ==========================================
# Step 3: Install Dependencies
# ==========================================
log_install "Step 3: Installing dependencies..."

cd "$DASHBOARD_DIR"

# Root dependencies
npm install

# Server dependencies
cd "$DASHBOARD_DIR/server"
npm install

# Client dependencies
cd "$DASHBOARD_DIR/client"
npm install

log_install "Dependencies installed"

# ==========================================
# Step 4: Build Dashboard
# ==========================================
log_install "Step 4: Building dashboard..."

# Build client
cd "$DASHBOARD_DIR/client"
npm run build

# Build server
cd "$DASHBOARD_DIR/server"
npm run build

log_install "Dashboard built successfully"

# ==========================================
# Step 5: Create systemd service
# ==========================================
log_install "Step 5: Creating systemd service..."

SERVICE_FILE="/etc/systemd/system/${DASHBOARD_SERVICE_NAME}.service"

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
sudo systemctl enable "$DASHBOARD_SERVICE_NAME"

log_install "Systemd service created and enabled"

# ==========================================
# Step 6: Configure Firewall
# ==========================================
log_install "Step 6: Configuring firewall..."

# Open dashboard port
sudo iptables -I INPUT -p tcp --dport "$DASHBOARD_PORT" -j ACCEPT 2>/dev/null || true

log_install "Port $DASHBOARD_PORT opened"

# ==========================================
# Step 7: Start Dashboard
# ==========================================
log_install "Step 7: Starting dashboard service..."

sudo systemctl start "$DASHBOARD_SERVICE_NAME"

# Wait for service to start
sleep "$MEMORY_STABILIZATION_WAIT"

# Verify service is running
if curl -s "http://localhost:$DASHBOARD_PORT/api/health" > /dev/null 2>&1; then
  log_install "Dashboard service started successfully!"
else
  log_install "WARNING: Dashboard service may not have started properly"
  log_install "Check: sudo systemctl status $DASHBOARD_SERVICE_NAME"
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
echo "  Start:    sudo systemctl start $DASHBOARD_SERVICE_NAME"
echo "  Stop:     sudo systemctl stop $DASHBOARD_SERVICE_NAME"
echo "  Status:   sudo systemctl status $DASHBOARD_SERVICE_NAME"
echo "  Logs:     sudo journalctl -u $DASHBOARD_SERVICE_NAME -f"
echo ""
echo "Features:"
echo "  - Real-time CPU/Memory/GPU monitoring"
echo "  - Brain mode switching (Code/Vision)"
echo "  - Ollama model status"
echo "  - WebSocket live updates (${DASHBOARD_UPDATE_INTERVAL}ms interval)"
echo ""

log_install "Phase 6 completed"
