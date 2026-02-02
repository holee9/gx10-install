#!/bin/bash
# GX10 Coding Environment Activation Script
# Ubuntu 24.04 LTS Compatible

set -e

echo "🚀 Coding Agent Environment"
echo ""

# Check Ollama
if command -v curl &> /dev/null; then
    if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
        echo "✅ Ollama: Connected"

        if command -v ollama &> /dev/null; then
            MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
            echo "   Models: $MODEL_COUNT available"
        fi
    else
        echo "⚠️  Ollama: Not responding"
        echo ""
        read -p "Start Ollama? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if systemctl list-unit-files | grep -q ollama.service; then
                sudo systemctl start ollama
                sleep 3
            else
                echo "  ⚠️  ollama.service not found"
            fi
        fi
    fi
else
    echo "⚠️  curl not available"
fi

echo ""
echo "Available commands:"
echo "  aider              - CLI pair programming (if installed)"
echo "  code .             - VS Code with Cline/Continue (if installed)"
echo "  ollama run <model> - Direct model interaction"
echo ""
echo "Recommended models:"
echo "  ollama run qwen2.5-coder:32b  - Main coding model"
echo "  ollama run qwen2.5-coder:7b   - Fast responses"
echo ""

# Check if aider is installed
if command -v aider &> /dev/null; then
    echo "✅ Aider: Available"
else
    echo "ℹ️  Aider: Not installed (pipx install aider-chat)"
fi

# Check if VS Code is installed
if command -v code &> /dev/null; then
    echo "✅ VS Code: Available"
else
    echo "ℹ️  VS Code: Not installed"
fi
