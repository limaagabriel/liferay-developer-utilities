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

    lp_step "$STEP" "$TOTAL_STEPS" "Removing bundle directory '$BUNDLE_DIR'"
    lp_run rm -rf "$BUNDLE_DIR" || return $?
    mkdir -p "$BUNDLE_DIR"
    BUNDLE_REMOVED=1
    STEP=$((STEP + 1))
}

run_build() {
    cd "$WORKTREE_DIR" || { return 1 2>/dev/null || exit 1; }

    lp_step "$STEP" "$TOTAL_STEPS" "Running ant setup-profile-dxp"
    lp_run ant setup-profile-dxp || return $?
    STEP=$((STEP + 1))

    lp_step "$STEP" "$TOTAL_STEPS" "Running ant all"
    lp_run ant all || return $?
    STEP=$((STEP + 1))
}

configure_properties() {
    local properties_args=()
    [[ -n "$DB_TYPE" ]] && properties_args+=("-d" "$DB_TYPE")
    properties_args+=("$BRANCH")

    lp_step "$STEP" "$TOTAL_STEPS" "Configuring portal properties"
    "$_LP_SCRIPTS_DIR/commands/bundle/properties.sh" "${properties_args[@]}"
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    TOTAL_STEPS=3
    if [[ -d "$BUNDLE_DIR" && $SKIP_IF_EXISTS -eq 0 ]]; then
        TOTAL_STEPS=4
    fi
    STEP=1

    prepare_bundle_directory || return $?
    run_build || return $?
    configure_properties || return $?

    lp_success "Bundle built at '$BUNDLE_DIR'."
}

main "$@"
