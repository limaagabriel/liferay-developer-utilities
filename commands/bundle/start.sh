#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "start" "$@"

BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) shift ;; # Already handled by lp_init_command
        -*)
            lp_error "Unknown option: $1"
            return 1 2>/dev/null || exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
BRANCH="${BRANCH:-master}"

lp_branch_vars "$BRANCH"
lp_validate_worktree || return $?
lp_load_bundle_dir || return $?

cd "$WORKTREE_DIR"

lp_step 1 1 "Starting server from $BUNDLE_DIR"

# Catalina output is always streamed regardless of --verbose
cd "$BUNDLE_DIR"/tomcat-*/bin
./catalina.sh jpda run
