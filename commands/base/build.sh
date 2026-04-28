#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "base" "build" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    NAME=""
    SOURCE_BRANCH=""
    ASSUME_YES=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)      ASSUME_YES=1; shift ;;
            --branch|-b)
                if [[ -n "$2" && "$2" != -* ]]; then
                    SOURCE_BRANCH="$2"; shift 2
                else
                    lp_error "Option $1 requires a branch name."
                    return 1 2>/dev/null || exit 1
                fi
                ;;
            --verbose|-v)  shift ;;
            --help|-h)     shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ -z "$NAME" ]]; then
                    NAME="$1"
                else
                    lp_error "Too many arguments: $1"
                    return 1 2>/dev/null || exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$NAME" ]]; then
        lp_error "Usage: lp base build [-b <branch>] [-y] <name>"
        return 1 2>/dev/null || exit 1
    fi
}

resolve_source_bundle() {
    local source_branch="${SOURCE_BRANCH:-$NAME}"
    lp_branch_vars "$source_branch"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    if [[ ! -d "$BUNDLE_DIR" ]]; then
        lp_error "Source bundle does not exist at $BUNDLE_DIR."
        lp_error "Build it first with 'lp bundle build $source_branch'."
        return 1
    fi
    SOURCE_BUNDLE="$BUNDLE_DIR"
}

main() {
    parse_arguments "$@" || return $?
    resolve_source_bundle || return $?

    local target="$BASE_BUNDLES_DIR/$NAME"
    local total=3
    [[ -d "$target" ]] && total=4
    local step=1

    if [[ -d "$target" ]]; then
        if [[ $ASSUME_YES -eq 0 ]]; then
            read -p " Base bundle '$NAME' already exists at $target. Delete and rebuild? [y/N] " confirm
            if [[ "$confirm" != "y" ]]; then
                lp_info "Aborted."
                return 0
            fi
        fi
        lp_step $step $total "Removing existing base '$NAME'"
        lp_run rm -rf "$target" || return $?
        step=$((step + 1))
    fi

    mkdir -p "$BASE_BUNDLES_DIR"

    lp_step $step $total "Cloning $SOURCE_BUNDLE -> $target"
    _lp_bundle_clone "$SOURCE_BUNDLE" "$target" || return $?
    step=$((step + 1))

    lp_step $step $total "Resetting mutable state in base"
    _lp_bundle_init_mutable_state "$target"
    step=$((step + 1))

    lp_step $step $total "Writing provenance metadata"
    _lp_bundle_write_meta "$target" "scratch" "$NAME" "$WORKTREE_DIR"

    local mode
    mode=$(cat "$_LP_BUNDLE_CLONE_MODE_FILE" 2>/dev/null || echo "?")
    lp_success "Base bundle '$NAME' ready at $target (clone mode: $mode)"
}

main "$@"
