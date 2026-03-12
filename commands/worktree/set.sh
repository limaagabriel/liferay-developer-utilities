#!/bin/bash
# Usage: source lp worktree set <branch-name>
# Sets the reference branch for the current session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"
source "$_LP_SCRIPTS_DIR/config.sh" || return 1 2>/dev/null || exit 1

BRANCH="$1"

if [[ -z "$BRANCH" ]]; then
    if lp_detect_worktree; then
        BRANCH="$LP_DETECTED_BRANCH"
    else
        lp_error "Error: Not currently in a worktree. Please provide a branch name."
        lp_error "Usage: lp worktree set [branch-name]"
        return 1 2>/dev/null || exit 1
    fi
fi

export LP_WORKTREE_REFERENCE_BRANCH="$BRANCH"
lp_info "Reference branch set to: $LP_WORKTREE_REFERENCE_BRANCH"
