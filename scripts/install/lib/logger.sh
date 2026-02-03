#!/bin/bash
# GX10 Logger Library
# Provides standardized logging with rotation
#
# DOC-ID: DOC-LIB-001
# VERSION: 1.0.0
# STATUS: RELEASED
#
# Author: Alfred
# Created: 2026-02-02
#
# Functions:
# - log(level, message): Unified logging function
# - init_log(phase_number, phase_name): Initialize log for a phase
# - set_level(level): Set minimum log level
# - rotate_logs(max_size_mb): Rotate large log files
#
# Log Levels: DEBUG, INFO, WARN, ERROR, CRITICAL

# Log levels with numeric values for comparison
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [CRITICAL]=4
)

# Current log level (default: INFO, can be overridden by LOG_LEVEL env var)
CURRENT_LOG_LEVEL="${LOG_LEVEL:-INFO}"
CURRENT_LOG_VALUE="${LOG_LEVELS[$CURRENT_LOG_LEVEL]}"

# Main log directory
LOG_DIR="/gx10/runtime/logs"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# log(): Unified logging function
# Args: $1=level (DEBUG|INFO|WARN|ERROR|CRITICAL), $2=message
# Side effect: Outputs to stdout and log file
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # Validate log level
    if [ -z "${LOG_LEVELS[$level]}" ]; then
        echo "[$timestamp] [ERROR] Invalid log level: $level" >&2
        level="ERROR"
    fi

    # Check if level should be logged based on current level
    local level_value="${LOG_LEVELS[$level]}"
    if [ "$level_value" -lt "$CURRENT_LOG_VALUE" ]; then
        return 0  # Skip logging - below threshold
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
# Side effect: Creates phase-specific log file and logs initialization
init_log() {
    local phase_num="$1"
    local phase_name="$2"
    local phase_log="$LOG_DIR/${phase_num}-${phase_name}.log"

    # Create phase log file
    touch "$phase_log"

    # Log initialization to both phase log and main log
    local separator="============================================================"
    echo "$separator" >> "$phase_log"
    echo "Phase $phase_num: $phase_name started at $(date -Iseconds)" >> "$phase_log"
    echo "$separator" >> "$phase_log"

    log "INFO" "=== Phase $phase_num: $phase_name started ==="
}

# set_level(): Set minimum log level
# Args: $1=level (DEBUG|INFO|WARN|ERROR|CRITICAL)
# Returns: 0=success, 1=failure
set_level() {
    local new_level="$1"

    if [ -z "${LOG_LEVELS[$new_level]}" ]; then
        echo "ERROR: Invalid log level: $new_level" >&2
        echo "Valid levels: DEBUG, INFO, WARN, ERROR, CRITICAL" >&2
        return 1
    fi

    CURRENT_LOG_LEVEL="$new_level"
    CURRENT_LOG_VALUE="${LOG_LEVELS[$new_level]}"
    log "INFO" "Log level changed to: $new_level"
    return 0
}

# rotate_logs(): Rotate large log files
# Args: $1=max_size_mb (default 100)
rotate_logs() {
    local max_size_mb="${1:-100}"
    local max_size_bytes=$((max_size_mb * 1024 * 1024))
    local rotated_count=0

    # Find log files larger than max_size
    while IFS= read -r -d '' logfile; do
        if [ -f "$logfile" ]; then
            local filesize=$(stat -c%s "$logfile" 2>/dev/null || stat -f%z "$logfile" 2>/dev/null || echo 0)

            if [ "$filesize" -gt "$max_size_bytes" ]; then
                # Create compressed archive
                local timestamp=$(date +'%Y%m%d-%H%M%S')
                local basename=$(basename "$logfile" .log)
                local archive_name="${LOG_DIR}/${basename}.${timestamp}.log.gz"

                # Compress log file
                if gzip -c "$logfile" > "$archive_name" 2>/dev/null; then
                    # Truncate original file
                    : > "$logfile"

                    ((rotated_count++))
                    echo "Rotated: $logfile -> $archive_name"
                fi
            fi
        fi
    done < <(find "$LOG_DIR" -type f -name "*.log" -print0 2>/dev/null)

    # Keep only last 5 rotated logs per base name
    find "$LOG_DIR" -name "*.log.gz" -type f 2>/dev/null | sort | head -n -5 | xargs -r rm -f

    log "INFO" "Log rotation completed: $rotated_count files rotated (max: ${max_size_mb}MB)"
    return 0
}

# get_log_file(): Get the current log file path
# Returns: Path to the main installation log file
get_log_file() {
    echo "$LOG_DIR/installation.log"
}

# get_phase_log(): Get the phase-specific log file path
# Args: $1=phase_number, $2=phase_name
# Returns: Path to the phase log file
get_phase_log() {
    local phase_num="$1"
    local phase_name="$2"
    echo "$LOG_DIR/${phase_num}-${phase_name}.log"
}

# Export functions for use in other scripts
export -f log
export -f init_log
export -f set_level
export -f rotate_logs
export -f get_log_file
export -f get_phase_log
