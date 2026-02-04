#!/bin/bash
#############################################
# GX10 Configuration Library
# Centralizes all hardcoded values for GX10 installation
#
# Reference: DOC-LIB-005
# Author: MoAI
# Created: 2026-02-03
# Version: 1.0.0
# Status: RELEASED
#
# Usage:
#   source "$SCRIPT_DIR/lib/config.sh"
#   init_config
#
# All values can be overridden via environment variables
# or through a .env file at /gx10/config/.env
#############################################

# Load environment overrides from .env file if it exists
load_env_file() {
    local env_file="${GX10_ENV_FILE:-/gx10/config/.env}"
    if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
        # Use echo if log function not yet available
        if type log &>/dev/null; then
            log "INFO" "Loaded configuration from $env_file"
        fi
    fi
}

# =============================================
# SYSTEM PATHS
# =============================================
GX10_BASE_DIR="${GX10_BASE_DIR:-/gx10}"
GX10_BRAINS_DIR="${GX10_BRAINS_DIR:-$GX10_BASE_DIR/brains}"
GX10_RUNTIME_DIR="${GX10_RUNTIME_DIR:-$GX10_BASE_DIR/runtime}"
GX10_CONFIG_DIR="${GX10_CONFIG_DIR:-$GX10_BASE_DIR/config}"
GX10_LOGS_DIR="${GX10_LOGS_DIR:-$GX10_RUNTIME_DIR/logs}"
GX10_STATE_DIR="${GX10_STATE_DIR:-$GX10_RUNTIME_DIR/state}"
GX10_API_DIR="${GX10_API_DIR:-$GX10_BASE_DIR/api}"

# =============================================
# OLLAMA CONFIGURATION
# =============================================
OLLAMA_HOST="${OLLAMA_HOST:-localhost}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OLLAMA_API_URL="${OLLAMA_API_URL:-http://$OLLAMA_HOST:$OLLAMA_PORT}"
OLLAMA_MODELS_DIR="${OLLAMA_MODELS_DIR:-$GX10_BRAINS_DIR/code/models}"
OLLAMA_NUM_CTX="${OLLAMA_NUM_CTX:-16384}"
OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-24h}"
OLLAMA_NUM_PARALLEL="${OLLAMA_NUM_PARALLEL:-2}"
OLLAMA_MAX_LOADED_MODELS="${OLLAMA_MAX_LOADED_MODELS:-2}"
OLLAMA_NUM_GPU="${OLLAMA_NUM_GPU:-1}"

# =============================================
# MODEL CONFIGURATION
# =============================================
CODE_MODEL_PRIMARY="${CODE_MODEL_PRIMARY:-qwen2.5-coder:32b}"
CODE_MODEL_SECONDARY="${CODE_MODEL_SECONDARY:-qwen2.5-coder:7b}"
CODE_MODEL_ALTERNATIVE="${CODE_MODEL_ALTERNATIVE:-deepseek-coder-v2:16b}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-nomic-embed-text}"

# Array of required models for validation
REQUIRED_MODELS=(
    "$CODE_MODEL_PRIMARY"
    "$CODE_MODEL_SECONDARY"
    "$CODE_MODEL_ALTERNATIVE"
    "$EMBEDDING_MODEL"
)

# =============================================
# VISION BRAIN CONFIGURATION
# =============================================
VISION_CONTAINER_NAME="${VISION_CONTAINER_NAME:-gx10-vision-brain}"
VISION_IMAGE_TAG="${VISION_IMAGE_TAG:-gx10-vision-brain:latest}"
VISION_PORT="${VISION_PORT:-8000}"
VISION_GPU_DEVICE="${VISION_GPU_DEVICE:-0}"
VISION_MEMORY_LIMIT="${VISION_MEMORY_LIMIT:-90g}"
VISION_MODELS_DIR="${VISION_MODELS_DIR:-$GX10_BRAINS_DIR/vision/models}"

# =============================================
# WEBUI CONFIGURATION
# =============================================
WEBUI_CONTAINER_NAME="${WEBUI_CONTAINER_NAME:-open-webui}"
WEBUI_PORT="${WEBUI_PORT:-8080}"
WEBUI_DATA_DIR="${WEBUI_DATA_DIR:-$GX10_BRAINS_DIR/code/webui}"
WEBUI_IMAGE="${WEBUI_IMAGE:-ghcr.io/open-webui/open-webui:main}"
WEBUI_PROTOCOL="${WEBUI_PROTOCOL:-http}"

# =============================================
# DASHBOARD CONFIGURATION
# =============================================
DASHBOARD_PORT="${DASHBOARD_PORT:-9000}"
DASHBOARD_WS_PATH="${DASHBOARD_WS_PATH:-/ws}"
DASHBOARD_UPDATE_INTERVAL="${DASHBOARD_UPDATE_INTERVAL:-2000}"
DASHBOARD_REPO="${DASHBOARD_REPO:-https://github.com/holee9/gx10-dashboard.git}"
DASHBOARD_DIR="${DASHBOARD_DIR:-$HOME/workspace/gx10-dashboard}"
DASHBOARD_SERVICE_NAME="${DASHBOARD_SERVICE_NAME:-gx10-dashboard}"

# =============================================
# API ENDPOINTS
# =============================================
BRAIN_STATUS_FILE="${BRAIN_STATUS_FILE:-$GX10_RUNTIME_DIR/active_brain.json}"
BRAIN_PATTERN_FILE="${BRAIN_PATTERN_FILE:-$GX10_RUNTIME_DIR/brain-usage-pattern.json}"
BRAIN_SWITCH_LOG="${BRAIN_SWITCH_LOG:-$GX10_LOGS_DIR/brain-switch.log}"

# =============================================
# TIMEOUTS AND LIMITS
# =============================================
HEALTH_CHECK_TIMEOUT="${HEALTH_CHECK_TIMEOUT:-30}"
SERVICE_START_TIMEOUT="${SERVICE_START_TIMEOUT:-60}"
MODEL_LOAD_TIMEOUT="${MODEL_LOAD_TIMEOUT:-300}"
DOCKER_BUILD_TIMEOUT="${DOCKER_BUILD_TIMEOUT:-600}"
BRAIN_SWITCH_TIMEOUT="${BRAIN_SWITCH_TIMEOUT:-30}"
CONTAINER_START_WAIT="${CONTAINER_START_WAIT:-10}"
MEMORY_STABILIZATION_WAIT="${MEMORY_STABILIZATION_WAIT:-3}"
OLLAMA_READY_TIMEOUT="${OLLAMA_READY_TIMEOUT:-30}"
MODEL_RESPONSE_TIMEOUT="${MODEL_RESPONSE_TIMEOUT:-60}"

# =============================================
# THRESHOLDS
# =============================================
MIN_DISK_SPACE_GB="${MIN_DISK_SPACE_GB:-500}"
MIN_MEMORY_GB="${MIN_MEMORY_GB:-100}"
GPU_TEMP_WARNING="${GPU_TEMP_WARNING:-75}"
GPU_TEMP_CRITICAL="${GPU_TEMP_CRITICAL:-85}"
TEST_COVERAGE_TARGET="${TEST_COVERAGE_TARGET:-85}"

# =============================================
# NODE.JS CONFIGURATION
# =============================================
NODE_VERSION_MIN="${NODE_VERSION_MIN:-18}"
NODE_VERSION_INSTALL="${NODE_VERSION_INSTALL:-20}"
NVM_VERSION="${NVM_VERSION:-0.40.1}"

# =============================================
# HELPER FUNCTIONS
# =============================================

# Get configuration value with default
# Args: $1=key, $2=default (optional)
# Returns: Configuration value or default
get_config() {
    local key="$1"
    local default="${2:-}"
    eval "echo \${$key:-$default}"
}

# Set runtime configuration (non-persistent)
# Args: $1=key, $2=value
set_config() {
    local key="$1"
    local value="$2"
    export "$key=$value"
}

# Save configuration to file
# Creates a gx10.conf file with current configuration
save_config_to_file() {
    local config_file="${GX10_CONFIG_DIR}/gx10.conf"
    mkdir -p "$(dirname "$config_file")"

    cat > "$config_file" << EOF
# GX10 Configuration File
# Generated: $(date -Iseconds)
# Edit this file to customize your GX10 installation

# =============================================
# System Paths
# =============================================
GX10_BASE_DIR=$GX10_BASE_DIR
GX10_BRAINS_DIR=$GX10_BRAINS_DIR
GX10_RUNTIME_DIR=$GX10_RUNTIME_DIR
GX10_CONFIG_DIR=$GX10_CONFIG_DIR
GX10_LOGS_DIR=$GX10_LOGS_DIR
GX10_API_DIR=$GX10_API_DIR

# =============================================
# Ollama Settings
# =============================================
OLLAMA_HOST=$OLLAMA_HOST
OLLAMA_PORT=$OLLAMA_PORT
OLLAMA_NUM_CTX=$OLLAMA_NUM_CTX
OLLAMA_KEEP_ALIVE=$OLLAMA_KEEP_ALIVE
OLLAMA_NUM_GPU=$OLLAMA_NUM_GPU

# =============================================
# Model Configuration
# =============================================
CODE_MODEL_PRIMARY=$CODE_MODEL_PRIMARY
CODE_MODEL_SECONDARY=$CODE_MODEL_SECONDARY
CODE_MODEL_ALTERNATIVE=$CODE_MODEL_ALTERNATIVE
EMBEDDING_MODEL=$EMBEDDING_MODEL

# =============================================
# Service Ports
# =============================================
DASHBOARD_PORT=$DASHBOARD_PORT
WEBUI_PORT=$WEBUI_PORT
VISION_PORT=$VISION_PORT

# =============================================
# Thresholds
# =============================================
GPU_TEMP_WARNING=$GPU_TEMP_WARNING
GPU_TEMP_CRITICAL=$GPU_TEMP_CRITICAL
MIN_DISK_SPACE_GB=$MIN_DISK_SPACE_GB
MIN_MEMORY_GB=$MIN_MEMORY_GB

# =============================================
# Timeouts (seconds)
# =============================================
HEALTH_CHECK_TIMEOUT=$HEALTH_CHECK_TIMEOUT
SERVICE_START_TIMEOUT=$SERVICE_START_TIMEOUT
BRAIN_SWITCH_TIMEOUT=$BRAIN_SWITCH_TIMEOUT
MODEL_RESPONSE_TIMEOUT=$MODEL_RESPONSE_TIMEOUT
EOF

    if type log &>/dev/null; then
        log "INFO" "Configuration saved to $config_file"
    fi
}

# Validate configuration values
# Returns: 0=success, >0=number of errors
validate_config() {
    local errors=0

    # Check ports are valid (1-65535)
    for port_var in OLLAMA_PORT VISION_PORT WEBUI_PORT DASHBOARD_PORT; do
        local port
        port=$(get_config "$port_var")
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 || "$port" -gt 65535 ]]; then
            if type log &>/dev/null; then
                log "ERROR" "Invalid port for $port_var: $port"
            else
                echo "ERROR: Invalid port for $port_var: $port" >&2
            fi
            ((errors++))
        fi
    done

    # Check timeouts are positive integers
    for timeout_var in HEALTH_CHECK_TIMEOUT SERVICE_START_TIMEOUT MODEL_LOAD_TIMEOUT BRAIN_SWITCH_TIMEOUT; do
        local timeout
        timeout=$(get_config "$timeout_var")
        if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [[ "$timeout" -lt 1 ]]; then
            if type log &>/dev/null; then
                log "ERROR" "Invalid timeout for $timeout_var: $timeout"
            else
                echo "ERROR: Invalid timeout for $timeout_var: $timeout" >&2
            fi
            ((errors++))
        fi
    done

    # Check memory thresholds are reasonable
    if [[ "$MIN_MEMORY_GB" -lt 32 ]]; then
        if type log &>/dev/null; then
            log "WARN" "MIN_MEMORY_GB ($MIN_MEMORY_GB) is below recommended minimum (32GB)"
        fi
    fi

    return $errors
}

# Print current configuration
# Outputs formatted configuration summary to stdout
print_config() {
    echo "=== GX10 Configuration ==="
    echo ""
    echo "Paths:"
    echo "  GX10_BASE_DIR: $GX10_BASE_DIR"
    echo "  GX10_BRAINS_DIR: $GX10_BRAINS_DIR"
    echo "  GX10_RUNTIME_DIR: $GX10_RUNTIME_DIR"
    echo "  GX10_LOGS_DIR: $GX10_LOGS_DIR"
    echo ""
    echo "Ollama:"
    echo "  OLLAMA_HOST: $OLLAMA_HOST"
    echo "  OLLAMA_PORT: $OLLAMA_PORT"
    echo "  OLLAMA_NUM_CTX: $OLLAMA_NUM_CTX"
    echo "  OLLAMA_NUM_GPU: $OLLAMA_NUM_GPU"
    echo ""
    echo "Models:"
    echo "  Primary: $CODE_MODEL_PRIMARY"
    echo "  Secondary: $CODE_MODEL_SECONDARY"
    echo "  Alternative: $CODE_MODEL_ALTERNATIVE"
    echo "  Embedding: $EMBEDDING_MODEL"
    echo ""
    echo "Services:"
    echo "  DASHBOARD_PORT: $DASHBOARD_PORT"
    echo "  WEBUI_PORT: $WEBUI_PORT"
    echo "  VISION_PORT: $VISION_PORT"
    echo ""
    echo "Thresholds:"
    echo "  GPU_TEMP_WARNING: ${GPU_TEMP_WARNING}C"
    echo "  GPU_TEMP_CRITICAL: ${GPU_TEMP_CRITICAL}C"
    echo "  MIN_MEMORY_GB: ${MIN_MEMORY_GB}GB"
    echo "  MIN_DISK_SPACE_GB: ${MIN_DISK_SPACE_GB}GB"
    echo ""
    echo "Timeouts:"
    echo "  HEALTH_CHECK_TIMEOUT: ${HEALTH_CHECK_TIMEOUT}s"
    echo "  BRAIN_SWITCH_TIMEOUT: ${BRAIN_SWITCH_TIMEOUT}s"
    echo "  MODEL_RESPONSE_TIMEOUT: ${MODEL_RESPONSE_TIMEOUT}s"
    echo "=========================="
}

# Get log file path for a phase
# Args: $1=phase_number, $2=phase_name
# Returns: Full path to log file
get_phase_log_file() {
    local phase_num="$1"
    local phase_name="$2"
    echo "${GX10_LOGS_DIR}/${phase_num}-${phase_name}.log"
}

# Ensure required directories exist
# Creates all GX10 directories if they don't exist
ensure_directories() {
    local dirs=(
        "$GX10_BASE_DIR"
        "$GX10_BRAINS_DIR"
        "$GX10_RUNTIME_DIR"
        "$GX10_CONFIG_DIR"
        "$GX10_LOGS_DIR"
        "$GX10_STATE_DIR"
        "$GX10_API_DIR"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
        fi
    done
}

# Initialize configuration
# Loads env file, validates config, and ensures directories
# Returns: 0=success, 1=failure
init_config() {
    load_env_file

    if ! validate_config; then
        if type log &>/dev/null; then
            log "ERROR" "Configuration validation failed"
        else
            echo "ERROR: Configuration validation failed" >&2
        fi
        return 1
    fi

    return 0
}

# Export all configuration variables and functions
export GX10_BASE_DIR GX10_BRAINS_DIR GX10_RUNTIME_DIR GX10_CONFIG_DIR GX10_LOGS_DIR GX10_STATE_DIR GX10_API_DIR
export OLLAMA_HOST OLLAMA_PORT OLLAMA_API_URL OLLAMA_MODELS_DIR OLLAMA_NUM_CTX OLLAMA_KEEP_ALIVE OLLAMA_NUM_PARALLEL OLLAMA_MAX_LOADED_MODELS OLLAMA_NUM_GPU
export CODE_MODEL_PRIMARY CODE_MODEL_SECONDARY CODE_MODEL_ALTERNATIVE EMBEDDING_MODEL
export VISION_CONTAINER_NAME VISION_IMAGE_TAG VISION_PORT VISION_GPU_DEVICE VISION_MEMORY_LIMIT VISION_MODELS_DIR
export WEBUI_CONTAINER_NAME WEBUI_PORT WEBUI_DATA_DIR WEBUI_IMAGE WEBUI_PROTOCOL
export DASHBOARD_PORT DASHBOARD_WS_PATH DASHBOARD_UPDATE_INTERVAL DASHBOARD_REPO DASHBOARD_DIR DASHBOARD_SERVICE_NAME
export BRAIN_STATUS_FILE BRAIN_PATTERN_FILE BRAIN_SWITCH_LOG
export HEALTH_CHECK_TIMEOUT SERVICE_START_TIMEOUT MODEL_LOAD_TIMEOUT DOCKER_BUILD_TIMEOUT BRAIN_SWITCH_TIMEOUT CONTAINER_START_WAIT MEMORY_STABILIZATION_WAIT OLLAMA_READY_TIMEOUT MODEL_RESPONSE_TIMEOUT
export MIN_DISK_SPACE_GB MIN_MEMORY_GB GPU_TEMP_WARNING GPU_TEMP_CRITICAL TEST_COVERAGE_TARGET
export NODE_VERSION_MIN NODE_VERSION_INSTALL NVM_VERSION

export -f get_config set_config save_config_to_file validate_config print_config get_phase_log_file ensure_directories init_config load_env_file
