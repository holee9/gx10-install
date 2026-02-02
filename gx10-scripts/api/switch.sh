#!/bin/bash
# GX10 Brain Switch Script
# DGX OS 7.2.3 Compatible

set -e

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: switch.sh [code|vision|none]"
    echo ""
    echo "Options:"
    echo "  code   - Switch to Code Brain (Ollama)"
    echo "  vision - Switch to Vision Brain (Docker)"
    echo "  none   - Stop all brains"
    exit 1
fi

echo "=== Switching to $TARGET Brain ==="
echo ""

# Validate target
if [[ ! "$TARGET" =~ ^(code|vision|none)$ ]]; then
    echo "❌ Invalid target: $TARGET"
    echo "   Valid options: code, vision, none"
    exit 1
fi

# Check commands availability
DOCKER_AVAILABLE=false
OLLAMA_AVAILABLE=false

if command -v docker &> /dev/null; then
    DOCKER_AVAILABLE=true
else
    echo "⚠️  Warning: docker command not found"
fi

if command -v ollama &> /dev/null; then
    OLLAMA_AVAILABLE=true
else
    echo "⚠️  Warning: ollama command not found"
fi

# 1. Stop current brains
echo "[1/4] Stopping current brains..."

# Unload Ollama models
if [ "$OLLAMA_AVAILABLE" = true ]; then
    RUNNING_MODELS=$(ollama ps 2>/dev/null | tail -n +2 | awk '{print $1}')
    if [ -n "$RUNNING_MODELS" ]; then
        echo "$RUNNING_MODELS" | while read -r model; do
            [ -n "$model" ] && ollama stop "$model" 2>/dev/null || true
        done
    fi
fi

# Stop Vision Brain container
if [ "$DOCKER_AVAILABLE" = true ]; then
    docker stop vision-brain 2>/dev/null || true
    docker rm vision-brain 2>/dev/null || true
fi

# 2. Flush buffer cache (critical for UMA architecture)
echo "[2/4] Flushing buffer cache..."
if [ "$EUID" -eq 0 ]; then
    sync
    echo 3 > /proc/sys/vm/drop_caches
else
    sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches' || {
        echo "  ⚠️  Failed to flush cache (need sudo)"
    }
fi
sleep 3

# 3. Start target brain
echo "[3/4] Starting $TARGET brain..."

case $TARGET in
    code)
        # Check if ollama service exists
        if systemctl list-unit-files 2>/dev/null | grep -q "^ollama.service"; then
            sudo systemctl start ollama
            sleep 5

            # Verify Ollama is running
            if systemctl is-active --quiet ollama; then
                echo "  ✅ Ollama started successfully"

                # Warmup with small request (if curl available)
                if command -v curl &> /dev/null; then
                    curl -s http://localhost:11434/api/tags > /dev/null 2>&1 || true
                fi
            else
                echo "  ⚠️  Ollama started but may not be ready"
            fi
        else
            echo "  ⚠️  ollama.service not found"
            echo "  Install Ollama first: curl -fsSL https://ollama.com/install.sh | sh"
        fi
        ;;
    vision)
        VISION_SCRIPT="/gx10/brains/vision/run.sh"
        if [ -f "$VISION_SCRIPT" ]; then
            if [ -x "$VISION_SCRIPT" ]; then
                "$VISION_SCRIPT"
            else
                echo "  ⚠️  Making $VISION_SCRIPT executable..."
                chmod +x "$VISION_SCRIPT"
                "$VISION_SCRIPT"
            fi
        else
            echo "  ❌ $VISION_SCRIPT not found"
            echo "  Ensure Vision Brain scripts are installed"
        fi
        sleep 10
        ;;
    none)
        if systemctl list-unit-files 2>/dev/null | grep -q "^ollama.service"; then
            sudo systemctl stop ollama 2>/dev/null || echo "  Note: Ollama not running"
        fi
        echo "  ✅ All brains stopped"
        ;;
esac

# 4. Update state
echo "[4/4] Updating state..."
STATE_DIR="/gx10/runtime"
mkdir -p "$STATE_DIR"

# Use timestamp with fallback
TIMESTAMP=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")

cat > "$STATE_DIR/active_brain.json" << EOF
{
  "active_brain": "$TARGET",
  "started_at": "$TIMESTAMP",
  "last_task": null
}
EOF

echo ""
echo "=== Switch Complete ==="
echo ""

# Run status check
STATUS_SCRIPT="/gx10/api/status.sh"
if [ -f "$STATUS_SCRIPT" ]; then
    if [ -x "$STATUS_SCRIPT" ]; then
        "$STATUS_SCRIPT"
    else
        echo "Run manually: $STATUS_SCRIPT"
    fi
fi

exit 0
