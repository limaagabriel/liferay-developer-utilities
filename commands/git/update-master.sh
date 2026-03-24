#!/bin/bash
# Usage: lp git update-master [-v]

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Update the master branch in the master worktree by pulling from upstream and pushing to origin."
    echo ""
    echo "Usage: lp git update-master [-v]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp git update-master"
    exit 0
fi

VERBOSE=0
if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
    VERBOSE=1
fi

# Load config to get MAIN_REPO_DIR
source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

lp_step 1 5 "Navigating to master worktree: $MAIN_REPO_DIR"
cd "$MAIN_REPO_DIR" || exit 1

lp_step 2 5 "Checking out master branch"
lp_run git checkout master

lp_step 3 5 "Fetching all remotes"
lp_run git fetch --all

lp_step 4 5 "Pulling from upstream master"
lp_run git pull upstream master

lp_step 5 5 "Pushing to origin master"
lp_run git push origin master

lp_success "Successfully updated master branch."
