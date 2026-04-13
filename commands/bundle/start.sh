#!/bin/bash
# Usage: lp bundle start [-v] [branch]
# If no branch is given, uses the current directory.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Start the Liferay server for a bundle."
    echo ""
    echo "Usage: lp bundle start [-v] [branch]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full ant output (catalina log always shown)"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp bundle start main"
    echo "  lp bundle start           # uses current directory"
    exit 0
fi

VERBOSE=0
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
BRANCH="${BRANCH:-master}"

lp_branch_vars "$BRANCH"

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Worktree '$WORKTREE_DIR' does not exist."
    exit 1
fi

BUNDLE_DIR=$(grep 'app.server.parent.dir' "$WORKTREE_DIR/app.server.${LIFERAY_USER}.properties" | cut -d'=' -f2)

if [[ -z "$BUNDLE_DIR" ]]; then
    lp_error "Could not find bundle directory for worktree '$WORKTREE_DIR'."
    exit 1
fi

cd "$WORKTREE_DIR"

lp_step 1 1 "Starting server from $BUNDLE_DIR"

# Catalina output is always streamed regardless of --verbose
cd "$BUNDLE_DIR"/tomcat-*/bin
./catalina.sh jpda run
