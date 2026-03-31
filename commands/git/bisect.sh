#!/bin/bash
# Usage: lp git bisect -g <good> -b <bad> [branch]

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Automate the Liferay Portal bisection process."
    echo ""
    echo "Usage: lp git bisect -g <good> -b <bad> [branch]"
    echo ""
    echo "Options:"
    echo "  -g, --good <commit>   The last known good commit (required)"
    echo "  -b, --bad <commit>    The first known bad commit (required)"
    echo "  -h, --help            Show this help"
    echo ""
    echo "This command will use 'git bisect run' with an automated script that"
    echo "builds and starts the bundle in a tmux session for each iteration."
    echo ""
    echo "Examples:"
    echo "  lp git bisect -g v7.4.3.100-ga100 -b master"
    echo "  lp git bisect -g 4a5b6c7 -b 1a2b3c4 my-fix-branch"
    exit 0
fi

GOOD_COMMIT=""
BAD_COMMIT=""
BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --good|-g) GOOD_COMMIT="$2"; shift 2 ;;
        --bad|-b)  BAD_COMMIT="$2"; shift 2 ;;
        --help|-h) shift ;; # handled above
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *)
            if [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            else
                lp_error "Too many arguments: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$GOOD_COMMIT" || -z "$BAD_COMMIT" ]]; then
    lp_error "Error: Both --good and --bad commits are required."
    lp_error "Usage: lp git bisect -g <good> -b <bad> [branch]"
    exit 1
fi

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

if [[ -z "$BRANCH" ]]; then
    if lp_detect_worktree; then
        BRANCH="$LP_DETECTED_BRANCH"
    else
        BRANCH="${LP_WORKTREE_REFERENCE_BRANCH:-master}"
    fi
fi

lp_branch_vars "$BRANCH"

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Worktree '$WORKTREE_DIR' does not exist."
    exit 1
fi

lp_step 1 3 "Navigating to worktree: $WORKTREE_DIR"
cd "$WORKTREE_DIR" || exit 1

lp_step 2 3 "Initializing git bisect from $GOOD_COMMIT to $BAD_COMMIT"
git bisect start "$BAD_COMMIT" "$GOOD_COMMIT"

lp_step 3 3 "Starting git bisect run"
lp_info "For each iteration, the bundle will be built and started in tmux."
lp_info "Tmux session name: lp-bisect-$BRANCH"

# Export variables needed by the step script
export _LP_SCRIPTS_DIR="$_LP_SCRIPTS_DIR"

git bisect run "$_LP_SCRIPTS_DIR/commands/git/bisect-step.sh" "$BRANCH"

lp_success "Git bisect complete."
git bisect log
