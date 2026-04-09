#!/bin/bash
# Usage: source lp worktree root [branch]
# Changes the current directory to the root of the specified or active worktree.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Change the current directory to the root of a worktree."
    echo ""
    echo "Usage: lp worktree root [branch]"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "If no branch is provided, it uses the reference branch or detects"
    echo "the current worktree."
    echo ""
    echo "Examples:"
    echo "  lp worktree root"
    echo "  lp worktree root my-feature"
    return 0 2>/dev/null || exit 0
fi

source "$_LP_SCRIPTS_DIR/config.sh" || return 1 2>/dev/null || exit 1

BRANCH="$1"

# 1. If no parameter, try reference branch
if [[ -z "$BRANCH" ]]; then
    BRANCH="$LP_WORKTREE_REFERENCE_BRANCH"
fi

# 2. If still no branch, try detecting current worktree
if [[ -z "$BRANCH" ]]; then
    if lp_detect_worktree; then
        BRANCH="$LP_DETECTED_BRANCH"
    fi
fi

# 3. Default to master
BRANCH="${BRANCH:-master}"

lp_branch_vars "$BRANCH"

if [[ -d "$WORKTREE_DIR" ]]; then
    cd "$WORKTREE_DIR" || return 1 2>/dev/null || exit 1
    lp_info "Moved to worktree root: $WORKTREE_DIR ($BRANCH)"
else
    lp_error "Error: Worktree directory '$WORKTREE_DIR' does not exist for branch '$BRANCH'."
    return 1 2>/dev/null || exit 1
fi
