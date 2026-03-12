#!/bin/bash
# Usage: lp worktree add [-r <remote>] [-v] <branch>

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Add a new git worktree for a branch."
    echo ""
    echo "Usage: lp worktree add [-r <remote>] [-v] <branch>"
    echo ""
    echo "Options:"
    echo "  -r, --remote <remote>   Track from a remote branch"
    echo "  -v, --verbose           Show full git output"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree add main"
    echo "  lp worktree add -r origin feature-xyz"
    exit 0
fi

VERBOSE=0
REMOTE=""
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --remote|-r)  REMOTE="$2"; shift 2 ;;
        --help|-h)    shift ;;  # already handled above
        -*)
            lp_error "Unknown option: $1"
            lp_error "Usage: lp worktree add [-r <remote>] [-v] <branch>"
            exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh" || exit 1

if [[ -z "$BRANCH" ]]; then
    lp_error "Usage: lp worktree add [-r <remote>] [-v] <branch>"
    exit 1
fi

lp_branch_vars "$BRANCH"

if [[ -n "$REMOTE" ]]; then
    REMOTE_BRANCH="$REMOTE/$BRANCH"
    lp_step 1 2 "Creating worktree for branch '$BRANCH' from remote '$REMOTE_BRANCH'"
    git -C "$MAIN_REPO_DIR" worktree add --track -b "$BRANCH" "$WORKTREE_DIR" "$REMOTE_BRANCH"
else
    lp_step 1 2 "Creating worktree for branch '$BRANCH'"
    lp_run git -C "$MAIN_REPO_DIR" worktree add -b "$BRANCH" "$WORKTREE_DIR"
fi

lp_step 2 2 "Creating app.server.me.properties"
cat > "$WORKTREE_DIR/app.server.me.properties" <<EOF
app.server.parent.dir=$BUNDLE_DIR
EOF

lp_success "Worktree ready at $WORKTREE_DIR"
lp_info "Tip: run 'lp worktree cd $BRANCH' to navigate there."
