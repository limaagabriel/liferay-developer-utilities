#!/bin/bash
# Helper script for lp git bisect run
# Usage: lp git bisect-step <branch>

BRANCH=$1
if [[ -z "$BRANCH" ]]; then
    echo "Error: Branch name is required for bisect-step."
    exit 1
fi

# Source libs using the exported _LP_SCRIPTS_DIR
source "$_LP_SCRIPTS_DIR/lib/output.sh"
source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

lp_branch_vars "$BRANCH"

SESSION_NAME="lp-bisect-$BRANCH"
CURRENT_COMMIT=$(git rev-parse --short HEAD)

# Display progress
echo ""
lp_info "------------------------------------------------------------"
lp_info "Bisection Step: Testing commit $CURRENT_COMMIT"
# git bisect visualize --oneline can show the range. 
# We'll use git bisect log to see how many steps are left.
git bisect log | grep -v "^#" | head -n 1
echo ""

# Kill existing bisect session for this branch
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    lp_step 1 3 "Cleaning up existing tmux session '$SESSION_NAME'"
    tmux kill-session -t "$SESSION_NAME"
fi

# Remove bundle directory (user request)
if [[ -d "$BUNDLE_DIR" ]]; then
    lp_step 2 3 "Removing existing bundle directory '$BUNDLE_DIR'"
    rm -rf "$BUNDLE_DIR"
fi

lp_step 3 3 "Starting build and bundle in tmux session '$SESSION_NAME'"
lp_info "Command: lp bundle build -y && lp bundle start"

# Use the user's shell to ensure lp commands are available if sourced in .zshrc/.bashrc
# Or we can use the absolute path to lp.sh to be safer.
USER_SHELL="${SHELL:-bash}"
tmux new-session -d -s "$SESSION_NAME" -c "$WORKTREE_DIR" "$USER_SHELL -ic 'source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp bundle build -y && lp bundle start; exec $USER_SHELL'"

lp_info "Monitoring the build:"
lp_info "  tmux attach -t $SESSION_NAME"
lp_info ""
lp_info "Once the portal is ready, provide your verdict below."

while true; do
    read -p "Result for $CURRENT_COMMIT? [g]ood / [b]ad / [s]kip: " choice
    case "$choice" in
        g|good)
            lp_success "Marking $CURRENT_COMMIT as GOOD"
            exit 0
            ;;
        b|bad)
            lp_error "Marking $CURRENT_COMMIT as BAD"
            exit 1
            ;;
        s|skip)
            lp_info "Skipping $CURRENT_COMMIT"
            exit 125
            ;;
        *)
            lp_info "Invalid choice. Please enter g, b, or s."
            ;;
    esac
done
