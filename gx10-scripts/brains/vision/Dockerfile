# GX10 Vision Brain Dockerfile
# Ubuntu 24.04 LTS Base Image
# Optimized for ARM64 + NVIDIA Blackwell GB10

FROM nvcr.io/nvidia/pytorch:24.01-py3

# Metadata
LABEL maintainer="GX10 Project"
LABEL description="Vision Brain with PyTorch, OpenCV, YOLO, SAM2"
LABEL ubuntu.version="24.04"

# Work directory
WORKDIR /workspace

# System packages
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libfontconfig1 \
    libice6 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip and install build tools (Ubuntu 24.04 compatible)
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Python packages - Core vision libraries
RUN pip install --no-cache-dir \
    opencv-python \
    opencv-contrib-python \
    numpy \
    scipy \
    scikit-image \
    scikit-learn \
    pillow \
    albumentations \
    imageio \
    imageio-ffmpeg

# Deep learning frameworks
RUN pip install --no-cache-dir \
    torch torchvision torchaudio \
    transformers \
    accelerate \
    datasets \
    timm \
    einops \
    safetensors

# Object detection
RUN pip install --no-cache-dir ultralytics

# Segmentation (SAM2)
RUN pip install --no-cache-dir git+https://github.com/facebookresearch/segment-anything-2.git

# Visualization
RUN pip install --no-cache-dir \
    matplotlib \
    seaborn \
    plotly

# Jupyter Lab
RUN pip install --no-cache-dir jupyterlab ipywidgets

# Expose Jupyter port
EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8888 || exit 1

# Default command
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", \
     "--allow-root", "--NotebookApp.token=''"]
