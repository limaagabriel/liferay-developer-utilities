#!/bin/bash
# Usage: lp git remove-remote [-v] <name>

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Remove a git remote from the master worktree."
    echo ""
    echo "Usage: lp git remove-remote [-v] <name>"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp git remove-remote upstream"
    exit 0
fi

VERBOSE=0
NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            lp_error "Usage: lp git remove-remote [-v] <name>"
            exit 1
            ;;
        *)
            NAME="$1"
            shift
            ;;
    esac
done

if [[ -z "$NAME" ]]; then
    lp_error "Error: Remote name is required."
    lp_error "Usage: lp git remove-remote [-v] <name>"
    exit 1
fi

# Load config to get MAIN_REPO_DIR
source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

lp_step 1 2 "Navigating to master worktree: $MAIN_REPO_DIR"
cd "$MAIN_REPO_DIR" || exit 1

lp_step 2 2 "Checking if remote '$NAME' exists"
if git remote | grep -q "^$NAME$"; then
    lp_run git remote remove "$NAME"
    lp_success "Remote '$NAME' removed."
else
    lp_info "Remote '$NAME' does not exist. Nothing to do."
fi
