#!/bin/bash
# Usage: source lp worktree cd <branch-name>
# NOTE: This script must be sourced (via `lp worktree cd`) to change the current
#       shell directory. The `lp` function handles this automatically.

# Guard: detect if the script is being executed instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced to change your current directory."
    echo "Run it as:  lp worktree cd <branch-name>"
    exit 1
fi

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Change the current directory to a worktree."
    echo ""
    echo "Usage: lp worktree cd <branch>"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree cd main"
    return 0
fi

source "$_LP_SCRIPTS_DIR/config.sh" || return 1

BRANCH="${1:-$LP_WORKTREE_REFERENCE_BRANCH}"

if [[ -z "$BRANCH" || "$BRANCH" == "master" ]]; then
    if [[ ! -d "$MAIN_REPO_DIR" ]]; then
        lp_error "Main repository '$MAIN_REPO_DIR' does not exist."
        return 1
    fi
    lp_info "Changing directory to $MAIN_REPO_DIR..."
    cd "$MAIN_REPO_DIR"
    return 0
fi

lp_branch_vars "$BRANCH"

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Worktree '$WORKTREE_DIR' does not exist."
    return 1
fi

lp_info "Changing directory to $WORKTREE_DIR..."
cd "$WORKTREE_DIR"
