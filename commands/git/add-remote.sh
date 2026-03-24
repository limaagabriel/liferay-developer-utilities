#!/bin/bash
# Usage: lp git add-remote [-v] <name> <url>

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Add a new git remote to the master worktree and fetch all remotes."
    echo ""
    echo "Usage: lp git add-remote [-v] <name> <url>"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp git add-remote upstream https://github.com/liferay/liferay-portal.git"
    exit 0
fi

VERBOSE=0
NAME=""
URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            lp_error "Usage: lp git add-remote [-v] <name> <url>"
            exit 1
            ;;
        *)
            if [[ -z "$NAME" ]]; then
                NAME="$1"
            elif [[ -z "$URL" ]]; then
                URL="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$NAME" || -z "$URL" ]]; then
    lp_error "Error: Both remote name and URL are required."
    lp_error "Usage: lp git add-remote [-v] <name> <url>"
    exit 1
fi

# Load config to get MAIN_REPO_DIR
source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

lp_step 1 3 "Navigating to master worktree: $MAIN_REPO_DIR"
cd "$MAIN_REPO_DIR" || exit 1

lp_step 2 3 "Checking if remote '$NAME' exists"
if git remote | grep -q "^$NAME$"; then
    lp_info "Remote '$NAME' already exists. Skipping 'git remote add'."
else
    lp_run git remote add "$NAME" "$URL"
    lp_success "Remote '$NAME' added."
fi

lp_step 3 3 "Fetching all remotes"
lp_run git fetch --all

lp_success "Successfully added remote '$NAME' and fetched all."
