#!/bin/bash
# GX10 System Startup Script
# DGX OS 7.2.3 Compatible

set -e

echo "=========================================="
echo "    GX10 System Starting...          "
echo "=========================================="
echo ""

# State directory
STATE_DIR="/gx10/runtime"
mkdir -p "$STATE_DIR/logs"

# Check if running as root or with sudo
SUDO=""
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "⚠️  Warning: sudo not available, some operations may fail"
    fi
fi

# 1. Start Ollama (Code Brain)
echo "[1/3] Starting Ollama..."
if systemctl list-unit-files 2>/dev/null | grep -q "^ollama.service"; then
    $SUDO systemctl start ollama
    sleep 5

    # Check Ollama status
    if systemctl is-active --quiet ollama; then
        echo "  ✅ Ollama started"

        # Verify API is responding
        if command -v curl &> /dev/null; then
            if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
                echo "  ✅ Ollama API responding"
            else
                echo "  ⚠️  Ollama running but API not responding yet"
            fi
        fi
    else
        echo "  ⚠️  Ollama failed to start"
        echo "  Check: systemctl status ollama"
    fi
else
    echo "  ℹ️  ollama.service not found"
    echo "  Install: curl -fsSL https://ollama.com/install.sh | sh"
fi

# 2. Start n8n (optional, if configured)
echo "[2/3] Starting n8n (optional)..."
if command -v docker &> /dev/null; then
    # Check if n8n container exists
    if docker ps -a -q -f name=n8n 2>/dev/null | grep -q .; then
        docker start n8n 2>/dev/null && echo "  ✅ n8n started" || echo "  ⚠️  n8n failed to start"
    else
        echo "  ℹ️  n8n not configured (skipped)"
    fi

    # Show status
    if docker ps -q -f name=n8n 2>/dev/null | grep -q .; then
        echo "  ✅ n8n running at http://localhost:5678"
    fi
else
    echo "  ℹ️  Docker not available, skipping n8n"
fi

# 3. Initialize state
echo "[3/3] Initializing state..."
mkdir -p "$STATE_DIR"

# Use timestamp with fallback
TIMESTAMP=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")

cat > "$STATE_DIR/active_brain.json" << EOF
{
  "active_brain": "code",
  "started_at": "$TIMESTAMP",
  "last_task": null
}
EOF

echo ""
echo "=========================================="
echo "    System Ready                        "
echo "=========================================="
echo ""
echo "Core Services:"
echo "  Ollama API  : http://localhost:11434"
echo ""
echo "Optional Services (if configured):"
echo "  Open WebUI  : http://localhost:8080"
echo "  n8n         : http://localhost:5678"
echo "  DGX Dashboard: https://$(hostname -I | awk '{print $1}'):6789"
echo ""
echo "Management Commands:"
echo "  /gx10/api/status.sh  - Check detailed system status"
echo "  /gx10/api/switch.sh  - Switch between Code/Vision brain"
echo ""
echo "Logs: $STATE_DIR/logs/"
echo ""

exit 0
