#!/bin/bash
# Usage: source lp worktree root
# Changes the current directory to the root of the active worktree.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Change the current directory to the root of the active worktree."
    echo ""
    echo "Usage: lp worktree root"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree root"
    return 0 2>/dev/null || exit 0
fi

source "$_LP_SCRIPTS_DIR/config.sh" || return 1 2>/dev/null || exit 1

if lp_detect_worktree; then
    cd "$LP_DETECTED_WORKTREE_DIR" || return 1 2>/dev/null || exit 1
    lp_info "Moved to worktree root: $LP_DETECTED_WORKTREE_DIR"
else
    lp_error "Error: Not currently in a worktree."
    return 1 2>/dev/null || exit 1
fi
