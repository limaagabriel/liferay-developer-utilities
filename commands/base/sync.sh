#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "base" "sync" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    BRANCH=""
    ASSUME_YES=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)      ASSUME_YES=1; shift ;;
            --verbose|-v)  shift ;;
            --help|-h)     shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ -z "$BRANCH" ]]; then
                    BRANCH="$1"
                else
                    lp_error "Too many arguments: $1"
                    return 1 2>/dev/null || exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$BRANCH" ]]; then
        lp_resolve_branch || {
            lp_error "Specify a branch or run from inside a worktree."
            lp_error "Usage: lp base sync [<branch>]"
            return 1 2>/dev/null || exit 1
        }
    fi
}

read_bundle_base_meta() {
    BASE_NAME=$(_lp_bundle_meta_get "$BUNDLE_DIR" "LP_BASE_NAME")
    BASE_COMMIT_AT_CLONE=$(_lp_bundle_meta_get "$BUNDLE_DIR" "LP_BASE_COMMIT")

    if [[ -z "$BASE_NAME" ]]; then
        lp_error "Bundle '$BRANCH' was not built from a base."
        lp_error "Use 'lp bundle build $BRANCH --from-base <name>' to attach to one."
        return 1
    fi

    BASE_PATH="$BASE_BUNDLES_DIR/$BASE_NAME"
    if [[ ! -d "$BASE_PATH" ]]; then
        lp_error "Base bundle '$BASE_NAME' no longer exists at $BASE_PATH."
        lp_error "Recreate it: 'lp base build $BASE_NAME'"
        return 1
    fi

    CURRENT_BASE_COMMIT=$(_lp_bundle_meta_get "$BASE_PATH" "LP_BUNDLE_COMMIT")
    [[ -z "$CURRENT_BASE_COMMIT" ]] && CURRENT_BASE_COMMIT="unknown"
    [[ -z "$BASE_COMMIT_AT_CLONE" ]] && BASE_COMMIT_AT_CLONE="unknown"
    return 0
}

confirm_reclone() {
    [[ $ASSUME_YES -eq 1 ]] && return 0
    lp_confirm "Re-clone '$BRANCH' from updated base '$BASE_NAME'? This wipes the bundle (data, OSGi state, deploys)."
}

main() {
    parse_arguments "$@" || return $?

    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    [[ -d "$BUNDLE_DIR" ]] || {
        lp_error "Bundle for '$BRANCH' not found at $BUNDLE_DIR."
        lp_error "Run 'lp bundle build $BRANCH --from-base <name>' first."
        return 1
    }

    read_bundle_base_meta || return $?

    if [[ "$CURRENT_BASE_COMMIT" == "$BASE_COMMIT_AT_CLONE" && "$CURRENT_BASE_COMMIT" != "unknown" ]]; then
        lp_success "Bundle '$BRANCH' is in sync with base '$BASE_NAME' at ${CURRENT_BASE_COMMIT:0:7}."
        return 0
    fi

    lp_info "Base drift detected for '$BRANCH':"
    lp_info "  Bundle cloned from base at: ${BASE_COMMIT_AT_CLONE:0:7}"
    lp_info "  Base now points to:         ${CURRENT_BASE_COMMIT:0:7}"
    echo ""

    confirm_reclone || { lp_info "Aborted."; return 0; }

    "$_LP_SCRIPTS_DIR/commands/bundle/build.sh" --from-base "$BASE_NAME" -y "$BRANCH"
}

main "$@"
