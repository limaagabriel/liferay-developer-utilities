#!/bin/bash
# Usage: lp modules deploy [options] [module_path]
# Run gw deploy in a module or all changed modules.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

usage() {
    echo "Run gw deploy in a module or all changed modules."
    echo ""
    echo "Usage: lp modules deploy [options] [module_path]"
    echo ""
    echo "Options:"
    echo "  -c, --changed      Deploy all modules changed in the current branch"
    echo "  -b, --base <branch> Base branch to compare against for --changed (default: master)"
    echo "  -h, --help         Show this help"
    echo ""
    echo "Examples:"
    echo "  lp modules deploy                        # deploy current directory"
    echo "  lp modules deploy modules/apps/portal-workflow/portal-workflow-api"
    echo "  lp modules deploy --changed              # deploy all changed modules"
    echo "  lp modules deploy -c -b ee               # deploy changed modules compared to ee"
}

CHANGED=0
BASE_BRANCH="master"
MODULE_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--changed)
            CHANGED=1
            shift
            ;;
        -b|--base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            return 0 2>/dev/null || exit 0
            ;;
        -*)
            lp_error "Error: Unknown option $1"
            usage
            exit 1
            ;;
        *)
            MODULE_PATH="$1"
            shift
            ;;
    esac
done

# If -c is provided, we ignore MODULE_PATH
if [[ $CHANGED -eq 1 ]]; then
    lp_info "Identifying changed modules compared to '$BASE_BRANCH'..."
    
    # We use lp modules changed to get the list
    CHANGED_LIST=$("$_LP_SCRIPTS_DIR/commands/modules/changed.sh" "$BASE_BRANCH")
    
    if [[ -z "$CHANGED_LIST" || "$CHANGED_LIST" == "No changed modules found"* ]]; then
        lp_info "No changed modules to deploy."
        exit 0
    fi

    ORIGINAL_PWD=$(pwd)
    # Get top level to ensure paths are correct
    GIT_ROOT=$(git rev-parse --show-toplevel)

    for module in $CHANGED_LIST; do
        lp_step "Deploying" "$module"
        cd "$GIT_ROOT/$module" || continue
        # We call portal/gw.sh directly
        "$_LP_SCRIPTS_DIR/commands/portal/gw.sh" deploy
        cd "$ORIGINAL_PWD" || exit 1
    done
elif [[ -n "$MODULE_PATH" ]]; then
    if [[ ! -d "$MODULE_PATH" ]]; then
        lp_error "Error: Directory '$MODULE_PATH' does not exist."
        exit 1
    fi
    cd "$MODULE_PATH" || exit 1
    "$_LP_SCRIPTS_DIR/commands/portal/gw.sh" deploy
else
    # Deploy current directory
    "$_LP_SCRIPTS_DIR/commands/portal/gw.sh" deploy
fi
