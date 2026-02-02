#!/bin/bash
# GX10 Vision Environment Activation Script
# Ubuntu 24.04 LTS Compatible

set -e

VISION_ENV="$HOME/workspace/vision/vision-env"

echo "👁️  Vision AI Environment"
echo ""

# Check if vision venv exists
if [ -d "$VISION_ENV" ]; then
    source "$VISION_ENV/bin/activate"
    echo "✅ Python environment activated: $VISION_ENV"
else
    echo "⚠️  Vision environment not found at: $VISION_ENV"
    echo ""
    echo "Creating new environment..."
    mkdir -p "$HOME/workspace/vision"
    python3 -m venv "$VISION_ENV"
    source "$VISION_ENV/bin/activate"

    echo "Installing PyTorch (ARM64)..."
    pip install --upgrade pip
    pip install torch torchvision torchaudio

    echo ""
    echo "Environment created. Install additional packages:"
    echo "  pip install opencv-python ultralytics transformers"
fi

echo ""
echo "Checking PyTorch installation..."
python3 << 'EOF'
import sys
try:
    import torch
    print(f"✅ PyTorch: {torch.__version__}")
    print(f"   CUDA: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"   GPU: {torch.cuda.get_device_name(0)}")
except ImportError:
    print("⚠️  PyTorch not installed")
    print("   Run: pip install torch torchvision torchaudio")
    sys.exit(1)
EOF

echo ""
echo "Available tools:"
echo "  jupyter lab - Notebook interface (if installed)"
echo "  python      - PyTorch/Vision environment"
echo "  yolo        - Object detection CLI (if ultralytics installed)"
echo ""
