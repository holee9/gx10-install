# KB-009: GB10 GPU CUDA Compatibility Issue

## Error Summary
- **Date**: 2026-02-03
- **Phase**: Phase 2 (Vision Brain Build)
- **Severity**: Critical
- **Status**: Resolved

## Error Message
```
NVIDIA GB10 with CUDA capability sm_121 is not compatible with the current PyTorch installation.
The current PyTorch install supports CUDA capabilities sm_52 sm_60 sm_61 sm_70 sm_72 sm_75 sm_80 sm_86 sm_87 sm_90 compute_90.
```

## Root Cause
- GX10 hardware uses **NVIDIA GB10 GPU** with **Blackwell architecture (sm_121)**
- Original Dockerfile used `nvcr.io/nvidia/pytorch:24.01-py3` which only supports up to sm_90
- GB10 (sm_121) is a newer architecture released after the 24.01 container

## Hardware Context
- **Platform**: ASUS Ascent GX10 / DGX Spark
- **GPU**: NVIDIA GB10 (48GB VRAM)
- **CUDA Capability**: sm_121 (Blackwell)
- **Architecture**: ARM64 + CUDA

## Solution Applied
Changed base image in `02-vision-brain-build.sh`:
- Before: `nvcr.io/nvidia/pytorch:24.01-py3`
- After: `nvcr.io/nvidia/pytorch:25.12-py3`

Also removed redundant PyTorch reinstall line (NGC 25.12 already includes compatible PyTorch).

## Prevention Rules
1. **Always check GPU architecture compatibility** before selecting NGC container versions
2. **For GB10/Blackwell GPUs**, use NGC containers version 25.11 or later
3. **Document hardware requirements** in PRD with specific CUDA capability version

## References
- [PyTorch NGC Container](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch)
- [PyTorch Release Notes 25.12](https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/rel-25-12.html)
- [DGX Spark GB10 Forum Discussion](https://discuss.pytorch.org/t/dgx-spark-gb10-cuda-13-0-python-3-12-sm-121/223744)

## Related KBs
- KB-005: Script execute permission
- KB-006: security.sh syntax error
- KB-007: error-handler phase parsing
- KB-008: lib runtime errors under set -u
