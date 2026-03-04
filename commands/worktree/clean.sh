#!/bin/bash
# Usage: lp worktree clean [-v] [branch]
# If no branch is given, uses the current directory.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Clean a worktree by running ant clean and git clean."
    echo ""
    echo "Usage: lp worktree clean [-v] [branch]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full ant/git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree clean main"
    echo "  lp worktree clean           # uses current directory"
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
    WORKTREE_DIR=$(pwd)
else
    lp_branch_vars "$BRANCH"
fi

cd "$WORKTREE_DIR"

lp_info "Cleaning worktree at '$WORKTREE_DIR'..."
lp_step 1 2 "Running ant clean"
lp_run ant clean

lp_step 2 2 "Cleaning git artifacts"
lp_run git clean -fdx -e .idea -e "*.iml" -e app.server.me.properties -e build.me.properties

lp_success "Worktree cleaned successfully."
