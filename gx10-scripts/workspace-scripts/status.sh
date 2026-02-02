#!/bin/bash
# GX10 System Status Script
# DGX OS 7.2.3 Compatible

set -euo pipefail

echo "=========================================="
echo "    GX10 System Status                    "
echo "=========================================="
echo ""

# GPU Status
echo "📊 GPU Status:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null || \
    nvidia-smi -L 2>/dev/null || \
    echo "  ⚠️  Unable to query GPU"
else
    echo "  ⚠️  nvidia-smi not found"
fi
echo ""

# Memory
echo "💾 Memory:"
if command -v free &> /dev/null; then
    free -h | grep -E "Mem|Swap" || echo "  Unable to fetch memory info"
else
    echo "  free command not found"
fi
echo ""

# Docker Containers
echo "🐳 Docker Containers:"
if command -v docker &> /dev/null; then
    CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)
    if [ -n "$CONTAINERS" ]; then
        echo "$CONTAINERS"
    else
        echo "  No running containers"
    fi
else
    echo "  ⚠️  Docker not running or not installed"
fi
echo ""

# System Services
echo "⚙️  Services:"

# Ollama
if systemctl list-unit-files | grep -q ollama.service 2>/dev/null; then
    if systemctl is-active --quiet ollama 2>/dev/null; then
        echo "  ✅ Ollama: Running"
    else
        echo "  ❌ Ollama: Stopped"
    fi
else
    echo "  ℹ️  Ollama: Not installed"
fi

# Jupyter
if systemctl list-unit-files | grep -q jupyter.service 2>/dev/null; then
    if systemctl is-active --quiet jupyter 2>/dev/null; then
        echo "  ✅ Jupyter: Running"
    else
        echo "  ❌ Jupyter: Stopped"
    fi
else
    echo "  ℹ️  Jupyter: Not installed"
fi

# Open WebUI
if command -v docker &> /dev/null; then
    if docker ps -q -f name=open-webui 2>/dev/null | grep -q .; then
        echo "  ✅ Open WebUI: Running"
    else
        echo "  ❌ Open WebUI: Stopped"
    fi
fi

echo ""

# Ollama Models
echo "🤖 Ollama Models:"
if command -v ollama &> /dev/null; then
    if command -v curl &> /dev/null && curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        ollama list 2>/dev/null || echo "  Cannot connect to Ollama API"
    else
        echo "  ⚠️  Ollama API not responding"
    fi
else
    echo "  ⚠️  ollama command not found"
fi
echo ""

# Storage
echo "💿 Storage:"
if command -v df &> /dev/null; then
    df -h / 2>/dev/null | tail -1 | awk '{print "  Used: "$3" / "$2" ("$5")"}' || \
    echo "  Unable to fetch disk info"
else
    echo "  df command not found"
fi
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
        echo "  Buffer Cache: ${TOTAL_CACHE_GB}GB"
        echo "  (To flush: sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches')"
    else
        echo "  Unable to calculate cache"
    fi
else
    echo "  /proc/meminfo not found"
fi
echo ""

# DGX Dashboard
echo "🎛️  DGX Dashboard:"
IP_ADDRESS=$(hostname -I | awk '{print $1}' 2>/dev/null)
if [ -n "$IP_ADDRESS" ]; then
    echo "  URL: https://${IP_ADDRESS}:6789"
else
    echo "  URL: https://<gx10-ip>:6789"
fi
echo ""
