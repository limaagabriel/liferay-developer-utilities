#!/bin/bash
# Usage: lp worktree start [-b] [-v] [branch]
# If no branch is given, uses the current directory.
# -b: run the build step (skipped by default)

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Start the Liferay server for a worktree."
    echo ""
    echo "Usage: lp worktree start [-b] [-v] [branch]"
    echo ""
    echo "Options:"
    echo "  -b              Run the build step before starting"
    echo "  -v, --verbose   Show full ant output (catalina log always shown)"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree start main"
    echo "  lp worktree start -b main"
    echo "  lp worktree start           # uses current directory"
    exit 0
fi

VERBOSE=0
BUILD=false
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        -b)           BUILD=true; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

source "$(dirname "${BASH_SOURCE[0]}")/../../config.sh"

if [[ -z "$BRANCH" ]]; then
    WORKTREE_DIR=$(pwd)
else
    lp_branch_vars "$BRANCH"
fi

BUNDLE_DIR=$(grep 'app.server.parent.dir' "$WORKTREE_DIR/app.server.me.properties" | cut -d'=' -f2)

cd "$WORKTREE_DIR"

if [[ "$BUILD" = true ]]; then
    lp_step 1 4 "Removing bundle directory '$BUNDLE_DIR'"
    lp_run rm -rf "$BUNDLE_DIR"

    lp_step 2 4 "Running ant setup-profile-dxp"
    lp_run ant setup-profile-dxp

    lp_step 3 4 "Running ant all"
    lp_run ant all

    lp_step 4 4 "Starting server from $BUNDLE_DIR"
else
    lp_step 1 1 "Starting server from $BUNDLE_DIR"
fi

# Catalina output is always streamed regardless of --verbose
cd "$BUNDLE_DIR"/tomcat-*/bin
./catalina.sh jpda run
