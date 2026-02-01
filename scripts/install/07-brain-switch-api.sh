#!/bin/bash
#############################################
# GX10 Auto Installation Script - Phase 7
# Brain Switch API
#############################################

set -e
set -u

LOG_FILE="/gx10/runtime/logs/07-brain-switch-api.log"
mkdir -p /gx10/runtime/logs

echo "=========================================="
echo "GX10 Phase 7: Brain Switch API"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Creating Brain Switch API..."

# Create initial active_brain.json
log "Creating active_brain.json..."
cat > /gx10/runtime/active_brain.json << EOF
{
  "brain": "code",
  "pid": null,
  "since": null,
  "last_switch": null
}
EOF

# Create status.sh
log "Creating status.sh script..."
cat > /gx10/api/status.sh << 'EOF'
#!/bin/bash
# GX10 Brain Status Script

STATUS_FILE="/gx10/runtime/active_brain.json"

if [ ! -f "$STATUS_FILE" ]; then
  echo '{"error": "Brain status file not found"}'
  exit 1
fi

cat "$STATUS_FILE" | jq '.'
EOF
chmod +x /gx10/api/status.sh

# Create switch.sh
log "Creating switch.sh script..."
cat > /gx10/api/switch.sh << 'EOF'
#!/bin/bash
# GX10 Brain Switch Script

set -e

STATUS_FILE="/gx10/runtime/active_brain.json"
TARGET_BRAIN=$1

if [ -z "$TARGET_BRAIN" ]; then
  echo "Usage: switch.sh [code|vision]"
  exit 1
fi

CURRENT=$(cat "$STATUS_FILE" | jq -r '.brain')

if [ "$TARGET_BRAIN" == "$CURRENT" ]; then
  echo "Already on $TARGET_BRAIN brain"
  exit 0
fi

case $TARGET_BRAIN in
  code)
    echo "Switching to Code Brain..."
    # Stop Vision Brain
    docker stop gx10-vision-brain 2>/dev/null || true
    docker rm gx10-vision-brain 2>/dev/null || true
    # Start Code Brain
    sudo systemctl start ollama
    ;;
  vision)
    echo "Switching to Vision Brain..."
    # Stop Code Brain
    sudo systemctl stop ollama
    # Start Vision Brain
    docker run -d \
      --name gx10-vision-brain \
      --gpus all \
      --restart unless-stopped \
      -v /gx10/brains/vision/models:/workspace/models \
      gx10-vision-brain:latest \
      tail -f /dev/null
    ;;
  *)
    echo "Invalid brain: $TARGET_BRAIN"
    echo "Usage: switch.sh [code|vision]"
    exit 1
    ;;
esac

# Update state
PID=$(pgrep -f "$TARGET_BRAIN" | head -1 || echo "null")
TIMESTAMP=$(date -Iseconds)
cat > "$STATUS_FILE" << EOF
{
  "brain": "$TARGET_BRAIN",
  "pid": $PID,
  "since": "$TIMESTAMP",
  "last_switch": "$TIMESTAMP"
}
EOF

echo "Switched to $TARGET_BRAIN brain"
EOF
chmod +x /gx10/api/switch.sh

# Create wrapper with sudo
log "Creating sudo wrapper..."
sudo tee /usr/local/bin/gx10-brain-switch > /dev/null << 'EOF'
#!/bin/bash
/gx10/api/switch.sh "$@"
EOF
sudo chmod +x /usr/local/bin/gx10-brain-switch

# Verification
log "Verifying Brain Switch API..."
echo "" | tee -a "$LOG_FILE"
echo "=== Brain Status ===" | tee -a "$LOG_FILE"
/gx10/api/status.sh | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "=== Scripts Created ===" | tee -a "$LOG_FILE"
ls -la /gx10/api/*.sh | tee -a "$LOG_FILE"

log "Phase 7 completed successfully!"
echo "=========================================="
echo "Phase 7: COMPLETED"
echo "=========================================="
echo "Commands:"
echo "  Check status: /gx10/api/status.sh"
echo "  Switch brain: sudo /gx10/api/switch.sh [code|vision]"
