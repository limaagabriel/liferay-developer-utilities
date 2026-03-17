#!/bin/bash
# Usage: lp worktree remove [-v] <branch>

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Remove a worktree and its bundle directory."
    echo ""
    echo "Usage: lp worktree remove [options] <branch>"
    echo ""
    echo "Options:"
    echo "  -b, --branch    Also delete the local branch"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp worktree remove main"
    echo "  lp worktree remove -b feature-xyz"
    exit 0
fi

VERBOSE=0
DELETE_BRANCH=0
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --branch|-b)  DELETE_BRANCH=1; shift ;;
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
    lp_error "Cannot remove the master branch."
    exit 1
fi

lp_branch_vars "$BRANCH"

if [[ "$DELETE_BRANCH" -eq 1 ]]; then
    read -p " Remove worktree '$WORKTREE_DIR', bundle '$BUNDLE_DIR' AND branch '$BRANCH'? [y/N] " confirm
else
    read -p " Remove worktree '$WORKTREE_DIR' and bundle '$BUNDLE_DIR'? [y/N] " confirm
fi

if [[ "$confirm" != "y" ]]; then
    lp_info "Aborted."
    exit 0
fi

TOTAL_STEPS=2
[[ "$DELETE_BRANCH" -eq 1 ]] && TOTAL_STEPS=3

lp_step 1 $TOTAL_STEPS "Removing worktree"
lp_run git -C "$MAIN_REPO_DIR" worktree remove "$WORKTREE_DIR" --force

lp_step 2 $TOTAL_STEPS "Removing bundle directory"
lp_run rm -rf "$BUNDLE_DIR"

if [[ "$DELETE_BRANCH" -eq 1 ]]; then
    lp_step 3 $TOTAL_STEPS "Deleting local branch '$BRANCH'"
    lp_run git -C "$MAIN_REPO_DIR" branch -D "$BRANCH"
fi

lp_success "Done!"
