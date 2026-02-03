#!/bin/bash
# GX10 Security Library
# Provides password management and certificate generation
#
# DOC-ID: DOC-LIB-003
# VERSION: 1.0.0
# STATUS: RELEASED
# DEPENDS: logger.sh
#
# Author: Alfred
# Created: 2026-02-02
#
# Functions:
# - validate_password(password): Check password complexity
# - prompt_password(prompt_text, min_length): Interactive password prompt
# - get_admin_password(): Get password from env or prompt
# - generate_cert(domain, cert_dir): Create self-signed SSL certificate
# - hash_password(password): Generate SHA256 hash
#
# Password requirements: min 12 chars, uppercase, lowercase, number, special

# Source logger library for logging functions
# Note: This should be sourced before calling security functions
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# source "$SCRIPT_DIR/logger.sh"

# Password complexity requirements
PASSWORD_MIN_LENGTH=12
PASSWORD_REQUIRE_UPPER=true
PASSWORD_REQUIRE_LOWER=true
PASSWORD_REQUIRE_NUMBER=true
PASSWORD_REQUIRE_SPECIAL=true
PASSWORD_SPECIAL_CHARS="!@#$%^&*"

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
        if ! [[ "$password" =~ [$PASSWORD_SPECIAL_CHARS] ]]; then
            echo "ERROR: Password must contain at least one special character ($PASSWORD_SPECIAL_CHARS)" >&2
            return 1
        fi
    fi

    return 0
}

# prompt_password(): Interactive password prompt with validation
# Args: $1=prompt_text, $2=min_length (default 12)
# Returns: Password via stdout (not echoed), exit code 1 on failure
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
        echo

        # Check if passwords match
        if [ "$password" != "$confirm" ]; then
            echo "ERROR: Passwords do not match. Please try again." >&2
            ((attempts++))
            continue
        fi

        # Validate password complexity
        if validate_password "$password" 2>/dev/null; then
            # Success - output password (only to caller, not to console)
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
# Returns: Password via stdout, exit code 1 on failure
get_admin_password() {
    # Check environment variable first (for CI/CD)
    if [ -n "${GX10_PASSWORD:-}" ]; then
        # Validate environment variable password
        if validate_password "$GX10_PASSWORD" 2>/dev/null; then
            echo "$GX10_PASSWORD"
            return 0
        else
            echo "ERROR: GX10_PASSWORD does not meet complexity requirements" >&2
            echo "Required: min ${PASSWORD_MIN_LENGTH} chars, uppercase, lowercase, number, special char" >&2
            return 1
        fi
    fi

    # Check for password file (non-interactive mode)
    local password_file="/gx10/runtime/state/.admin_password"
    if [ -f "$password_file" ]; then
        local stored_password=$(cat "$password_file" 2>/dev/null)
        if [ -n "$stored_password" ] && validate_password "$stored_password" 2>/dev/null; then
            echo "$stored_password"
            return 0
        fi
    fi

    # Fall back to interactive prompt
    prompt_password "Enter GX10 admin password"
}

# save_admin_password(): Securely save admin password to file
# Args: $1=password
# Returns: 0=success, 1=failure
save_admin_password() {
    local password="$1"

    # Create state directory
    mkdir -p "/gx10/runtime/state"

    # Save with restricted permissions
    local password_file="/gx10/runtime/state/.admin_password"

    # Store password hash instead of plaintext
    local password_hash=$(hash_password "$password")
    echo "$password_hash" > "$password_file"

    # Set restrictive permissions
    chmod 600 "$password_file" 2>/dev/null

    return 0
}

# verify_admin_password(): Verify password against stored hash
# Args: $1=password
# Returns: 0=match, 1=no match or error
verify_admin_password() {
    local password="$1"
    local password_file="/gx10/runtime/state/.admin_password"

    if [ ! -f "$password_file" ]; then
        return 1
    fi

    local stored_hash=$(cat "$password_file" 2>/dev/null)
    local input_hash=$(hash_password "$password")

    if [ "$stored_hash" = "$input_hash" ]; then
        return 0
    fi

    return 1
}

# generate_cert(): Create self-signed SSL certificate
# Args: $1=domain, $2=cert_output_dir
# Returns: 0=success, 1=failure
generate_cert() {
    local domain="${1:-localhost}"
    local output_dir="${2:-/gx10/runtime/certs}"

    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        echo "ERROR: openssl is required for certificate generation" >&2
        return 1
    fi

    # Create output directory
    mkdir -p "$output_dir"

    local cert_file="$output_dir/cert.pem"
    local key_file="$output_dir/key.pem"

    # Check if certificate already exists and is valid
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        # Check if certificate is still valid (more than 30 days)
        local expiry=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry" ]; then
            local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null)
            local current_epoch=$(date +%s)
            local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))

            if [ $days_left -gt 30 ]; then
                echo "Certificate already exists and is valid for $days_left days"
                return 0
            fi
        fi
    fi

    # Generate self-signed certificate
    local subj="/CN=$domain/O=GX10/C=US"

    if openssl req -x509 -newkey rsa:4096 \
        -keyout "$key_file" \
        -out "$cert_file" \
        -days 365 \
        -nodes \
        -subj "$subj" 2>/dev/null; then

        # Set appropriate permissions
        chmod 644 "$cert_file" 2>/dev/null
        chmod 600 "$key_file" 2>/dev/null

        echo "Certificate generated successfully"
        echo "  Certificate: $cert_file"
        echo "  Private key: $key_file"
        return 0
    else
        echo "ERROR: Certificate generation failed" >&2
        return 1
    fi
}

# generate_cert_with_san(): Create certificate with Subject Alternative Names
# Args: $1=domain, $2=comma_separated_sans, $3=cert_output_dir
# Returns: 0=success, 1=failure
generate_cert_with_san() {
    local domain="${1:-localhost}"
    local sans="${2:-DNS:localhost,DNS:localhost.localdomain}"
    local output_dir="${3:-/gx10/runtime/certs}"

    if ! command -v openssl &> /dev/null; then
        echo "ERROR: openssl is required for certificate generation" >&2
        return 1
    fi

    mkdir -p "$output_dir"

    local cert_file="$output_dir/cert.pem"
    local key_file="$output_dir/key.pem"
    local config_file="$output_dir/openssl.cnf"

    # Create OpenSSL config with SAN
    cat > "$config_file" << EOF
[req]
default_bits = 4096
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $domain
O = GX10
C = US

[v3_req]
subjectAltName = $sans
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
EOF

    # Generate certificate with SAN
    if openssl req -x509 -newkey rsa:4096 \
        -keyout "$key_file" \
        -out "$cert_file" \
        -days 365 \
        -nodes \
        -config "$config_file" \
        -extensions v3_req 2>/dev/null; then

        chmod 644 "$cert_file" 2>/dev/null
        chmod 600 "$key_file" 2>/dev/null
        rm -f "$config_file"

        echo "Certificate with SAN generated successfully"
        echo "  Certificate: $cert_file"
        echo "  SANs: $sans"
        return 0
    else
        rm -f "$config_file"
        echo "ERROR: Certificate generation failed" >&2
        return 1
    fi
}

# hash_password(): Generate password hash (for secure storage)
# Args: $1=password
# Returns: SHA256 hash
hash_password() {
    local password="$1"
    # Using SHA256 for basic hashing
    # For production, consider using bcrypt or argon2
    echo -n "$password" | sha256sum | cut -d' ' -f1
}

# generate_random_password(): Generate a secure random password
# Args: $1=length (default 16)
# Returns: Random password
generate_random_password() {
    local length="${1:-16}"

    # Ensure password meets complexity requirements
    local password=""
    local attempts=0
    local max_attempts=100

    while [ $attempts -lt $max_attempts ]; do
        # Generate random password using /dev/urandom
        password=$(cat /dev/urandom 2>/dev/null | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c "$length")

        # Validate complexity
        if validate_password "$password" 2>/dev/null; then
            echo "$password"
            return 0
        fi

        ((attempts++))
    done

    echo "ERROR: Failed to generate valid password" >&2
    return 1
}

# check_password_strength(): Assess password strength
# Args: $1=password
# Returns: Strength level (weak|fair|good|strong)
check_password_strength() {
    local password="$1"
    local score=0

    # Length check
    if [ ${#password} -ge 12 ]; then ((score++))
    elif [ ${#password} -ge 16 ]; then ((score+=2))
    fi

    # Character variety
    [[ "$password" =~ [A-Z] ]] && ((score++))
    [[ "$password" =~ [a-z] ]] && ((score++))
    [[ "$password" =~ [0-9] ]] && ((score++))
    [[ "$password" =~ [!@#$%^&*] ]] && ((score++))

    # Determine strength
    if [ $score -lt 3 ]; then
        echo "weak"
    elif [ $score -lt 4 ]; then
        echo "fair"
    elif [ $score -lt 6 ]; then
        echo "good"
    else
        echo "strong"
    fi
}

# Export functions for use in other scripts
export -f validate_password
export -f prompt_password
export -f get_admin_password
export -f save_admin_password
export -f verify_admin_password
export -f generate_cert
export -f generate_cert_with_san
export -f hash_password
export -f generate_random_password
export -f check_password_strength
