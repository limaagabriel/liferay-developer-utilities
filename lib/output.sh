#!/bin/bash
# lib/output.sh — Shared output helpers for lp scripts.
#
# Source this file at the top of lp scripts:
#   source "$_LP_SCRIPTS_DIR/lib/output.sh"

LP_OUTPUT_PREFIX="  "

# lp_step N TOTAL "message" — print " [N/TOTAL] message..."
lp_step() {
    echo "${LP_OUTPUT_PREFIX}[$1/$2] $3..."
}

# lp_info "message" — print an informational line
lp_info() {
    echo "${LP_OUTPUT_PREFIX}$1"
}

# lp_success "message" — print a success confirmation
lp_success() {
    echo "${LP_OUTPUT_PREFIX}$1"
}

# lp_error "message" — print an error message to stderr
lp_error() {
    echo "${LP_OUTPUT_PREFIX}$1" >&2
}

# lp_run <cmd> [args...] — run a command, suppressing stdout+stderr unless VERBOSE=1.
# If the command fails in non-verbose mode, the last 100 lines of output are shown.
lp_run() {
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then
        "$@"
        return $?
    else
        local tmp_out
        tmp_out=$(mktemp)
        "$@" > "$tmp_out" 2>&1
        local exit_code=$?
        
        if [[ $exit_code -ne 0 ]]; then
            echo "${LP_OUTPUT_PREFIX}Command failed with exit code $exit_code: $*" >&2
            echo "${LP_OUTPUT_PREFIX}Last 100 lines of output:" >&2
            tail -n 100 "$tmp_out" >&2
            rm -f "$tmp_out"
            return $exit_code
        fi
        
        rm -f "$tmp_out"
        return 0
    fi
}

# lp_format_duration <seconds> — format seconds into a human-readable string
lp_format_duration() {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    
    [[ $D -gt 0 ]] && printf '%dd ' $D
    [[ $H -gt 0 ]] && printf '%dh ' $H
    [[ $M -gt 0 ]] && printf '%dm ' $M
    printf '%ds' $S
}
