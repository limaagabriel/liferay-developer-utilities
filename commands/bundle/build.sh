#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "build" "$@"

parse_arguments() {
    VERBOSE=1
    ASSUME_YES=0
    SKIP_IF_EXISTS=0
    BRANCH=""
    DB_TYPE=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --db|-d)
                if [[ -n "$2" && "$2" != -* ]]; then
                    DB_TYPE="$2"
                    shift 2
                else
                    lp_error "Option $1 requires a value (hypersonic|mysql)."
                    return 1 2>/dev/null || exit 1
                fi
                ;;
            --quiet|-q)           VERBOSE=0; shift ;;
            --yes|-y)             ASSUME_YES=1; shift ;;
            --skip-if-exists|-s)  SKIP_IF_EXISTS=1; shift ;;
            --verbose|-v)         shift ;;
            --help|-h)            shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done

    BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
    BRANCH="${BRANCH:-master}"
}

prepare_bundle_directory() {
    BUNDLE_REMOVED=0
    if [[ ! -d "$BUNDLE_DIR" ]]; then
        mkdir -p "$BUNDLE_DIR"
        return
    fi

    if [[ $SKIP_IF_EXISTS -eq 1 ]]; then
        lp_info "Bundle directory '$BUNDLE_DIR' already exists. Skipping build (-s)."
        return 0 2>/dev/null || exit 0
    fi

    if [[ $ASSUME_YES -eq 0 ]]; then
        read -p " Bundle directory '$BUNDLE_DIR' already exists. Delete and rebuild? [y/N] " confirm
        if [[ "$confirm" != "y" ]]; then
            lp_info "Aborted."
            return 0 2>/dev/null || exit 0
        fi
    fi

    lp_step 1 3 "Removing bundle directory '$BUNDLE_DIR'"
    lp_run rm -rf "$BUNDLE_DIR" || return $?
    mkdir -p "$BUNDLE_DIR"
    BUNDLE_REMOVED=1
}

run_build() {
    local start_step=2
    local total_steps=3
    
    if [[ $BUNDLE_REMOVED -eq 0 ]]; then
        start_step=1
        total_steps=2
    fi

    cd "$WORKTREE_DIR" || { return 1 2>/dev/null || exit 1; }

    lp_step "$start_step" "$total_steps" "Running ant setup-profile-dxp"
    lp_run ant setup-profile-dxp || return $?

    lp_step "$((start_step + 1))" "$total_steps" "Running ant all"
    lp_run ant all || return $?
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?
    prepare_bundle_directory || return $?
    run_build || return $?
    
    local properties_args=()
    if [[ -n "$DB_TYPE" ]]; then
        properties_args+=("-d" "$DB_TYPE")
    fi
    properties_args+=("$BRANCH")

    "$_LP_SCRIPTS_DIR/commands/bundle/properties.sh" "${properties_args[@]}"
    lp_success "Bundle built at '$BUNDLE_DIR'."
}

main "$@"
