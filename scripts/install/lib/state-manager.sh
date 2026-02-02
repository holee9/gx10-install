#!/bin/bash
# GX10 State Manager Library
# Manages persistent state across installation phases
#
# DOC-ID: DOC-LIB-002
# VERSION: 1.0.0
# STATUS: RELEASED
#
# Author: Alfred
# Created: 2026-02-02
#
# Functions:
# - init_state(): Initialize state directory and create state.json
# - save_state(key, value): Save state value to config
# - load_state(key): Load state value from config
# - set_phase(phase_number): Set current installation phase
# - get_phase(): Get current installation phase
# - set_status(status): Set installation status
# - get_status(): Get installation status
#
# State file location: /gx10/runtime/state/state.json

# State directory
GX10_STATE_DIR="/gx10/runtime/state"
STATE_FILE="$GX10_STATE_DIR/state.json"

# init_state(): Initialize state directory and create state file
# Side effect: Creates state directory structure and initial state.json
init_state() {
    # Create state directory
    mkdir -p "$GX10_STATE_DIR"

    # Create state file if not exists
    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "version": "1.0",
  "installation_id": null,
  "started_at": null,
  "updated_at": null,
  "current_phase": 0,
  "status": "not_started",
  "config": {}
}
EOF
        echo "State initialized at: $STATE_FILE"
    fi
}

# _ensure_state_file(): Internal helper to ensure state file exists
_ensure_state_file() {
    if [ ! -f "$STATE_FILE" ]; then
        init_state
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

# save_state(): Save state value to config
# Args: $1=key, $2=value
# Returns: 0=success, 1=failure
save_state() {
    local key="$1"
    local value="$2"

    _ensure_state_file
    _check_jq || return 1

    # Update timestamp and save value
    local timestamp=$(date -u -Iseconds)
    jq ".config.$key = \"$value\" | .updated_at = \"$timestamp\"" "$STATE_FILE" > "${STATE_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
        return 0
    else
        echo "ERROR: Failed to save state key: $key" >&2
        rm -f "${STATE_FILE}.tmp"
        return 1
    fi
}

# save_state_json(): Save complex JSON value to config
# Args: $1=key, $2=json_value
# Returns: 0=success, 1=failure
save_state_json() {
    local key="$1"
    local json_value="$2"

    _ensure_state_file
    _check_jq || return 1

    local timestamp=$(date -u -Iseconds)
    jq ".config.$key = $json_value | .updated_at = \"$timestamp\"" "$STATE_FILE" > "${STATE_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
        return 0
    else
        echo "ERROR: Failed to save JSON state key: $key" >&2
        rm -f "${STATE_FILE}.tmp"
        return 1
    fi
}

# load_state(): Load state value from config
# Args: $1=key
# Returns: Value or empty string
load_state() {
    local key="$1"

    _ensure_state_file
    _check_jq || return 1

    jq -r ".config.$key // empty" "$STATE_FILE" 2>/dev/null
}

# load_state_json(): Load complex JSON value from config
# Args: $1=key
# Returns: JSON value or empty string
load_state_json() {
    local key="$1"

    _ensure_state_file
    _check_jq || return 1

    jq -r ".config.$key // {}" "$STATE_FILE" 2>/dev/null
}

# set_phase(): Set current phase
# Args: $1=phase_number
# Returns: 0=success, 1=failure
set_phase() {
    local phase="$1"

    _ensure_state_file
    _check_jq || return 1

    local timestamp=$(date -u -Iseconds)
    jq ".current_phase = $phase | .updated_at = \"$timestamp\"" "$STATE_FILE" > "${STATE_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
        return 0
    else
        echo "ERROR: Failed to set phase: $phase" >&2
        rm -f "${STATE_FILE}.tmp"
        return 1
    fi
}

# get_phase(): Get current phase
# Returns: Phase number
get_phase() {
    _ensure_state_file
    _check_jq || return 1

    jq -r '.current_phase' "$STATE_FILE" 2>/dev/null
}

# set_status(): Set installation status
# Args: $1=status (not_started|in_progress|completed|failed|rolled_back)
# Returns: 0=success, 1=failure
set_status() {
    local status="$1"

    _ensure_state_file
    _check_jq || return 1

    local timestamp=$(date -u -Iseconds)

    # Set started_at on first in_progress
    if [ "$status" = "in_progress" ]; then
        local current_status=$(jq -r '.status' "$STATE_FILE")
        if [ "$current_status" = "not_started" ]; then
            jq ".status = \"$status\" | .started_at = \"$timestamp\" | .updated_at = \"$timestamp\"" "$STATE_FILE" > "${STATE_FILE}.tmp"
        else
            jq ".status = \"$status\" | .updated_at = \"$timestamp\"" "$STATE_FILE" > "${STATE_FILE}.tmp"
        fi
    else
        jq ".status = \"$status\" | .updated_at = \"$timestamp\"" "$STATE_FILE" > "${STATE_FILE}.tmp"
    fi

    if [ $? -eq 0 ]; then
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
        return 0
    else
        echo "ERROR: Failed to set status: $status" >&2
        rm -f "${STATE_FILE}.tmp"
        return 1
    fi
}

# get_status(): Get installation status
# Returns: Status string
get_status() {
    _ensure_state_file
    _check_jq || return 1

    jq -r '.status' "$STATE_FILE" 2>/dev/null
}

# get_installation_id(): Get or create installation ID
# Returns: Installation ID
get_installation_id() {
    _ensure_state_file
    _check_jq || return 1

    local id=$(jq -r '.installation_id // empty' "$STATE_FILE" 2>/dev/null)

    if [ -z "$id" ]; then
        # Generate new installation ID
        id="gx10-$(date +%Y%m%d-%H%M%S)-$(hostname | cut -c1-8)"
        local timestamp=$(date -u -Iseconds)
        jq ".installation_id = \"$id\" | .updated_at = \"$timestamp\"" "$STATE_FILE" > "${STATE_FILE}.tmp"
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi

    echo "$id"
}

# get_state_file(): Get the state file path
# Returns: Path to state.json
get_state_file() {
    echo "$STATE_FILE"
}

# export_state(): Export state as JSON string
# Returns: Full state JSON
export_state() {
    _ensure_state_file
    _check_jq || return 1

    cat "$STATE_FILE"
}

# import_state(): Import state from JSON string
# Args: $1=json_string
# Returns: 0=success, 1=failure
import_state() {
    local json_string="$1"

    mkdir -p "$GX10_STATE_DIR"

    # Validate JSON before importing
    if echo "$json_string" | jq empty 2>/dev/null; then
        echo "$json_string" > "$STATE_FILE"
        return 0
    else
        echo "ERROR: Invalid JSON state data" >&2
        return 1
    fi
}

# reset_state(): Reset state to initial values (use with caution)
# Returns: 0=success, 1=failure
reset_state() {
    local confirmation="${2:-no}"

    if [ "$confirmation" != "yes-i-am-sure" ]; then
        echo "ERROR: State reset requires confirmation. Use: reset_state yes-i-am-sure" >&2
        return 1
    fi

    cat > "$STATE_FILE" << 'EOF'
{
  "version": "1.0",
  "installation_id": null,
  "started_at": null,
  "updated_at": null,
  "current_phase": 0,
  "status": "not_started",
  "config": {}
}
EOF
    echo "State has been reset"
    return 0
}

# Export functions for use in other scripts
export -f init_state
export -f save_state
export -f save_state_json
export -f load_state
export -f load_state_json
export -f set_phase
export -f get_phase
export -f set_status
export -f get_status
export -f get_installation_id
export -f get_state_file
export -f export_state
export -f import_state
export -f reset_state
