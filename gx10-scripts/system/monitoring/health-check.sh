#!/bin/bash
# GX10 Health Check Script
# DGX OS 7.2.3 Compatible
# Recommended cron: */5 * * * *

set -e

# Configuration
LOG_FILE="/gx10/runtime/logs/health.log"
LOG_DIR="/gx10/runtime/logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Get timestamp with fallback
TIMESTAMP=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%d %H:%M:%S")

# Initialize status variables
OLLAMA_STATUS="FAIL"
DOCKER_STATUS="FAIL"
MEM_USAGE="N/A"
GPU_USAGE="N/A"
ACTIVE_BRAIN="none"

# Check Ollama
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 3 http://localhost:11434/api/version > /dev/null 2>&1; then
        OLLAMA_STATUS="OK"
    fi
elif systemctl is-active --quiet ollama 2>/dev/null; then
    OLLAMA_STATUS="OK"
fi

# Check Docker
if command -v docker &> /dev/null; then
    if docker ps > /dev/null 2>&1; then
        DOCKER_STATUS="OK"
    fi
fi

# Memory usage
if command -v free &> /dev/null; then
    MEM_USED=$(free -g | awk '/Mem:/{print $3}')
    MEM_TOTAL=$(free -g | awk '/Mem:/{print $2}')
    if [ -n "$MEM_USED" ] && [ -n "$MEM_TOTAL" ]; then
        MEM_USAGE="${MEM_USED}/${MEM_TOTAL}GB"
    fi
fi

# GPU usage (if available)
if command -v nvidia-smi &> /dev/null; then
    GPU_MEM=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [ -n "$GPU_MEM" ]; then
        GPU_USAGE="$GPU_MEM MiB"
    fi
fi

# Active brain
ACTIVE_BRAIN_FILE="/gx10/runtime/active_brain.json"
if [ -f "$ACTIVE_BRAIN_FILE" ]; then
    if command -v jq &> /dev/null; then
        ACTIVE_BRAIN=$(jq -r '.active_brain' "$ACTIVE_BRAIN_FILE" 2>/dev/null)
        ACTIVE_BRAIN=${ACTIVE_BRAIN:-"unknown"}
    else
        ACTIVE_BRAIN=$(grep -oP '"active_brain":\s*"\K[^"]+' "$ACTIVE_BRAIN_FILE" 2>/dev/null)
        ACTIVE_BRAIN=${ACTIVE_BRAIN:-"unknown"}
    fi
fi

# Log entry
LOG_ENTRY="$TIMESTAMP | Ollama: $OLLAMA_STATUS | Docker: $DOCKER_STATUS | Memory: $MEM_USAGE | GPU: $GPU_USAGE | Brain: $ACTIVE_BRAIN"

echo "$LOG_ENTRY" >> "$LOG_FILE"

# Print to stdout if running interactively (tty)
if [ -t 1 ]; then
    echo "$LOG_ENTRY"
fi

# Exit with appropriate code
# Only fail if Ollama is critically down AND Code Brain is active
if [ "$OLLAMA_STATUS" = "FAIL" ] && [ "$ACTIVE_BRAIN" = "code" ]; then
    exit 1
fi

exit 0
