#!/bin/bash
# lp_init_command <namespace> <command> "$@"
# Sources libs/config, handles --help and --verbose flags.
lp_init_command() {
    local _lp_ns="$1"
    local _lp_cmd="$2"
    shift 2

    source "$_LP_SCRIPTS_DIR/lib/output.sh"
    source "$_LP_SCRIPTS_DIR/lib/help.sh"
    source "$_LP_SCRIPTS_DIR/lib/worktree.sh"

    if [[ "$_lp_ns" == "config" ]]; then
        source "$_LP_SCRIPTS_DIR/config.sh" >/dev/null 2>&1 || true
    else
        source "$_LP_SCRIPTS_DIR/config.sh" || {
            lp_error "Failed to load configuration."
            return 1 2>/dev/null || exit 1
        }
    fi

    for _lp_arg in "$@"; do
        if [[ "$_lp_arg" == "--help" || "$_lp_arg" == "-h" ]]; then
            lp_print_command_help "$_lp_ns" "$_lp_cmd"
            if [[ "${BASH_SOURCE[1]}" == "${0}" ]]; then
                exit 0
            else
                return 255
            fi
        fi
    done

    VERBOSE="${VERBOSE:-0}"
    for _lp_arg in "$@"; do
        if [[ "$_lp_arg" == "--verbose" || "$_lp_arg" == "-v" ]]; then
            VERBOSE=1
            break
        fi
    done
    export VERBOSE
}
