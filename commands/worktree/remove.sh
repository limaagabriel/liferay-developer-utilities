#!/bin/bash
# Usage: lp worktree remove [-v] <branch>

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Remove a worktree and its bundle directory."
    echo ""
    echo "Usage: lp worktree remove [-v] <branch>"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree remove main"
    exit 0
fi

VERBOSE=0
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh"

if [[ -z "$BRANCH" ]]; then
    lp_error "Usage: lp worktree remove [-v] <branch>"
    exit 1
fi

lp_branch_vars "$BRANCH"

read -p "Remove worktree '$WORKTREE_DIR' and bundle '$BUNDLE_DIR'? [y/N] " confirm
if [[ "$confirm" != "y" ]]; then
    lp_info "Aborted."
    exit 0
fi

lp_step 1 2 "Removing worktree"
lp_run git -C "$MAIN_REPO_DIR" worktree remove "$WORKTREE_DIR" --force

lp_step 2 2 "Removing bundle directory"
lp_run rm -rf "$BUNDLE_DIR"

lp_success "Done!"
