#!/bin/bash
# lp - Liferay Portal script entrypoint
#
# This file must be sourced so that commands like `lp worktree cd` and
# `lp bundle cd` can change the current shell's directory.
#
# Add to ~/.zshrc or ~/.bashrc:
#   source ~/dev/scripts/lp.sh
#
# Usage:
#   lp worktree add [-r <remote>] <branch>
#   lp worktree cd <branch>
#   lp worktree code <branch>
#   lp worktree list
#   lp worktree rebuild <branch>
#   lp worktree remove <branch>
#   lp worktree start [-b] [branch]
#   lp mysql start
#   lp mysql reset
#   lp bundle cd <branch>

_LP_SCRIPTS_DIR="/home/me/dev/scripts"

lp() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: lp <namespace> <command> [args...]"
        echo ""
        echo "Available commands:"
        echo "  lp worktree add [-r <remote>] <branch>"
        echo "  lp worktree cd <branch>"
        echo "  lp worktree code <branch>"
        echo "  lp worktree list"
        echo "  lp worktree rebuild <branch>"
        echo "  lp worktree remove <branch>"
        echo "  lp worktree start [-b] [branch]"
        echo "  lp mysql start"
        echo "  lp mysql reset"
        echo "  lp bundle cd <branch>"
        return 1
    fi

    local namespace="$1"
    local command="$2"
    local script="$_LP_SCRIPTS_DIR/commands/$namespace/$command.sh"

    echo script: "$script"

    if [[ ! -f "$script" ]]; then
        echo "lp: unknown command '$namespace $command'"
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
