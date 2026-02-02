#!/bin/bash
# Vision Brain Docker Container Runner
# DGX OS 7.2.3 Compatible

set -e

# Configuration
IMAGE_NAME="gx10-vision-brain:latest"
CONTAINER_NAME="vision-brain"
MODELS_DIR="/gx10/brains/vision/models"
BENCHMARKS_DIR="/gx10/brains/vision/benchmarks"
HF_CACHE_DIR="/root/.cache/huggingface"

echo "=== Vision Brain Startup ==="
echo ""

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found"
    echo "   Docker is pre-installed on DGX OS"
    echo "   Check: docker --version"
    exit 1
fi

# Create directories if they don't exist
echo "Creating directories..."
mkdir -p "$MODELS_DIR" "$BENCHMARKS_DIR"
mkdir -p "$HOME/.cache/huggingface"

# Check if image exists
echo "Checking Docker image..."
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "⚠️  Docker image $IMAGE_NAME not found"
    echo "   Building from Dockerfile..."

    DOCKERFILE="/gx10/brains/vision/Dockerfile"
    if [ ! -f "$DOCKERFILE" ]; then
        echo "❌ Dockerfile not found at $DOCKERFILE"
        exit 1
    fi

    cd /gx10/brains/vision

    # Build with progress output
    if docker build -t "$IMAGE_NAME" .; then
        echo "✅ Build completed"
    else
        echo "❌ Build failed"
        cd -
        exit 1
    fi

    cd -
fi

# Remove existing container if running
echo "Checking for existing container..."
CONTAINER_EXISTS=$(docker ps -a -q -f name="$CONTAINER_NAME" 2>/dev/null)
if [ -n "$CONTAINER_EXISTS" ]; then
    echo "Removing existing container..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
fi

# Check GPU availability
echo "Checking GPU availability..."
if ! docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu24.04 nvidia-smi &>/dev/null; then
    echo "⚠️  GPU access test failed"
    echo "   NVIDIA Container Toolkit may not be properly configured"
    echo "   On DGX OS this should work out of the box"
fi

# Run Vision Brain container
echo "Starting Vision Brain container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    --gpus all \
    --shm-size=16g \
    --network=bridge \
    -p 8888:8888 \
    -v "$MODELS_DIR:/workspace/models:rw" \
    -v "$BENCHMARKS_DIR:/workspace/benchmarks:rw" \
    -v "$HOME/.cache/huggingface:$HF_CACHE_DIR:rw" \
    -e JUPYTER_ENABLE_LAB=yes \
    "$IMAGE_NAME" 2>/dev/null || {
    echo "❌ Failed to start container"
    exit 1
}

# Wait for container to be ready
echo "Waiting for Jupyter Lab to start..."
sleep 5

# Verify container is running
RUNNING=$(docker ps -q -f name="$CONTAINER_NAME" 2>/dev/null)
if [ -n "$RUNNING" ]; then
    echo "✅ Vision Brain started successfully"
    echo ""
    echo "Access Jupyter Lab at: http://localhost:8888"
    echo ""
    echo "Useful commands:"
    echo "  View logs:    docker logs -f $CONTAINER_NAME"
    echo "  Stop:         docker stop $CONTAINER_NAME"
    echo "  Restart:      docker restart $CONTAINER_NAME"
    echo "  Shell access: docker exec -it $CONTAINER_NAME bash"
    echo ""
else
    echo "❌ Failed to start Vision Brain"
    echo ""
    echo "Check logs:"
    docker logs "$CONTAINER_NAME" 2>/dev/null || echo "  No logs available"
    exit 1
fi

exit 0
