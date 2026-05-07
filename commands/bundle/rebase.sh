#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "rebase" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    BRANCH=""
    NEW_BASE=""
    ASSUME_YES=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from-base|-f)
                if [[ -n "$2" && "$2" != -* ]]; then
                    NEW_BASE="$2"; shift 2
                else
                    lp_error "Option $1 requires a base bundle name."
                    return 1 2>/dev/null || exit 1
                fi
                ;;
            --yes|-y)     ASSUME_YES=1; shift ;;
            --verbose|-v) shift ;;
            --help|-h)    shift ;;
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

    if [[ -z "$NEW_BASE" ]]; then
        lp_error "Usage: lp bundle rebase [<branch>] --from-base <name>"
        return 1 2>/dev/null || exit 1
    fi

    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"
}

read_current_source() {
    CURRENT_BASE=$(_lp_bundle_meta_get "$BUNDLE_DIR" "LP_BASE_NAME")
    CURRENT_BASE_COMMIT=$(_lp_bundle_meta_get "$BUNDLE_DIR" "LP_BASE_COMMIT")
}

resolve_new_base() {
    NEW_BASE_PATH=$(_lp_bundle_resolve_base "$NEW_BASE") || return $?
    NEW_BASE_COMMIT=$(_lp_bundle_meta_get "$NEW_BASE_PATH" "LP_BUNDLE_COMMIT")
    [[ -z "$NEW_BASE_COMMIT" ]] && NEW_BASE_COMMIT="unknown"
    return 0
}

confirm_rebase() {
    if [[ -z "$CURRENT_BASE" ]]; then
        lp_info "Bundle '$BRANCH' was built from scratch. Attaching to base '$NEW_BASE' for the first time."
    else
        if [[ "$CURRENT_BASE" == "$NEW_BASE" && "$CURRENT_BASE_COMMIT" == "$NEW_BASE_COMMIT" ]]; then
            lp_info "Bundle '$BRANCH' already on base '$NEW_BASE' at ${NEW_BASE_COMMIT:0:7}."
            lp_info "Use 'lp base sync $BRANCH' to refresh if drift is suspected."
            return 1
        fi
        lp_info "Rebase '$BRANCH':"
        lp_info "  current: $CURRENT_BASE @ ${CURRENT_BASE_COMMIT:0:7}"
        lp_info "  new:     $NEW_BASE @ ${NEW_BASE_COMMIT:0:7}"
    fi

    [[ $ASSUME_YES -eq 1 ]] && return 0

    lp_confirm "Wipes data, dev-deployed modules, config, OSGi state. Continue?"
}

main() {
    parse_arguments "$@" || return $?

    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    [[ -d "$BUNDLE_DIR" ]] || {
        lp_error "Bundle for '$BRANCH' not found at $BUNDLE_DIR."
        lp_error "Run 'lp bundle build $BRANCH --from-base $NEW_BASE' to create it."
        return 1
    }

    read_current_source
    resolve_new_base || return $?
    confirm_rebase || { lp_info "Aborted."; return 0; }

    "$_LP_SCRIPTS_DIR/commands/bundle/build.sh" --from-base "$NEW_BASE" -y "$BRANCH"
}

main "$@"
