#!/bin/bash
# Usage: lp worktree rebuild [-v] [branch]
# If no branch is given, uses the current directory.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Delete the bundle and rebuild it from the worktree."
    echo ""
    echo "Usage: lp worktree rebuild [-v] [branch]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose   Show full ant/git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree rebuild main"
    echo "  lp worktree rebuild --verbose main"
    echo "  lp worktree rebuild           # uses current directory"
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

if [[ "$BRANCH" == "master" ]]; then
    WORKTREE_DIR="$MAIN_REPO_DIR"
else
    lp_branch_vars "$BRANCH"
fi

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Worktree '$WORKTREE_DIR' does not exist."
    exit 1
fi

PROPS_FILE=$WORKTREE_DIR/app.server.me.properties

if [[ ! -f "$PROPS_FILE" ]]; then
    lp_error "app.server.me.properties not found at '$WORKTREE_DIR'."
    exit 1
fi

BUNDLE_DIR=$(grep 'app.server.parent.dir' "$PROPS_FILE" | cut -d'=' -f2)

if [[ -z "$BUNDLE_DIR" ]]; then
    lp_error "Could not find bundle directory for worktree '$WORKTREE_DIR'."
    exit 1
fi

read -p "This will delete '$BUNDLE_DIR' and rebuild. Continue? [y/N] " confirm
if [[ "$confirm" != "y" ]]; then
    lp_info "Aborted."
    exit 0
fi

lp_step 1 3 "Removing bundle directory '$BUNDLE_DIR'"
lp_run rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"

cd "$WORKTREE_DIR"

lp_step 2 3 "Running ant setup-profile-dxp"
lp_run ant setup-profile-dxp

lp_step 3 3 "Running ant all"
lp_run ant all

lp_success "Bundle rebuilt at '$BUNDLE_DIR'."
