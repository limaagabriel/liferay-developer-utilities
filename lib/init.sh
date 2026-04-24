#!/bin/bash
# lib/init.sh — Common initialization for lp command scripts.

# lp_init_command <namespace> <command> "$@"
# Standardizes script setup: sources config, handles help/verbose flags.
lp_init_command() {
    local _lp_ns="$1"
    local _lp_cmd="$2"
    shift 2

    # Source core libraries (already done in lp.sh, but good for standalone)
    source "$_LP_SCRIPTS_DIR/lib/output.sh"
    source "$_LP_SCRIPTS_DIR/lib/help.sh"
    source "$_LP_SCRIPTS_DIR/lib/worktree.sh"

    # Source configuration (mandatory)
    if [[ "$_lp_ns" == "config" ]]; then
        # For config namespace, we allow it to fail or proceed with defaults
        source "$_LP_SCRIPTS_DIR/config.sh" >/dev/null 2>&1 || true
    else
        source "$_LP_SCRIPTS_DIR/config.sh" || {
            lp_error "Failed to load configuration."
            return 1 2>/dev/null || exit 1
        }
    fi

    # Handle help flag early
    for _lp_arg in "$@"; do
        if [[ "$_lp_arg" == "--help" || "$_lp_arg" == "-h" ]]; then
            lp_print_command_help "$_lp_ns" "$_lp_cmd"
            # Return/exit depending on if we are sourced or executed
            if [[ "${BASH_SOURCE[1]}" == "${0}" ]]; then
                exit 0
            else
                return 255
            fi
        fi
    done

    # Initialize standard variables
    # If VERBOSE is already 1 (inherited), keep it. Otherwise, default to 0.
    VERBOSE="${VERBOSE:-0}"
    
    for _lp_arg in "$@"; do
        if [[ "$_lp_arg" == "--verbose" || "$_lp_arg" == "-v" ]]; then
            VERBOSE=1
            break
        fi
    done
    export VERBOSE
}
