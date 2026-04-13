#!/bin/bash
# commands/portal/sample.sh — Interact with liferay-sample-workspace elements.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

usage() {
    echo "Interact with liferay-sample-workspace elements."
    echo ""
    echo "Usage: lp portal sample [options] [branch]"
    echo ""
    echo "Options:"
    echo "  -c, --client-extension [pattern]  Deploy matching client extensions (or list all if no pattern)"
    echo "  -v, --verbose                     Show full gradle output"
    echo "  -h, --help                        Show this help"
    echo ""
    echo "Examples:"
    echo "  lp portal sample -c my-extension"
    echo "  lp portal sample -c -v"
    echo "  lp portal sample -c master"
}

if [[ "$#" -eq 0 ]]; then
    usage
    return 0 2>/dev/null || exit 0
fi

CET_PATTERN=""
LIST_ONLY=0
BRANCH=""
VERBOSE=0

# Source config early to help distinguish between patterns and branches
source "$_LP_SCRIPTS_DIR/config.sh" || return 1 2>/dev/null || exit 1

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--client-extension)
            if [[ -n "$2" && "$2" != -* ]]; then
                if [[ "$#" -eq 2 ]]; then
                    is_branch=0
                    check_wt=""
                    if [[ "$2" == "master" ]]; then
                        check_wt="$MAIN_REPO_DIR"
                    elif [[ "$2" == "ee" ]]; then
                        check_wt="$EE_REPO_DIR"
                    else
                        check_wt="${BASE_PROJECT_DIR}/${MAIN_REPO_NAME}-$2"
                    fi
                    
                    if [[ -n "$check_wt" && -d "$check_wt" ]]; then
                        is_branch=1
                    fi

                    if [[ "$is_branch" -eq 1 ]]; then
                        CET_PATTERN="*"
                        LIST_ONLY=1
                        shift 1
                    else
                        CET_PATTERN="$2"
                        shift 2
                    fi
                else
                    CET_PATTERN="$2"
                    shift 2
                fi
            else
                CET_PATTERN="*"
                LIST_ONLY=1
                shift 1
            fi
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            return 0 2>/dev/null || exit 0
            ;;
        -*)
            lp_error "Error: Unknown option: $1"
            usage
            return 1 2>/dev/null || exit 1
            ;;
        *)
            if [[ -z "$BRANCH" ]]; then
                BRANCH="$1"
            else
                lp_error "Error: Multiple branches specified: $BRANCH and $1"
                usage
                return 1 2>/dev/null || exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$CET_PATTERN" ]]; then
    return 0 2>/dev/null || exit 0
fi

# 1. Determine branch and worktree
if [[ -z "$BRANCH" ]]; then
    if [[ -n "$LP_WORKTREE_REFERENCE_BRANCH" ]]; then
        BRANCH="$LP_WORKTREE_REFERENCE_BRANCH"
        lp_branch_vars "$BRANCH"
    elif lp_detect_worktree; then
        BRANCH="$LP_DETECTED_BRANCH"
        WORKTREE_DIR="$LP_DETECTED_WORKTREE_DIR"
    else
        BRANCH="master"
        lp_branch_vars "$BRANCH"
    fi
else
    lp_branch_vars "$BRANCH"
fi

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Error: Worktree directory does not exist: $WORKTREE_DIR"
    return 1 2>/dev/null || exit 1
fi

WORKSPACE_PATH="$WORKTREE_DIR/workspaces/liferay-sample-workspace"

if [[ ! -d "$WORKSPACE_PATH" ]]; then
    lp_error "Error: liferay-sample-workspace not found at $WORKSPACE_PATH"
    return 1 2>/dev/null || exit 1
fi

CET_BASE_DIR="$WORKSPACE_PATH/client-extensions"
if [[ ! -d "$CET_BASE_DIR" ]]; then
    lp_error "Error: client-extensions directory not found at $CET_BASE_DIR"
    return 1 2>/dev/null || exit 1
fi

SEARCH_PATTERN="$CET_PATTERN"
if [[ "$SEARCH_PATTERN" != "*" && "$SEARCH_PATTERN" != *"*"* ]]; then
    SEARCH_PATTERN="*${SEARCH_PATTERN}*"
fi

MATCHES=()
while IFS= read -r -d '' dir; do
    MATCHES+=("$dir")
done < <(find "$CET_BASE_DIR" -maxdepth 1 -mindepth 1 -type d -iname "$SEARCH_PATTERN" -print0)

if [[ ${#MATCHES[@]} -eq 0 ]]; then
    lp_error "Error: No client extensions matching '$CET_PATTERN' found in $CET_BASE_DIR"
    return 1 2>/dev/null || exit 1
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
    lp_info "Available client extensions in $BRANCH:"
    IFS=$'\n' SORTED_MATCHES=($(sort <<<"${MATCHES[*]}"))
    unset IFS
    for CET_DIR in "${SORTED_MATCHES[@]}"; do
        echo "  - $(basename "$CET_DIR")"
    done
    return 0 2>/dev/null || exit 0
fi

# 2. Modify gradle.properties
BUNDLE_DIR="$BUNDLES_DIR/$BRANCH"
GRADLE_PROPERTIES="$WORKSPACE_PATH/gradle.properties"

HAD_GRADLE_PROPERTIES=0
if [[ -f "$GRADLE_PROPERTIES" ]]; then
    HAD_GRADLE_PROPERTIES=1
fi

[[ "$VERBOSE" -eq 1 ]] && lp_info "Using bundle path: $BUNDLE_DIR"
[[ "$VERBOSE" -eq 1 ]] && lp_info "Target gradle.properties: $GRADLE_PROPERTIES"

TMP_GRADLE_PROPERTIES=$(mktemp)
if [[ "$HAD_GRADLE_PROPERTIES" -eq 1 ]]; then
    cat "$GRADLE_PROPERTIES" > "$TMP_GRADLE_PROPERTIES"
fi

cleanup() {
    [[ "$VERBOSE" -eq 1 ]] && lp_info "Rolling back $GRADLE_PROPERTIES changes..."
    if [[ "$HAD_GRADLE_PROPERTIES" -eq 1 ]]; then
        cat "$TMP_GRADLE_PROPERTIES" > "$GRADLE_PROPERTIES"
    else
        rm -f "$GRADLE_PROPERTIES"
    fi
    rm -f "$TMP_GRADLE_PROPERTIES"
}
trap cleanup EXIT

if [[ "$HAD_GRADLE_PROPERTIES" -eq 1 ]]; then
    sed -i "/^[[:space:]]*#[[:space:]]*liferay.workspace.home.dir[[:space:]]*=/d" "$GRADLE_PROPERTIES"
    sed -i "/^[[:space:]]*liferay.workspace.home.dir[[:space:]]*=/d" "$GRADLE_PROPERTIES"
fi

echo "liferay.workspace.home.dir=$BUNDLE_DIR" >> "$GRADLE_PROPERTIES"

# 4. Deploy matching client extensions
i=0
total=${#MATCHES[@]}
IFS=$'\n' SORTED_MATCHES=($(sort <<<"${MATCHES[*]}"))
unset IFS

for CET_DIR in "${SORTED_MATCHES[@]}"; do
    ((i++))
    CET_NAME=$(basename "$CET_DIR")
    lp_step "$i" "$total" "Deploying client extension: $CET_NAME"
    
    # Use lp_run to handle verbosity automatically
    (cd "$CET_DIR" && VERBOSE=$VERBOSE lp_run zsh -ic "gw deploy")
done

lp_success "Successfully deployed ${#MATCHES[@]} client extension(s)."
