#!/bin/bash
# GX10 Error Handler Library
# Provides checkpoint, rollback, and resume capabilities
#
# DOC-ID: DOC-LIB-004
# VERSION: 1.0.0
# STATUS: RELEASED
# DEPENDS: state-manager.sh, logger.sh
#
# Author: Alfred
# Created: 2026-02-02
#
# Functions:
# - init_checkpoint_system(): Initialize checkpoint system
# - checkpoint(phase_name, description): Create a rollback point
# - complete_checkpoint(checkpoint_id): Mark checkpoint as completed
# - add_rollback_action(checkpoint_id, type, data): Register rollback action
# - rollback(checkpoint_id): Execute rollback to checkpoint
# - get_last_checkpoint(): Find most recent completed checkpoint
# - resume_from_checkpoint(checkpoint_id): Continue from checkpoint
#
# Checkpoint file: /gx10/runtime/state/checkpoints.json

# State directory
GX10_STATE_DIR="/gx10/runtime/state"
CHECKPOINT_FILE="$GX10_STATE_DIR/checkpoints.json"

# Current active checkpoint (for adding rollback actions)
_CURRENT_CHECKPOINT_ID=""

# init_checkpoint_system(): Initialize checkpoint directory and file
# Side effect: Creates checkpoint file with initial structure
init_checkpoint_system() {
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
        echo "Checkpoint system initialized at: $CHECKPOINT_FILE"
    fi
}

# _check_jq(): Check if jq is available
_check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq is required but not installed. Please install jq." >&2
        return 1
    fi
    return 0
}

# checkpoint(): Create a rollback point
# Args: $1=phase_name, $2=pre_action_description
# Returns: checkpoint_id (format: cp-{phase}-{timestamp})
checkpoint() {
    local phase_name="$1"
    local pre_action="$2"

    # Initialize if needed
    if [ ! -f "$CHECKPOINT_FILE" ]; then
        init_checkpoint_system
    fi

    _check_jq || return 1

    # Extract phase number from phase_name (e.g., "phase-01" -> "1", "01-code-models" -> "1")
    local phase_num="${phase_name##*-}"
    # If still not a number (e.g., only text), use the raw name
    if [[ "$phase_num" =~ ^[0-9]+$ ]]; then
        phase_num=$((10#$phase_num))
    else
        # Try extracting digits from anywhere in the string
        phase_num=$(echo "$phase_name" | grep -oE '[0-9]+' | head -1)
        phase_num=${phase_num:-0}
    fi

    local timestamp=$(date -u +"%Y%m%d-%H%M%S")
    local checkpoint_id="cp-${phase_num}-${timestamp}"
    local iso_timestamp=$(date -u -Iseconds)

    # Create checkpoint entry
    local checkpoint_entry=$(jq -n \
        --arg id "$checkpoint_id" \
        --arg phase "$phase_num" \
        --arg name "$phase_name" \
        --arg desc "$pre_action" \
        --arg ts "$iso_timestamp" \
        '{
            checkpoint_id: $id,
            phase: ($phase | tonumber),
            phase_name: $name,
            description: $desc,
            timestamp: $ts,
            status: "pending",
            rollback_actions: [],
            state_snapshot: {files_created: [], containers_created: [], services_enabled: [], packages_installed: []}
        }' )

    # Append to checkpoints array and update current phase
    jq ".checkpoints += [$checkpoint_entry] | .current_phase = $phase_num | .updated_at = \"$iso_timestamp\" | .created_at = (if .created_at == null then \"$iso_timestamp\" else .created_at end)" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
        # Set as current checkpoint for adding rollback actions
        _CURRENT_CHECKPOINT_ID="$checkpoint_id"
        echo "$checkpoint_id"
        return 0
    else
        echo "ERROR: Failed to create checkpoint" >&2
        rm -f "${CHECKPOINT_FILE}.tmp"
        return 1
    fi
}

# complete_checkpoint(): Mark checkpoint as completed
# Args: $1=checkpoint_id
# Returns: 0=success, 1=failure
complete_checkpoint() {
    local checkpoint_id="$1"

    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo "ERROR: Checkpoint file not found" >&2
        return 1
    fi

    local iso_timestamp=$(date -u -Iseconds)
    jq "(.checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\")).status = \"completed\" | .updated_at = \"$iso_timestamp\"" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
        # Clear current checkpoint
        _CURRENT_CHECKPOINT_ID=""
        return 0
    else
        echo "ERROR: Failed to complete checkpoint: $checkpoint_id" >&2
        rm -f "${CHECKPOINT_FILE}.tmp"
        return 1
    fi
}

# fail_checkpoint(): Mark checkpoint as failed
# Args: $1=checkpoint_id, $2=error_message
# Returns: 0=success, 1=failure
fail_checkpoint() {
    local checkpoint_id="$1"
    local error_message="${2:-Unknown error}"

    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo "ERROR: Checkpoint file not found" >&2
        return 1
    fi

    local iso_timestamp=$(date -u -Iseconds)
    jq "(.checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\")).status = \"failed\" | (.checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\")).error = \"$error_message\" | .updated_at = \"$iso_timestamp\"" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
        return 0
    else
        echo "ERROR: Failed to mark checkpoint as failed: $checkpoint_id" >&2
        rm -f "${CHECKPOINT_FILE}.tmp"
        return 1
    fi
}

# add_rollback_action(): Register rollback action for current checkpoint
# Args: $1=checkpoint_id, $2=action_type, $3=action_data
# Example: add_rollback_action "cp-1-xxx" "file" "remove:/tmp/file"
# Returns: 0=success, 1=failure
add_rollback_action() {
    local checkpoint_id="$1"
    local action_type="$2"
    local action_data="$3"

    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo "ERROR: Checkpoint file not found" >&2
        return 1
    fi

    # Escape special characters in action_data for JSON
    local escaped_data=$(echo "$action_data" | sed 's/"/\\"/g')

    jq "(.checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\")).rollback_actions += [{type: \"$action_type\", data: \"$escaped_data\"}]" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
        return 0
    else
        echo "ERROR: Failed to add rollback action for checkpoint: $checkpoint_id" >&2
        rm -f "${CHECKPOINT_FILE}.tmp"
        return 1
    fi
}

# add_file_rollback(): Add file removal rollback action (convenience function)
# Args: $1=checkpoint_id, $2=file_path
add_file_rollback() {
    local checkpoint_id="$1"
    local file_path="$2"
    add_rollback_action "$checkpoint_id" "file" "remove:$file_path"
}

# add_backup_rollback(): Add file restore rollback action (convenience function)
# Args: $1=checkpoint_id, $2=backup_path, $3=target_path
add_backup_rollback() {
    local checkpoint_id="$1"
    local backup_path="$2"
    local target_path="${3:-$backup_path}"
    add_rollback_action "$checkpoint_id" "file" "restore:$backup_path:$target_path"
}

# add_service_rollback(): Add service disable rollback action (convenience function)
# Args: $1=checkpoint_id, $2=service_name
add_service_rollback() {
    local checkpoint_id="$1"
    local service_name="$2"
    add_rollback_action "$checkpoint_id" "service" "disable:$service_name"
}

# add_container_rollback(): Add container stop rollback action (convenience function)
# Args: $1=checkpoint_id, $2=container_name
add_container_rollback() {
    local checkpoint_id="$1"
    local container_name="$2"
    add_rollback_action "$checkpoint_id" "container" "stop:$container_name"
}

# rollback(): Execute rollback to checkpoint
# Args: $1=checkpoint_id (target checkpoint to rollback TO)
# Returns: 0=success, 1=failure
rollback() {
    local target_checkpoint="$1"

    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo "ERROR: Checkpoint file not found" >&2
        return 1
    fi

    echo "=== Starting Rollback ==="
    echo "Target checkpoint: $target_checkpoint"

    # Get all checkpoints after target (including target) in reverse order
    local checkpoints_to_rollback=$(jq -r ".checkpoints | map(select(.checkpoint_id >= \"$target_checkpoint\")) | reverse | .[].checkpoint_id" "$CHECKPOINT_FILE" 2>/dev/null)

    if [ -z "$checkpoints_to_rollback" ]; then
        echo "ERROR: No checkpoints found to rollback" >&2
        return 1
    fi

    for cp_id in $checkpoints_to_rollback; do
        echo ""
        echo "Rolling back checkpoint: $cp_id"

        # Get rollback actions for this checkpoint
        local actions=$(jq -r ".checkpoints[] | select(.checkpoint_id == \"$cp_id\") | .rollback_actions[] | @json" "$CHECKPOINT_FILE" 2>/dev/null)

        if [ -z "$actions" ]; then
            echo "  No rollback actions for this checkpoint"
            continue
        fi

        # Execute actions in reverse order
        echo "$actions" | while IFS= read -r action; do
            [ -z "$action" ] && continue

            local type=$(echo "$action" | jq -r '.type')
            local data=$(echo "$action" | jq -r '.data')

            case "$type" in
                file)
                    _rollback_file "$data"
                    ;;
                service)
                    _rollback_service "$data"
                    ;;
                container)
                    _rollback_container "$data"
                    ;;
                env)
                    _rollback_env "$data"
                    ;;
                package)
                    _rollback_package "$data"
                    ;;
                *)
                    echo "  WARNING: Unknown rollback action type: $type" >&2
                    ;;
            esac
        done

        # Mark checkpoint as rolled back
        local iso_timestamp=$(date -u -Iseconds)
        jq "(.checkpoints[] | select(.checkpoint_id == \"$cp_id\")).status = \"rolled_back\" | .updated_at = \"$iso_timestamp\"" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
        mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
    done

    echo ""
    echo "=== Rollback Complete ==="
    return 0
}

# _rollback_file(): Internal function to handle file rollback
# Args: $1=action_data
_rollback_file() {
    local data="$1"

    if [[ "$data" == remove:* ]]; then
        local file_path="${data#remove:}"
        if [ -f "$file_path" ] || [ -L "$file_path" ]; then
            rm -f "$file_path" 2>/dev/null && echo "  Removed: $file_path" || echo "  WARNING: Failed to remove: $file_path" >&2
        else
            echo "  SKIPPED: File not found: $file_path"
        fi
    elif [[ "$data" == restore:* ]]; then
        local restore_data="${data#restore:}"
        local backup_path=$(echo "$restore_data" | cut -d: -f1)
        local target_path=$(echo "$restore_data" | cut -d: -f2)
        if [ -f "$backup_path" ]; then
            cp -f "$backup_path" "$target_path" 2>/dev/null && echo "  Restored: $target_path from $backup_path" || echo "  WARNING: Failed to restore: $target_path" >&2
        else
            echo "  WARNING: Backup not found: $backup_path" >&2
        fi
    fi
}

# _rollback_service(): Internal function to handle service rollback
# Args: $1=action_data
_rollback_service() {
    local data="$1"

    if [[ "$data" == disable:* ]]; then
        local service_name="${data#disable:}"
        if command -v systemctl &> /dev/null; then
            systemctl disable "$service_name" 2>/dev/null && systemctl stop "$service_name" 2>/dev/null && echo "  Disabled service: $service_name" || echo "  WARNING: Failed to disable service: $service_name" >&2
        else
            echo "  SKIPPED: systemctl not available for: $service_name"
        fi
    elif [[ "$data" == stop:* ]]; then
        local service_name="${data#stop:}"
        if command -v systemctl &> /dev/null; then
            systemctl stop "$service_name" 2>/dev/null && echo "  Stopped service: $service_name" || echo "  WARNING: Failed to stop service: $service_name" >&2
        fi
    fi
}

# _rollback_container(): Internal function to handle container rollback
# Args: $1=action_data
_rollback_container() {
    local data="$1"

    if [[ "$data" == stop:* ]]; then
        local container_name="${data#stop:}"
        if command -v docker &> /dev/null; then
            docker stop "$container_name" 2>/dev/null && echo "  Stopped container: $container_name" || echo "  WARNING: Failed to stop container: $container_name" >&2
        else
            echo "  SKIPPED: Docker not available for: $container_name"
        fi
    elif [[ "$data" == rm:* ]]; then
        local container_name="${data#rm:}"
        if command -v docker &> /dev/null; then
            docker stop "$container_name" 2>/dev/null
            docker rm "$container_name" 2>/dev/null && echo "  Removed container: $container_name" || echo "  WARNING: Failed to remove container: $container_name" >&2
        fi
    fi
}

# _rollback_env(): Internal function to handle environment variable rollback
# Args: $1=action_data
_rollback_env() {
    local data="$1"

    if [[ "$data" == unset:* ]]; then
        local env_var="${data#unset:}"
        # Remove from bashrc
        sed -i "/^export $env_var=/d" ~/.bashrc 2>/dev/null && echo "  Unset environment variable: $env_var" || echo "  WARNING: Failed to unset: $env_var" >&2
        # Unset from current session
        unset "$env_var" 2>/dev/null
    fi
}

# _rollback_package(): Internal function to handle package rollback
# Args: $1=action_data
_rollback_package() {
    local data="$1"

    if [[ "$data" == remove:* ]]; then
        local package_name="${data#remove:}"
        if command -v apt-get &> /dev/null; then
            apt-get remove -y "$package_name" 2>/dev/null && echo "  Removed package: $package_name" || echo "  WARNING: Failed to remove package: $package_name" >&2
        elif command -v yum &> /dev/null; then
            yum remove -y "$package_name" 2>/dev/null && echo "  Removed package: $package_name" || echo "  WARNING: Failed to remove package: $package_name" >&2
        else
            echo "  SKIPPED: No package manager found for: $package_name"
        fi
    fi
}

# get_last_checkpoint(): Find most recent completed checkpoint
# Returns: checkpoint_id or empty string
get_last_checkpoint() {
    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo ""
        return 1
    fi

    jq -r '.checkpoints | map(select(.status == "completed")) | .[-1].checkpoint_id // ""' "$CHECKPOINT_FILE" 2>/dev/null
}

# get_checkpoint_info(): Get information about a checkpoint
# Args: $1=checkpoint_id
# Returns: JSON with checkpoint information
get_checkpoint_info() {
    local checkpoint_id="$1"

    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo "{}"
        return 1
    fi

    jq ".checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\")" "$CHECKPOINT_FILE" 2>/dev/null
}

# list_checkpoints(): List all checkpoints with status
# Returns: Formatted list of checkpoints
list_checkpoints() {
    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo "No checkpoints found"
        return 1
    fi

    echo "=== Checkpoints ==="
    jq -r '.checkpoints[] | "\(.checkpoint_id)\t\(.status)\t\(.phase_name)\t\(.description)"' "$CHECKPOINT_FILE" 2>/dev/null | column -t -s $'\t'
}

# resume_from_checkpoint(): Continue from checkpoint
# Args: $1=checkpoint_id
# Returns: Next phase number
resume_from_checkpoint() {
    local checkpoint_id="$1"

    _check_jq || return 1

    # Get phase number from checkpoint
    local phase=$(jq -r ".checkpoints[] | select(.checkpoint_id == \"$checkpoint_id\") | .phase" "$CHECKPOINT_FILE" 2>/dev/null)

    if [ -z "$phase" ]; then
        echo "ERROR: Checkpoint not found: $checkpoint_id" >&2
        return 1
    fi

    # Return next phase
    echo $((phase + 1))
}

# get_current_phase(): Get current phase from checkpoint file
# Returns: Current phase number
get_current_phase() {
    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo "0"
        return 0
    fi

    jq -r '.current_phase' "$CHECKPOINT_FILE" 2>/dev/null
}

# cleanup_old_checkpoints(): Remove checkpoints older than specified days
# Args: $1=days_to_keep (default 30)
cleanup_old_checkpoints() {
    local days_to_keep="${1:-30}"
    local cutoff_date=$(date -d "$days_to_keep days ago" -u -Iseconds 2>/dev/null || date -v-${days_to_keep}d -u -Iseconds 2>/dev/null)

    _check_jq || return 1

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        return 0
    fi

    # Filter out old checkpoints and keep recent ones
    jq ".checkpoints = [.checkpoints[] | select(.timestamp >= \"$cutoff_date\" | not | not or (.status == \"completed\" or .status == \"rolled_back\"))]" "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
        echo "Cleaned up checkpoints older than $days_to_keep days"
        return 0
    fi

    rm -f "${CHECKPOINT_FILE}.tmp"
    return 1
}

# Export functions for use in other scripts
export -f init_checkpoint_system
export -f checkpoint
export -f complete_checkpoint
export -f fail_checkpoint
export -f add_rollback_action
export -f add_file_rollback
export -f add_backup_rollback
export -f add_service_rollback
export -f add_container_rollback
export -f rollback
export -f get_last_checkpoint
export -f get_checkpoint_info
export -f list_checkpoints
export -f resume_from_checkpoint
export -f get_current_phase
export -f cleanup_old_checkpoints
