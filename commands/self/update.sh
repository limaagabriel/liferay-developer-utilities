#!/bin/bash
# commands/self/update.sh — Update the lp tool itself.
#
# This script performs a git pull in the lp script directory.

# Help
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: lp self update [options]"
    echo ""
    echo "Update the lp tool by pulling the latest changes from its repository."
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    exit 0
fi

source "$_LP_SCRIPTS_DIR/lib/output.sh"

# Parse options
VERBOSE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose) VERBOSE=1; shift ;;
        *) shift ;;
    esac
done

if [[ ! -d "$_LP_SCRIPTS_DIR/.git" ]]; then
    lp_error "Error: $_LP_SCRIPTS_DIR is not a git repository. Cannot update."
    exit 1
fi

lp_step 1 1 "Pulling latest changes in $_LP_SCRIPTS_DIR"
cd "$_LP_SCRIPTS_DIR"
if [[ $VERBOSE -eq 1 ]]; then
    git pull
else
    git pull >/dev/null 2>&1
fi

if [[ $? -eq 0 ]]; then
    lp_success "lp has been updated successfully."
else
    lp_error "Failed to update lp."
    exit 1
fi
