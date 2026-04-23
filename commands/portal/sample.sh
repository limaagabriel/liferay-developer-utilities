#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "portal" "sample" "$@"

parse_arguments() {
    CET_PATTERN="*"
    LIST_ONLY=0
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list|-l) LIST_ONLY=1; shift ;;
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ "$1" == *"*"* || -z "$BRANCH" ]]; then
                    if [[ "$1" == *"*"* ]]; then
                         CET_PATTERN="$1"
                    else
                         BRANCH="$1"
                    fi
                fi
                shift
                ;;
        esac
    done
}

validate_paths() {
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
}

find_matching_extensions() {
    local search_pattern="$CET_PATTERN"
    if [[ "$search_pattern" != "*" && "$search_pattern" != *"*"* ]]; then
        search_pattern="*${search_pattern}*"
    fi

    MATCHES=()
    while IFS= read -r -d '' dir; do
        MATCHES+=("$dir")
    done < <(find "$CET_BASE_DIR" -maxdepth 1 -mindepth 1 -type d -iname "$search_pattern" -print0)

    if [[ ${#MATCHES[@]} -eq 0 ]]; then
        lp_error "Error: No client extensions matching '$CET_PATTERN' found in $CET_BASE_DIR"
        return 1 2>/dev/null || exit 1
    fi
}

list_extensions() {
    lp_info "Available client extensions in $BRANCH:"
    IFS=$'\n' local sorted_matches=($(sort <<<"${MATCHES[*]}"))
    unset IFS
    for cet_dir in "${sorted_matches[@]}"; do
        echo "  - $(basename "$cet_dir")"
    done
}

configure_liferay_workspace() {
    BUNDLE_DIR="$BUNDLES_DIR/$BRANCH"
    local gradle_properties="$WORKSPACE_PATH/gradle.properties"

    HAD_GRADLE_PROPERTIES=0
    [[ -f "$gradle_properties" ]] && HAD_GRADLE_PROPERTIES=1

    TMP_GRADLE_PROPERTIES=$(mktemp)
    [[ "$HAD_GRADLE_PROPERTIES" -eq 1 ]] && cat "$gradle_properties" > "$TMP_GRADLE_PROPERTIES"

    trap cleanup EXIT

    if [[ "$HAD_GRADLE_PROPERTIES" -eq 1 ]]; then
        sed -i "/^[[:space:]]*#[[:space:]]*liferay.workspace.home.dir[[:space:]]*=/d" "$gradle_properties"
        sed -i "/^[[:space:]]*liferay.workspace.home.dir[[:space:]]*=/d" "$gradle_properties"
    fi

    echo "liferay.workspace.home.dir=$BUNDLE_DIR" >> "$gradle_properties"
}

cleanup() {
    local gradle_properties="$WORKSPACE_PATH/gradle.properties"
    if [[ "$HAD_GRADLE_PROPERTIES" -eq 1 ]]; then
        cat "$TMP_GRADLE_PROPERTIES" > "$gradle_properties"
    else
        rm -f "$gradle_properties"
    fi
    rm -f "$TMP_GRADLE_PROPERTIES"
}

deploy_extensions() {
    local total=${#MATCHES[@]}
    local i=0
    
    IFS=$'\n' local sorted_matches=($(sort <<<"${MATCHES[*]}"))
    unset IFS

    for cet_dir in "${sorted_matches[@]}"; do
        ((i++))
        local cet_name=$(basename "$cet_dir")
        lp_step "$i" "$total" "Deploying client extension: $cet_name"
        (cd "$cet_dir" && lp_run zsh -ic "gw deploy")
    done

    lp_success "Successfully deployed $total client extension(s)."
}

main() {
    parse_arguments "$@" || return 1 2>/dev/null || exit 1
    [[ -z "$CET_PATTERN" ]] && return 0
    
    lp_resolve_branch --reference --default-master --vars
    lp_validate_worktree
    validate_paths || return 1 2>/dev/null || exit 1
    find_matching_extensions || return 1 2>/dev/null || exit 1
    
    if [[ "$LIST_ONLY" -eq 1 ]]; then
        list_extensions
        return 0
    fi

    configure_liferay_workspace
    deploy_extensions
}

main "$@"
