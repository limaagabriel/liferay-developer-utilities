#!/bin/bash
# lib/output.sh — Shared output helpers for lp scripts.
#
# Source this file at the top of lp scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

# lp_step N TOTAL "message" — print "[N/TOTAL] message..."
lp_step() {
    echo "[$1/$2] $3..."
}

# lp_info "message" — print an informational line
lp_info() {
    echo "$1"
}

# lp_success "message" — print a success confirmation
lp_success() {
    echo "$1"
}

# lp_error "message" — print an error message to stderr
lp_error() {
    echo "$1" >&2
}

# lp_run <cmd> [args...] — run a command, suppressing stdout+stderr unless VERBOSE=1
lp_run() {
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}
