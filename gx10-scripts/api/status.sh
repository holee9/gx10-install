#!/bin/bash
# GX10 Brain Status Check Script
# DGX OS 7.2.3 Compatible

# Exit on error disabled for status checking
set +e

echo "=== GX10 Brain Status ==="
echo ""

# Memory status
echo "📊 Memory:"
free -h | grep -E "Mem|Swap" || echo "  Unable to check memory"
echo ""

# GPU status
echo "🎮 GPU:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null || nvidia-smi
else
    echo "  ⚠️ nvidia-smi not found"
fi
echo ""

# Ollama status (Code Brain)
echo "🧠 Code Brain (Ollama):"
if systemctl is-active --quiet ollama 2>/dev/null; then
    echo "  Status: ✅ Running"
    if command -v ollama &> /dev/null; then
        MODELS=$(ollama ps 2>/dev/null | tail -n +2)
        if [ -n "$MODELS" ]; then
            echo "$MODELS"
        else
            echo "  Models: None loaded"
        fi
    else
        echo "  ⚠️ ollama command not found"
    fi
else
    echo "  Status: ❌ Stopped"
fi
echo ""

# Vision Brain status
echo "👁️  Vision Brain (Docker):"
if command -v docker &> /dev/null; then
    CONTAINER_ID=$(docker ps -q -f name=vision-brain 2>/dev/null)
    if [ -n "$CONTAINER_ID" ]; then
        echo "  Status: ✅ Running"
        docker stats vision-brain --no-stream --format "  Memory: {{.MemUsage}}" 2>/dev/null || echo "  Container running"
    else
        echo "  Status: ❌ Stopped"
    fi
else
    echo "  ⚠️ docker command not found"
fi
echo ""

# Active brain status
echo "🎯 Active Brain:"
ACTIVE_BRAIN_FILE="/gx10/runtime/active_brain.json"
if [ -f "$ACTIVE_BRAIN_FILE" ]; then
    if command -v jq &> /dev/null; then
        ACTIVE_BRAIN=$(jq -r '.active_brain' "$ACTIVE_BRAIN_FILE" 2>/dev/null)
        echo "  $ACTIVE_BRAIN"
    else
        ACTIVE_BRAIN=$(grep -oP '"active_brain":\s*"\K[^"]+' "$ACTIVE_BRAIN_FILE" 2>/dev/null)
        echo "  ${ACTIVE_BRAIN:-unknown}"
    fi
else
    echo "  (no state file)"
fi
echo ""

# Disk usage
echo "💾 Disk:"
df -h / 2>/dev/null | tail -1 | awk '{print "  Used: "$3" / "$2" ("$5")"}' || echo "  Unable to check disk usage"
echo ""

# UMA Memory Health (DGX OS specific)
echo "🔍 UMA Memory Health:"
if [ -f /proc/meminfo ]; then
    BUFFERS=$(grep "^Buffers:" /proc/meminfo | awk '{print $2}')
    CACHED=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
    SLAB=$(grep "^Slab:" /proc/meminfo | awk '{print $2}')

    if [ -n "$BUFFERS" ] && [ -n "$CACHED" ] && [ -n "$SLAB" ]; then
        TOTAL_CACHE=$((BUFFERS + CACHED + SLAB))
        TOTAL_CACHE_GB=$((TOTAL_CACHE / 1024 / 1024))
        echo "  Buffer Cache: ${TOTAL_CACHE_GB} GB"
        echo "  (Run: sync; echo 3 | sudo tee /proc/sys/vm/drop_caches to flush)"
    else
        echo "  Unable to calculate buffer cache"
    fi
else
    echo "  Unable to access /proc/meminfo"
fi
echo ""

# Exit with success
exit 0
