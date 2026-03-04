#!/bin/bash
# Usage: lp worktree code <branch-name>

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Open a worktree in VS Code."
    echo ""
    echo "Usage: lp worktree code <branch>"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree code main"
    exit 0
fi

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh" || exit 1

BRANCH=$1

if [[ -z "$BRANCH" ]]; then
    lp_error "Usage: lp worktree code <branch>"
    exit 1
fi

lp_branch_vars "$BRANCH"

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Worktree '$WORKTREE_DIR' does not exist."
    exit 1
fi

code "$WORKTREE_DIR"
