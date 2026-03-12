#!/bin/bash
# Usage: source lp worktree set <branch-name>
# Sets the reference branch for the current session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ -z "$1" ]]; then
    lp_error "Usage: lp worktree set <branch-name>"
    return 1 2>/dev/null || exit 1
fi

export LP_WORKTREE_REFERENCE_BRANCH="$1"
lp_info "Reference branch set to: $LP_WORKTREE_REFERENCE_BRANCH"
