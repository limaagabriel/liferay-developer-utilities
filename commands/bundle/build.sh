#!/bin/bash
# Usage: lp bundle build [-q] [branch]
# If no branch is given, uses the current directory.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Build the portal bundle from the worktree."
    echo ""
    echo "Usage: lp bundle build [-q] [-y] [-s] [branch]"
    echo ""
    echo "Options:"
    echo "  -q, --quiet             Hide full ant/git output (unless error)"
    echo "  -y, --yes               Skip confirmation for deleting existing bundle"
    echo "  -s, --skip-if-exists    Skip build if bundle directory already exists"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  lp bundle build main"
    echo "  lp bundle build -q main"
    echo "  lp bundle build -y main"
    echo "  lp bundle build -s main"
    echo "  lp bundle build           # uses current directory"
    exit 0
fi

VERBOSE=1
ASSUME_YES=0
SKIP_IF_EXISTS=0
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quiet|-q)           VERBOSE=0; shift ;;
        --yes|-y)             ASSUME_YES=1; shift ;;
        --skip-if-exists|-s)  SKIP_IF_EXISTS=1; shift ;;
        --help|-h)            shift ;;
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

TOTAL_STEPS=2
STEP=1

if [[ -d "$BUNDLE_DIR" ]]; then
    if [[ $SKIP_IF_EXISTS -eq 1 ]]; then
        lp_info "Bundle directory '$BUNDLE_DIR' already exists. Skipping build (-s)."
        exit 0
    fi
    if [[ $ASSUME_YES -eq 0 ]]; then
        read -p " Bundle directory '$BUNDLE_DIR' already exists. Delete and rebuild? [y/N] " confirm
        if [[ "$confirm" != "y" ]]; then
            lp_info "Aborted."
            exit 0
        fi
    fi
    TOTAL_STEPS=3
    lp_step $((STEP++)) $TOTAL_STEPS "Removing bundle directory '$BUNDLE_DIR'"
    lp_run rm -rf "$BUNDLE_DIR"
    mkdir -p "$BUNDLE_DIR"
fi

cd "$WORKTREE_DIR"

lp_step $((STEP++)) $TOTAL_STEPS "Running ant setup-profile-dxp"
lp_run ant setup-profile-dxp

lp_step $((STEP++)) $TOTAL_STEPS "Running ant all"
lp_run ant all

lp_success "Bundle built at '$BUNDLE_DIR'."
