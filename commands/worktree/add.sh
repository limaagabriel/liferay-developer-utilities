#!/bin/bash
# Usage: lp worktree add [options] <branch>

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Add a new git worktree for a branch."
    echo ""
    echo "Usage: lp worktree add [options] <branch>"
    echo ""
    echo "Options:"
    echo "  -b, --base <branch>     Base branch to create from (defaults to master)"
    echo "  -r, --remote <remote>   Track from a remote branch"
    echo "  -c, --cd                Automatically 'lp worktree cd' after adding"
    echo "  -s, --session           Automatically 'lp session start' after adding (skips build)"
    echo "  -v, --verbose           Show full git output"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree add main"
    echo "  lp worktree add -b LPS-12345 feature-xyz"
    echo "  lp worktree add -r origin feature-xyz"
    echo "  lp worktree add -c feature-abc"
    echo "  lp worktree add -s feature-xyz"
    return 0 2>/dev/null || exit 0
fi

VERBOSE=0
BASE=""
REMOTE=""
BRANCH=""
AUTO_CD=0
AUTO_SESSION=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)  VERBOSE=1; shift ;;
        --base|-b)     BASE="$2"; shift 2 ;;
        --remote|-r)   REMOTE="$2"; shift 2 ;;
        --cd|-c)       AUTO_CD=1; shift ;;
        --session|-s)  AUTO_SESSION=1; shift ;;
        --help|-h)     shift ;;  # already handled above
        -*)
            lp_error "Unknown option: $1"
            lp_error "Usage: lp worktree add [options] <branch>"
            return 1 2>/dev/null || exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

source "$_LP_SCRIPTS_DIR/config.sh" || return 1 2>/dev/null || exit 1

if [[ -z "$BRANCH" ]]; then
    lp_error "Usage: lp worktree add [options] <branch>"
    return 1 2>/dev/null || exit 1
fi

# Check worktree limit
CURRENT_WORKTREE_COUNT=$(git -C "$MAIN_REPO_DIR" worktree list --porcelain | grep "^worktree" | wc -l)
if [[ $CURRENT_WORKTREE_COUNT -ge $WORKTREE_LIMIT ]]; then
    lp_info "Warning: You already have $CURRENT_WORKTREE_COUNT worktrees (limit is $WORKTREE_LIMIT)."
fi

lp_branch_vars "$BRANCH"

if [[ -n "$REMOTE" ]]; then
    REMOTE_BRANCH="$REMOTE/$BRANCH"
    lp_step 1 2 "Creating worktree for branch '$BRANCH' from remote '$REMOTE_BRANCH'"
    # Use -B to allow resetting the branch if it already exists
    lp_run git -C "$MAIN_REPO_DIR" worktree add --track -B "$BRANCH" "$WORKTREE_DIR" "$REMOTE_BRANCH"
else
    if git -C "$MAIN_REPO_DIR" show-ref --verify --quiet "refs/heads/$BRANCH"; then
        lp_step 1 2 "Creating worktree for existing branch '$BRANCH'"
        lp_run git -C "$MAIN_REPO_DIR" worktree add "$WORKTREE_DIR" "$BRANCH"
    else
        START_POINT="${BASE:-master}"
        lp_step 1 2 "Creating worktree for branch '$BRANCH' from '$START_POINT'"
        lp_run git -C "$MAIN_REPO_DIR" worktree add -b "$BRANCH" "$WORKTREE_DIR" "$START_POINT"
    fi
fi

lp_step 2 2 "Creating app.server.me.properties"
cat > "$WORKTREE_DIR/app.server.me.properties" <<EOF
app.server.parent.dir=$BUNDLE_DIR
EOF

lp_success "Worktree ready at $WORKTREE_DIR"

if [[ $AUTO_SESSION -eq 1 ]]; then
    lp_info "Automatically starting session for $BRANCH (skipping build)..."
    "$_LP_SCRIPTS_DIR/commands/session/start.sh" --no-build "$BRANCH"
fi

if [[ $AUTO_CD -eq 1 ]]; then
    lp_info "Automatically changing directory to $WORKTREE_DIR..."
    source "$_LP_SCRIPTS_DIR/commands/worktree/cd.sh" "$BRANCH"
else
    lp_info "Tip: run 'lp worktree cd $BRANCH' to navigate there."
fi
