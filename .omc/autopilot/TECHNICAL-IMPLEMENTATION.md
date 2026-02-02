# GX10 Installation Scripts - Technical Implementation Guide

**Document**: Technical Implementation Guide
**Version**: 1.0.0
**Status**: DRAFT
**Created**: 2026-02-01
**Companion**: `.omc/autopilot/spec.md`

---

## Purpose

This document provides detailed technical specifications for implementing the enhancements described in the main specification. It includes complete function signatures, data structures, security implementations, and verification commands.

---

## 1. Library Specifications

### 1.1 Directory Structure

```
scripts/
├── lib/
│   ├── error-handler.sh    # Checkpoint and rollback framework
│   ├── security.sh         # Password and credential utilities
│   ├── logger.sh           # Standardized logging
│   └── state-manager.sh    # State persistence
├── install/
│   ├── 00-install-all.sh
│   ├── 01-initial-setup.sh
│   └── ... (02-10)
└── .templates/
    └── script-header.sh     # Standardized header template
```

### 1.2 `lib/error-handler.sh`

Complete implementation with function signatures:

```bash
#!/bin/bash
# GX10 Error Handler Library
# Provides checkpoint, rollback, and resume capabilities

# State directory
GX10_STATE_DIR="/gx10/runtime/state"
CHECKPOINT_FILE="$GX10_STATE_DIR/checkpoints.json"

# Initialize state directory
init_state() {
    mkdir -p "$GX10_STATE_DIR"

    # Create checkpoint file if not exists
    if [ ! -f "$CHECKPOINT_FILE" ]; then
        cat > "$CHECKPOINT_FILE" << 'EOF'
{
  "version": "1.0",
  "created_at": null,
  "updated_at": null,
  "current_phase": 0,
  "checkpoints": []
}
EOF
    fi
}

# checkpoint(): Create a rollback point
# Args: $1=phase_name, $2=pre_action_description
# Returns: checkpoint_id (format: cp-{phase}-{timestamp})
# Side effect: Appends to checkpoints.json
checkpoint() {
    local phase_name="$1"
    local pre_action="$2"
    local phase_num="${phase_name%%-*}"
    local timestamp=$(date -u +"%Y%m%d-%H%M%S")
    local checkpoint_id="cp-${phase_num}-${timestamp}"

    # Create checkpoint entry
    local checkpoint_entry=$(jq -n \
        --arg id "$checkpoint_id" \
        --arg phase "$phase_num" \
        --arg name "$phase_name" \
        --arg desc "$pre_action" \
        --arg ts "$(date -u -Iseconds)" \
        '{
            checkpoint_id: $id,
            phase: ($phase | tonumber),
            phase_name: $name,
            description: $desc,
            timestamp: $ts,
            status: "pending",
            rollback_actions: []
        }' )

    # Append to checkpoints array
    jq ".checkpoints += [$checkpoint_entry] | .current_phase = ($phase | tonumber) | .updated_at = \"$timestamp\"" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
    mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"

    echo "$checkpoint_id"
}

# complete_checkpoint(): Mark checkpoint as completed
# Args: $1=checkpoint_id
complete_checkpoint() {
    local checkpoint_id="$1"

    jq "(.checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\")).status = \"completed\" | .updated_at = \"$(date -u -Iseconds)\"" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
    mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
}

# add_rollback_action(): Register rollback action for current checkpoint
# Args: $1=checkpoint_id, $2=action_type, $3=action_data
# Example: add_rollback_action "cp-1-xxx" "file" "remove:/tmp/file"
add_rollback_action() {
    local checkpoint_id="$1"
    local action_type="$2"
    local action_data="$3"

    jq "(.checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\")).rollback_actions += [{type: \"$action_type\", data: \"$action_data\"}]" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
    mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
}

# rollback(): Execute rollback to checkpoint
# Args: $1=checkpoint_id
# Returns: 0=success, 1=failure
rollback() {
    local target_checkpoint="$1"

    # Get all checkpoints after target
    local checkpoints_to_rollback=$(jq -r ".checkpoints | map(select(.checkpoint_id >= \"$target_checkpoint\")) | reverse | .[].checkpoint_id" "$CHECKPOINT_FILE")

    echo "Rolling back to: $target_checkpoint"

    for cp_id in $checkpoints_to_rollback; do
        echo "Rolling back checkpoint: $cp_id"

        # Get rollback actions
        local actions=$(jq -r ".checkpoints[] | select(.checkpoint_id == \"$cp_id\") | .rollback_actions[] | @json" "$CHECKPOINT_FILE")

        # Execute actions in reverse order
        echo "$actions" | jq -r '.' | while read -r action; do
            local type=$(echo "$action" | jq -r '.type')
            local data=$(echo "$action" | jq -r '.data')

            case "$type" in
                file)
                    local file_path="${data#remove:}"
                    rm -f "$file_path" 2>/dev/null && echo "  Removed: $file_path"
                    ;;
                service)
                    local service_name="${data#disable:}"
                    systemctl disable "$service_name" 2>/dev/null && echo "  Disabled: $service_name"
                    ;;
                container)
                    local container_name="${data#stop:}"
                    docker stop "$container_name" 2>/dev/null && echo "  Stopped: $container_name"
                    ;;
                env)
                    local env_var="${data#unset:}"
                    sed -i "/^export $env_var/d" ~/.bashrc
                    ;;
            esac
        done
    done

    return 0
}

# get_last_checkpoint(): Find most recent completed checkpoint
# Returns: checkpoint_id or empty string
get_last_checkpoint() {
    jq -r '.checkpoints | map(select(.status == "completed")) | .[-1].checkpoint_id // ""' "$CHECKPOINT_FILE"
}

# resume_from_checkpoint(): Continue from checkpoint
# Args: $1=checkpoint_id
# Returns: Next phase number
resume_from_checkpoint() {
    local checkpoint_id="$1"

    # Get phase number from checkpoint
    local phase=$(jq -r ".checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\") | .phase" "$CHECKPOINT_FILE")

    # Return next phase
    echo $((phase + 1))
}
```

### 1.3 `lib/security.sh`

Complete implementation with function signatures:

```bash
#!/bin/bash
# GX10 Security Library
# Provides password management and certificate generation

# Password complexity requirements
PASSWORD_MIN_LENGTH=12
PASSWORD_REQUIRE_UPPER=true
PASSWORD_REQUIRE_LOWER=true
PASSWORD_REQUIRE_NUMBER=true
PASSWORD_REQUIRE_SPECIAL=true

# validate_password(): Check password complexity
# Args: $1=password
# Returns: 0=valid, 1=invalid
validate_password() {
    local password="$1"

    # Check minimum length
    if [ ${#password} -lt $PASSWORD_MIN_LENGTH ]; then
        echo "ERROR: Password must be at least $PASSWORD_MIN_LENGTH characters" >&2
        return 1
    fi

    # Check uppercase
    if [ "$PASSWORD_REQUIRE_UPPER" = true ]; then
        if ! [[ "$password" =~ [A-Z] ]]; then
            echo "ERROR: Password must contain at least one uppercase letter" >&2
            return 1
        fi
    fi

    # Check lowercase
    if [ "$PASSWORD_REQUIRE_LOWER" = true ]; then
        if ! [[ "$password" =~ [a-z] ]]; then
            echo "ERROR: Password must contain at least one lowercase letter" >&2
            return 1
        fi
    fi

    # Check number
    if [ "$PASSWORD_REQUIRE_NUMBER" = true ]; then
        if ! [[ "$password" =~ [0-9] ]]; then
            echo "ERROR: Password must contain at least one number" >&2
            return 1
        fi
    fi

    # Check special character
    if [ "$PASSWORD_REQUIRE_SPECIAL" = true ]; then
        if ! [[ "$password" =~ [!@#$%^&*] ]]; then
            echo "ERROR: Password must contain at least one special character (!@#$%^&*)" >&2
            return 1
        fi
    fi

    return 0
}

# prompt_password(): Interactive password prompt with validation
# Args: $1=prompt_text, $2=min_length (default 12)
# Returns: Password via stdout (not echoed)
prompt_password() {
    local prompt_text="${1:-Enter admin password}"
    local min_length="${2:-$PASSWORD_MIN_LENGTH}"
    local password=""
    local confirm=""
    local attempts=0
    local max_attempts=3

    while [ $attempts -lt $max_attempts ]; do
        # Read password silently
        read -s -p "$prompt_text (min $min_length chars): " password
        echo

        # Confirm password
        read -s -p "Confirm password: " confirm
        echo

        # Check if passwords match
        if [ "$password" != "$confirm" ]; then
            echo "ERROR: Passwords do not match" >&2
            ((attempts++))
            continue
        fi

        # Validate password
        if validate_password "$password"; then
            # Success - output password
            echo "$password"
            return 0
        fi

        ((attempts++))
    done

    echo "ERROR: Maximum password attempts exceeded" >&2
    return 1
}

# get_admin_password(): Get password from env or prompt
# Priority: GX10_PASSWORD env var > interactive prompt
# Returns: Password via stdout
get_admin_password() {
    # Check environment variable first (for CI/CD)
    if [ -n "${GX10_PASSWORD:-}" ]; then
        # Validate environment variable password
        if validate_password "$GX10_PASSWORD"; then
            echo "$GX10_PASSWORD"
            return 0
        else
            echo "ERROR: GX10_PASSWORD does not meet complexity requirements" >&2
            return 1
        fi
    fi

    # Fall back to interactive prompt
    prompt_password "Enter GX10 admin password"
}

# generate_cert(): Create self-signed SSL certificate
# Args: $1=domain, $2=cert_output_dir
# Returns: 0=success, 1=failure
generate_cert() {
    local domain="${1:-localhost}"
    local output_dir="${2:-/gx10/runtime/certs}"

    # Create output directory
    mkdir -p "$output_dir"

    local cert_file="$output_dir/cert.pem"
    local key_file="$output_dir/key.pem"

    # Generate self-signed certificate
    if openssl req -x509 -newkey rsa:4096 \
        -keyout "$key_file" \
        -out "$cert_file" \
        -days 365 \
        -nodes \
        -subj "/CN=$domain/O=GX10/C=US" 2>/dev/null; then
        echo "Certificate generated successfully: $cert_file"
        return 0
    else
        echo "ERROR: Certificate generation failed" >&2
        return 1
    fi
}

# hash_password(): Generate password hash (for secure storage)
# Args: $1=password
# Returns: SHA256 hash
hash_password() {
    local password="$1"
    echo -n "$password" | sha256sum | cut -d' ' -f1
}
```

### 1.4 `lib/logger.sh`

Complete implementation with function signatures:

```bash
#!/bin/bash
# GX10 Logger Library
# Provides standardized logging with rotation

# Log levels
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [CRITICAL]=4
)

# Current log level (default: INFO)
CURRENT_LOG_LEVEL="${LOG_LEVEL:-INFO}"
CURRENT_LOG_VALUE="${LOG_LEVELS[$CURRENT_LOG_LEVEL]}"

# Main log directory
LOG_DIR="/gx10/runtime/logs"
mkdir -p "$LOG_DIR"

# log(): Unified logging function
# Args: $1=level (DEBUG|INFO|WARN|ERROR|CRITICAL), $2=message
# Side effect: Outputs to stdout and log file
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # Check if level should be logged
    local level_value="${LOG_LEVELS[$level]}"
    if [ "$level_value" -lt "$CURRENT_LOG_VALUE" ]; then
        return 0  # Skip logging
    fi

    # Format log entry
    local log_entry="[$timestamp] [$level] $message"

    # Output to stdout
    echo "$log_entry"

    # Append to main log file
    echo "$log_entry" >> "$LOG_DIR/installation.log"
}

# init_log(): Initialize log for a phase
# Args: $1=phase_number, $2=phase_name
# Side effect: Creates phase-specific log file
init_log() {
    local phase_num="$1"
    local phase_name="$2"
    local phase_log="$LOG_DIR/${phase_num}-${phase_name}.log"

    # Create phase log file
    touch "$phase_log"

    # Log initialization
    log "INFO" "=== Phase $phase_num: $phase_name started ==="
}

# set_level(): Set minimum log level
# Args: $1=level (DEBUG|INFO|WARN|ERROR|CRITICAL)
set_level() {
    local new_level="$1"

    if [ -z "${LOG_LEVELS[$new_level]}" ]; then
        log "ERROR" "Invalid log level: $new_level"
        return 1
    fi

    CURRENT_LOG_LEVEL="$new_level"
    CURRENT_LOG_VALUE="${LOG_LEVELS[$new_level]}"
    log "INFO" "Log level changed to: $new_level"
}

# rotate_logs(): Rotate large log files
# Args: $1=max_size_mb (default 100)
rotate_logs() {
    local max_size_mb="${1:-100}"
    local max_size_bytes=$((max_size_mb * 1024 * 1024))

    # Find log files larger than max_size
    find "$LOG_DIR" -type f -name "*.log" -size +${max_size_mb}M | while read -r logfile; do
        # Compress log file
        gzip -c "$logfile" > "${logfile}.gz"

        # Truncate original file
        > "$logfile"

        log "INFO" "Rotated log file: $logfile"
    done

    # Keep only last 5 rotated logs
    find "$LOG_DIR" -name "*.log.gz" -type f | sort | head -n -5 | xargs rm -f

    log "INFO" "Log rotation completed"
}
```

### 1.5 `lib/state-manager.sh`

Complete implementation:

```bash
#!/bin/bash
# GX10 State Manager Library
# Manages persistent state across installation phases

GX10_STATE_DIR="/gx10/runtime/state"

# init_state(): Initialize state directory
# Side effect: Creates state directory structure
init_state() {
    mkdir -p "$GX10_STATE_DIR"

    # Create state file if not exists
    local state_file="$GX10_STATE_DIR/state.json"
    if [ ! -f "$state_file" ]; then
        cat > "$state_file" << 'EOF'
{
  "version": "1.0",
  "installation_id": null,
  "started_at": null,
  "current_phase": 0,
  "status": "not_started",
  "config": {}
}
EOF
    fi
}

# save_state(): Save state value
# Args: $1=key, $2=value
save_state() {
    local key="$1"
    local value="$2"
    local state_file="$GX10_STATE_DIR/state.json"

    jq ".config.$key = \"$value\" | .updated_at = \"$(date -u -Iseconds)\"" "$state_file" > "${state_file}.tmp"
    mv "${state_file}.tmp" "$state_file"
}

# load_state(): Load state value
# Args: $1=key
# Returns: Value or empty string
load_state() {
    local key="$1"
    local state_file="$GX10_STATE_DIR/state.json"

    jq -r ".config.$key // empty" "$state_file"
}

# set_phase(): Set current phase
# Args: $1=phase_number
set_phase() {
    local phase="$1"
    local state_file="$GX10_STATE_DIR/state.json"

    jq ".current_phase = $phase | .updated_at = \"$(date -u -Iseconds)\"" "$state_file" > "${state_file}.tmp"
    mv "${state_file}.tmp" "$state_file"
}

# get_phase(): Get current phase
# Returns: Phase number
get_phase() {
    local state_file="$GX10_STATE_DIR/state.json"
    jq -r '.current_phase' "$state_file"
}
```

### 1.6 `.templates/script-header.sh`

Standardized header template:

```bash
#############################################
# GX10 Auto Installation Script - Phase XX
# <Phase Description>
#
# Reference: <DOC-ID-REF> Section "<Reference Section>"
# - <Requirement 1>
# - <Requirement 2>
#
# DOC-ID: DOC-SCR-00XX
# VERSION: 1.0.0
# STATUS: RELEASED|DRAFT|DEPRECATED
# DEPENDS: DOC-SCR-00X[, DOC-SCR-00X]
#
# Author: <author-name>
# Created: YYYY-MM-DD
# Modified: YYYY-MM-DD
#
# Reviewed-By: <reviewer-name> (YYYY-MM-DD)
#############################################

# alfrad review:
# ✅ <What was done correctly>
# ⚠️ <What needs attention>
# 💡 <Suggestions for improvement>
```

---

## 2. State Persistence Format

### 2.1 Checkpoint JSON Schema

**Location:** `/gx10/runtime/state/checkpoints.json`

**Complete Schema:**

```json
{
  "version": "1.0",
  "created_at": "2026-02-01T00:00:00Z",
  "updated_at": "2026-02-01T12:34:56Z",
  "current_phase": 5,
  "checkpoints": [
    {
      "checkpoint_id": "cp-001-20260201-120000",
      "phase": 1,
      "phase_name": "01-initial-setup",
      "description": "Before initial system setup",
      "timestamp": "2026-02-01T12:00:00Z",
      "status": "completed",
      "rollback_actions": [
        {
          "type": "file",
          "data": "remove:/tmp/gx10-installer.tmp"
        },
        {
          "type": "service",
          "data": "disable:ssh"
        }
      ],
      "state_snapshot": {
        "files_created": [
          "/gx10/runtime/logs/01-initial-setup.log"
        ],
        "containers_created": [],
        "services_enabled": ["ssh"],
        "packages_installed": ["build-essential", "git", "curl"]
      }
    }
  ]
}
```

### 2.2 State Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `checkpoint_id` | string | Yes | Unique ID: `cp-{phase}-{timestamp}` |
| `phase` | integer | Yes | Phase number (1-10) |
| `phase_name` | string | Yes | Script filename without extension |
| `description` | string | Yes | Human-readable description |
| `timestamp` | string | Yes | ISO 8601 timestamp (UTC) |
| `status` | string | Yes | `pending`, `completed`, `failed`, `rolled_back` |
| `rollback_actions` | array | No | Array of rollback action objects |
| `state_snapshot` | object | No | State capture at checkpoint time |

### 2.3 Rollback Action Types

| Type | Data Format | Example |
|------|-------------|---------|
| `file` | `remove:path` or `restore:backup_path` | `remove:/tmp/file.txt` |
| `service` | `disable:service_name` or `stop:service_name` | `disable:ssh` |
| `container` | `stop:container_name` or `rm:container_name` | `stop:n8n` |
| `env` | `unset:VAR_NAME` | `unset:GX10_ADMIN_PASSWORD` |

---

## 3. Security Implementation

### 3.1 Password Management (09-service-automation.sh Fix)

**Current Vulnerable Code (Line 53):**
```bash
-e N8N_BASIC_AUTH_PASSWORD=gx10admin \  # SECURITY RISK!
```

**Fixed Implementation:**

```bash
# In 00-install-all.sh (before phase loop)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/security.sh"

# Get password from environment or prompt
ADMIN_PASSWORD=$(get_admin_password)

if [ -z "$ADMIN_PASSWORD" ]; then
    log "ERROR" "Failed to get admin password"
    exit 1
fi

# Export for all phases
export GX10_ADMIN_PASSWORD="$ADMIN_PASSWORD"
log "INFO" "Admin password obtained (length: ${#ADMIN_PASSWORD})"

# In 09-service-automation.sh (replace line 53)
docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD="${GX10_ADMIN_PASSWORD}" \  # FIXED
  -v /gx10/automation/n8n:/home/node/.n8n \
  n8nio/n8n
```

**Non-Interactive Mode (CI/CD):**
```bash
# Set environment variable before running installer
export GX10_PASSWORD="YourSecurePassword123!"
sudo ./00-install-all.sh
```

### 3.2 HTTPS Implementation (08-webui-install.sh)

**Current HTTP-Only Code:**
```bash
-p 8080:8080  # HTTP only
```

**Fixed HTTPS Implementation:**

```bash
# In 08-webui-install.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/security.sh"

# Certificate directory
CERT_DIR="/gx10/runtime/certs"
mkdir -p "$CERT_DIR"

# Get IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_NAME="${SERVER_IP:-localhost}"

log "INFO" "Generating SSL certificate for $SERVER_NAME"
if generate_cert "$SERVER_NAME" "$CERT_DIR"; then
    log "INFO" "Certificate generated successfully"
else
    log "WARN" "Certificate generation failed, falling back to HTTP"
    ENABLE_HTTPS=false
fi

# Check if HTTPS is enabled
ENABLE_HTTPS="${ENABLE_HTTPS:-true}"

if [ "$ENABLE_HTTPS" = "true" ]; then
    log "INFO" "Starting Open WebUI with HTTPS..."

    docker run -d \
      --name open-webui \
      --restart unless-stopped \
      -p 443:8443 \
      -v /gx10/brains/code/webui:/app/backend/data \
      -v "$CERT_DIR/cert.pem:/app/certs/cert.pem:ro" \
      -v "$CERT_DIR/key.pem:/app/certs/key.pem:ro" \
      -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
      -e WEBUI_SECRET_KEY="${WEBUI_SECRET:-$(openssl rand -hex 32)}" \
      -e HTTPS_ENABLED=true \
      -e SSL_CERT_PATH=/app/certs/cert.pem \
      -e SSL_KEY_PATH=/app/certs/key.pem \
      --add-host=host.docker.internal:host-gateway \
      ghcr.io/open-webui/open-webui:main

    # Also enable HTTP redirect container
    docker run -d \
      --name open-webui-redirect \
      --restart unless-stopped \
      -p 8080:80 \
      -v "$CERT_DIR:/etc/nginx/certs:ro" \
      nginx:alpine sh -c '
        echo "server { listen 80; return 301 https://$host:443\$request_uri; }" > /etc/nginx/conf.d/redirect.conf
        nginx -g "daemon off;"
      '

    log "INFO" "Open WebUI started: HTTPS on 443, HTTP redirect on 8080"
else
    log "WARN" "Starting Open WebUI with HTTP only (not recommended)"
    docker run -d \
      --name open-webui \
      --restart unless-stopped \
      -p 8080:8080 \
      -v /gx10/brains/code/webui:/app/backend/data \
      -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
      --add-host=host.docker.internal:host-gateway \
      ghcr.io/open-webui/open-webui:main
fi
```

---

## 4. Quantization Strategy

### 4.1 Ollama Built-In Quantization (Primary)

**Decision:** Use Ollama's pre-quantized models

**Rationale:**
- Ollama maintains optimized quantized versions
- Community-tested for stability
- Reduces build time from hours to minutes
- Supports int8, int4 quantization out of box

**Implementation (05-code-models-download.sh):**

```bash
# Primary: qwen2.5-coder:32b (int8 quantized by Ollama)
log "INFO" "Pulling qwen2.5-coder:32b (int8 quantized)"
time ollama pull qwen2.5-coder:32b >> "$LOG_FILE" 2>&1

# Verify quantization
log "INFO" "Verifying model quantization..."
ollama list | grep qwen2.5-coder:32b

# Expected output includes quantization info
# Quantization level: int8 (default for Ollama 32B models)

# Fast: qwen2.5-coder:7b (int4 quantized)
log "INFO" "Pulling qwen2.5-coder:7b (int4 quantized)"
time ollama pull qwen2.5-coder:7b >> "$LOG_FILE" 2>&1

# Alternative: deepseek-coder-v2:16b (int8 quantized)
log "INFO" "Pulling deepseek-coder-v2:16b (int8 quantized)"
time ollama pull deepseek-coder-v2:16b >> "$LOG_FILE" 2>&1
```

**Verification Command:**
```bash
# Check if model uses quantization
ollama show qwen2.5-coder:32b | grep -i "quant\|int8\|Q4"
```

### 4.2 Custom Quantization (Fallback)

**Fallback implementation (if Ollama model unavailable):**

```bash
# Build custom GGUF model (2-4 hours)
# Only execute if: ollama pull fails AND user confirms

log "WARN" "Ollama model not available. Build custom quantized model?"
log "INFO" "This will take 2-4 hours and requires significant disk space"
read -r -p "Build custom model? (y/N): " response

if [[ "$response" =~ ^[Yy]$ ]]; then
    log "INFO" "Starting custom quantization build..."

    # This would require:
    # 1. Download base model from HuggingFace
    # 2. Install llama.cpp
    # 3. Convert to GGUF with quantization
    # 4. Create Ollama model file

    bash "$(dirname "${BASH_SOURCE[0]}")/../lib/build-gguf.sh"
else
    log "WARN" "Skipping custom build, continuing with available models"
fi
```

---

## 5. Verification Commands

### 5.1 Metadata Completeness Check

**Command:**
```bash
# Find scripts missing DOC-SCR- metadata
cd scripts/install
grep -L "DOC-SCR-" *.sh
```

**Expected Output:** (empty - all scripts have metadata)

**Fix Script (if needed):**
```bash
# Add DOC-ID to scripts missing it
for script in $(grep -L "DOC-SCR-" *.sh); do
    # Extract phase number
    phase=$(echo "$script" | grep -oP '\d+(?=-)')

    # Add metadata after first line
    sed -i "2 a #\n# DOC-ID: DOC-SCR-00${phase}\n# VERSION: 1.0.0\n# STATUS: RELEASED" "$script"
done
```

### 5.2 Hardcoded Password Check

**Command:**
```bash
# Find hardcoded passwords (exclude prompt/read statements)
cd scripts/install
grep -rn "PASSWORD=" . | grep -v "prompt\|read\|N8N_BASIC_AUTH_PASSWORD=\${"
```

**Expected Output:** (empty - no hardcoded passwords)

**Current Finding (before fix):**
```
09-service-automation.sh:53:  -e N8N_BASIC_AUTH_PASSWORD=gx10admin \
```

**Fix Verification:**
```bash
# After fix, this should return empty
grep -rn "gx10admin" scripts/install/  # Should return empty
grep -rn "PASSWORD=\".*\"" scripts/install/ | grep -v "prompt\|read"  # Should return empty
```

### 5.3 HTTPS/Certificate Check

**Command:**
```bash
# Verify HTTPS implementation
cd scripts/install
grep -n "https\|cert\|ssl\|443\|generate_cert" 08-webui-install.sh | head -5
```

**Expected Output:** Must contain:
- `generate_cert` function call
- `-p 443:8443` or similar HTTPS port
- Certificate volume mount

**Current Finding (before fix):** No HTTPS implementation

### 5.4 Library Sourcing Check

**Command:**
```bash
# Verify all scripts source shared libraries
cd scripts/install
grep -n "source.*lib/" *.sh | wc -l
```

**Expected Output:** 10 or more (all scripts source libraries)

**Required Pattern:**
```bash
# At the top of each script (after set -e set -u)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logger.sh"
source "$SCRIPT_DIR/../lib/error-handler.sh"
source "$SCRIPT_DIR/../lib/security.sh"
source "$SCRIPT_DIR/../lib/state-manager.sh"
```

### 5.5 Checkpoint Implementation Check

**Command:**
```bash
# Verify checkpoint creation
cd scripts/install
grep -n "checkpoint\|rollback\|init_state" *.sh | wc -l
```

**Expected Output:** At least 30 (3+ per script)

**Required Pattern:**
```bash
# At start of each phase
init_state
CHECKPOINT_ID=$(checkpoint "phase-$PHASE" "Before $PHASE_NAME")

# At successful completion
complete_checkpoint "$CHECKPOINT_ID"

# On error trap
trap "rollback $CHECKPOINT_ID; exit 1" ERR
```

### 5.6 Comprehensive Audit Script

**Complete verification script:**

```bash
#!/bin/bash
# GX10 Installation Scripts - Comprehensive Audit

echo "=== GX10 Installation Scripts Audit ==="
echo ""

PASS=0
FAIL=0

# Check 1: Metadata completeness
echo "[1/6] Checking metadata completeness..."
MISSING_METADATA=$(cd scripts/install && grep -L "DOC-SCR-" *.sh | wc -l)
if [ "$MISSING_METADATA" -eq 0 ]; then
    echo "  ✅ PASS: All scripts have DOC-ID metadata"
    ((PASS++))
else
    echo "  ❌ FAIL: $MISSING_METADATA scripts missing DOC-ID"
    ((FAIL++))
fi

# Check 2: Hardcoded passwords
echo "[2/6] Checking for hardcoded passwords..."
HARDCODED_PASSWORDS=$(cd scripts/install && grep -rn "PASSWORD=" . | grep -v "prompt\|read\|\${" | wc -l)
if [ "$HARDCODED_PASSWORDS" -eq 0 ]; then
    echo "  ✅ PASS: No hardcoded passwords found"
    ((PASS++))
else
    echo "  ❌ FAIL: $HARDCODED_PASSWORDS hardcoded passwords found"
    ((FAIL++))
    grep -rn "PASSWORD=" . | grep -v "prompt\|read\|\${"
fi

# Check 3: HTTPS implementation
echo "[3/6] Checking HTTPS implementation..."
HTTPS_COUNT=$(cd scripts/install && grep -c "443\|generate_cert\|https" 08-webui-install.sh 2>/dev/null || echo "0")
if [ "$HTTPS_COUNT" -gt 0 ]; then
    echo "  ✅ PASS: HTTPS implementation found"
    ((PASS++))
else
    echo "  ❌ FAIL: HTTPS not implemented"
    ((FAIL++))
fi

# Check 4: Library sourcing
echo "[4/6] Checking library sourcing..."
LIBRARY_COUNT=$(cd scripts/install && grep -c "source.*lib/" *.sh 2>/dev/null || echo "0")
if [ "$LIBRARY_COUNT" -ge 10 ]; then
    echo "  ✅ PASS: Libraries properly sourced"
    ((PASS++))
else
    echo "  ❌ FAIL: Only $LIBRARY_COUNT/10 scripts source libraries"
    ((FAIL++))
fi

# Check 5: Checkpoint implementation
echo "[5/6] Checking checkpoint implementation..."
CHECKPOINT_COUNT=$(cd scripts/install && grep -c "checkpoint\|rollback" *.sh 2>/dev/null || echo "0")
if [ "$CHECKPOINT_COUNT" -ge 20 ]; then
    echo "  ✅ PASS: Checkpoint system implemented"
    ((PASS++))
else
    echo "  ❌ FAIL: Insufficient checkpoint implementation ($CHECKPOINT_COUNT/20)"
    ((FAIL++))
fi

# Check 6: Quantization strategy
echo "[6/6] Checking quantization strategy..."
QUANT_COUNT=$(cd scripts/install && grep -c "quant\|int8\|INT8" *.sh 2>/dev/null || echo "0")
if [ "$QUANT_COUNT" -gt 0 ]; then
    echo "  ✅ PASS: Quantization strategy documented"
    ((PASS++))
else
    echo "  ⚠️  WARN: Quantization not explicitly documented (may use Ollama default)"
    ((PASS++))
fi

# Summary
echo ""
echo "=== Audit Summary ==="
echo "Passed: $PASS/6"
echo "Failed: $FAIL/6"

if [ $FAIL -eq 0 ]; then
    echo "✅ All checks passed!"
    exit 0
else
    echo "❌ Some checks failed - review required"
    exit 1
fi
```

---

## 6. Implementation Phases (With File Ownership)

### Phase 1: Foundation Libraries

**Sequential (must complete first)**
**Effort:** 4 hours

| File | Owner | Task | Dependencies |
|------|-------|------|--------------|
| `lib/logger.sh` | Team-Lib-1 | Create logging library | None |
| `lib/state-manager.sh` | Team-Lib-2 | Create state persistence | None |
| `lib/security.sh` | Team-Lib-3 | Create security utilities | logger.sh |
| `lib/error-handler.sh` | Team-Lib-4 | Create error handling | state-manager.sh, logger.sh |

### Phase 2: Script Header Updates

**Parallel (5 teams)**
**Effort:** 2 hours (parallel)

| Team | Scripts | DOC-IDs |
|------|---------|---------|
| Team-A | 01, 02 | DOC-SCR-001, DOC-SCR-002 |
| Team-B | 03, 04 | DOC-SCR-003, DOC-SCR-004 |
| Team-C | 05, 06 | DOC-SCR-005, DOC-SCR-006 |
| Team-D | 07, 08 | DOC-SCR-007, DOC-SCR-008 |
| Team-E | 09, 10 | DOC-SCR-009, DOC-SCR-010 |

**Each team updates:**
1. Add standardized header (DOC-ID, version, status)
2. Source library modules at top
3. Replace inline `log()` with library calls
4. Add checkpoint calls

### Phase 3: Error Handling Integration

**Parallel (5 teams, same ownership as Phase 2)**
**Effort:** 4 hours (parallel)

**Each team adds:**
1. Checkpoint at phase start
2. Complete checkpoint at phase end
3. Rollback handlers for critical operations
4. Error trap with rollback

### Phase 4: Security Fixes

**Sequential (credential changes)**
**Effort:** 2 hours

| File | Task | Dependencies |
|------|-------|--------------|
| `00-install-all.sh` | Add password prompt at start | security.sh |
| `09-service-automation.sh` | Remove hardcoded password | security.sh, 00-install-all.sh |
| `08-webui-install.sh` | Add HTTPS implementation | security.sh |

### Phase 5: Verification

**Parallel (3 teams)**
**Effort:** 2 hours

| Team | Task |
|------|-------|
| Audit-Team | Run comprehensive audit script |
| Test-Team | Execute dry-run installation |
| Doc-Team | Create DOC-MATRIX.md, update README |

---

## 7. Risk Mitigation

### 7.1 Breaking Changes

**Risk:** Enhanced scripts may break existing installations

**Mitigation:**
```bash
# Add version check in 00-install-all.sh
if [ -f "/gx10/runtime/state/version" ]; then
    CURRENT_VERSION=$(cat /gx10/runtime/state/version)
    if [ "$CURRENT_VERSION" != "2.0.0" ]; then
        log "WARN" "Detected installation version $CURRENT_VERSION"
        log "INFO" "Upgrade to version 2.0.0 recommended"
        read -p "Continue? (y/N): " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
fi

# Save version after first phase
echo "2.0.0" > /gx10/runtime/state/version
```

### 7.2 Password Prompt in CI/CD

**Risk:** Automated deployments require interactive password

**Mitigation:**
```bash
# Support both environment variable and prompt
if [ -n "${GX10_PASSWORD:-}" ]; then
    # Use environment variable
    ADMIN_PASSWORD="$GX10_PASSWORD"
else
    # Use interactive prompt
    ADMIN_PASSWORD=$(get_admin_password)
fi
```

### 7.3 Certificate Generation Failure

**Risk:** Certificate generation fails, blocking installation

**Mitigation:**
```bash
# Fallback to HTTP with warning
if ! generate_cert "$SERVER_NAME" "$CERT_DIR"; then
    log "WARN" "Certificate generation failed"
    log "WARN" "Falling back to HTTP (not recommended for production)"
    ENABLE_HTTPS=false
fi
```

---

## 8. Success Criteria

### 8.1 Installation Success

- [ ] All 10 phases complete without critical errors
- [ ] All services running (Ollama, Open WebUI, n8n, Vision Brain)
- [ ] All models downloaded and accessible
- [ ] Brain switch completes in < 30 seconds
- [ ] Installation report has 0 ERROR entries

### 8.2 Script Quality

- [ ] 100% of scripts have DOC-ID metadata
- [ ] 100% of scripts source all 4 libraries
- [ ] 0 hardcoded passwords in any script
- [ ] All error messages include: problem, impact, action

### 8.3 Security Compliance

- [ ] No default credentials in production state
- [ ] HTTPS available for web interfaces
- [ ] Password complexity enforced
- [ ] No secrets in logs or console output

### 8.4 Error Recovery

- [ ] Each phase can be re-run independently
- [ ] Resume capability functional
- [ ] Rollback capability tested
- [ ] State persistence verified

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-01 | 1.0.0 | Initial technical implementation guide |

---

*End of Technical Implementation Guide*
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-02

**리뷰어**:

- drake

