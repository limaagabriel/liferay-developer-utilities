#!/bin/bash
# lp - Liferay Portal script entrypoint
#
# This file must be sourced so that commands like `lp worktree cd` and
# `lp bundle cd` can change the current shell's directory.
#
# Add to ~/.zshrc or ~/.bashrc:
#   source ~/dev/scripts/lp.sh

_LP_SCRIPTS_DIR="/home/me/dev/scripts"

source "$_LP_SCRIPTS_DIR/lib/help.sh"

lp() {
    # No arguments — show top-level help
    if [[ $# -eq 0 ]]; then
        lp_top_level_help
        return 1
    fi

    local namespace="$1"

    # lp help — top-level help
    if [[ "$namespace" == "help" ]]; then
        lp_top_level_help
        return 0
    fi

    # Validate namespace
    local ns_cmds
    ns_cmds=$(_lp_ns_cmds "$namespace")
    if [[ -z "$ns_cmds" ]]; then
        echo "lp: unknown namespace '$namespace'" >&2
        return 1
    fi

    # lp <ns> — namespace-level help
    if [[ $# -eq 1 ]]; then
        lp_namespace_help "$namespace"
        return 1
    fi

    local command="$2"

    # lp <ns> help — namespace-level help
    if [[ "$command" == "help" ]]; then
        lp_namespace_help "$namespace"
        return 0
    fi

    local script="$_LP_SCRIPTS_DIR/commands/$namespace/$command.sh"

    if [[ ! -f "$script" ]]; then
        echo "lp: unknown command '$namespace $command'" >&2
        return 1
    fi

    # Commands that must be sourced to affect the current shell's working directory
    case "$namespace/$command" in
        worktree/cd|bundle/cd)
            source "$script" "${@:3}"
            ;;
        *)
            "$script" "${@:3}"
            ;;
    esac
}
