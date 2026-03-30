#!/bin/bash
# Usage: lp git update-ee [-v]

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Update the ee branch in the EE repository by pulling from upstream and pushing to origin."
    echo ""
    echo "Usage: lp git update-ee [-v]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp git update-ee"
    exit 0
fi

VERBOSE=0
if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
    VERBOSE=1
fi

# Load config to get EE_REPO_DIR
source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

lp_step 1 5 "Navigating to EE repository: $EE_REPO_DIR"
cd "$EE_REPO_DIR" || exit 1

lp_step 2 5 "Checking out ee branch"
lp_run git checkout ee

lp_step 3 5 "Fetching all remotes"
lp_run git fetch --all

lp_step 4 5 "Pulling from upstream ee"
lp_run git pull upstream ee

lp_step 5 5 "Pushing to origin ee"
lp_run git push origin ee

lp_success "Successfully updated ee branch."
