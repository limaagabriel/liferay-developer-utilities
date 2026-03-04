#!/bin/bash
# Usage: lp worktree add [-r <remote-name>] <branch-name>

set -e

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh"

REMOTE=""

while getopts "r:" opt; do
    case $opt in
        r) REMOTE="$OPTARG" ;;
        *) echo "Usage: lp worktree add [-r <remote-name>] <branch-name>"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

BRANCH=${1}

if [ -z "$BRANCH" ]; then
    echo "Usage: lp worktree add [-r <remote-name>] <branch-name>"
    exit 1
fi

lp_branch_vars "$BRANCH"

if [ -n "$REMOTE" ]; then
    REMOTE_BRANCH="$REMOTE/$BRANCH"
    echo "Creating worktree for branch '$BRANCH' from remote '$REMOTE_BRANCH'..."
    git -C "$MAIN_REPO_DIR" worktree add --track -b "$BRANCH" "$WORKTREE_DIR" "$REMOTE_BRANCH"
else
    echo "Creating worktree for branch '$BRANCH'..."
    git -C "$MAIN_REPO_DIR" worktree add -b "$BRANCH" "$WORKTREE_DIR"
fi

echo "Creating app.server.me.properties..."
cat > "$WORKTREE_DIR/app.server.me.properties" <<EOF
app.server.parent.dir=$BUNDLE_DIR
EOF

echo "Done! Worktree ready at $WORKTREE_DIR"
echo "Tip: run 'lp worktree cd $BRANCH' to navigate there."
