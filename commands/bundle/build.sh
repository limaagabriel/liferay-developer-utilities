#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "build" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    VERBOSE=1
    ASSUME_YES=0
    SKIP_IF_EXISTS=0
    BRANCH=""
    DB_TYPE=""
    FROM_BASE=""

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
            --from-base|-f)
                if [[ -n "$2" && "$2" != -* ]]; then
                    FROM_BASE="$2"
                    shift 2
                else
                    lp_error "Option $1 requires a base bundle name."
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
    BUILD_SKIPPED=0
    if [[ ! -d "$BUNDLE_DIR" ]]; then
        mkdir -p "$BUNDLE_DIR"
        return
    fi

    if [[ $SKIP_IF_EXISTS -eq 1 ]]; then
        lp_info "Bundle directory '$BUNDLE_DIR' already exists. Skipping build (-s)."
        BUILD_SKIPPED=1
        return 0
    fi

    if [[ $ASSUME_YES -eq 0 ]]; then
        read -p " Bundle directory '$BUNDLE_DIR' already exists. Delete and rebuild? [y/N] " confirm
        if [[ "$confirm" != "y" ]]; then
            lp_info "Aborted."
            BUILD_SKIPPED=1
            return 0
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

clone_from_base() {
    BUILD_SKIPPED=0
    local base_path
    base_path=$(_lp_bundle_resolve_base "$FROM_BASE") || return $?

    if [[ -d "$BUNDLE_DIR" ]]; then
        if [[ $SKIP_IF_EXISTS -eq 1 ]]; then
            lp_info "Bundle directory '$BUNDLE_DIR' already exists. Skipping (-s)."
            BUILD_SKIPPED=1
            return 0
        fi
        if [[ $ASSUME_YES -eq 0 ]]; then
            read -p " Bundle directory '$BUNDLE_DIR' already exists. Delete and rebuild from base '$FROM_BASE'? [y/N] " confirm
            if [[ "$confirm" != "y" ]]; then
                lp_info "Aborted."
                BUILD_SKIPPED=1
                return 0
            fi
        fi
        lp_step "$STEP" "$TOTAL_STEPS" "Removing existing bundle '$BUNDLE_DIR'"
        lp_run rm -rf "$BUNDLE_DIR" || return $?
        STEP=$((STEP + 1))
    fi

    mkdir -p "$BUNDLES_DIR"

    lp_step "$STEP" "$TOTAL_STEPS" "Cloning base '$FROM_BASE' -> $BUNDLE_DIR"
    _lp_bundle_clone "$base_path" "$BUNDLE_DIR" || return $?
    STEP=$((STEP + 1))

    lp_step "$STEP" "$TOTAL_STEPS" "Resetting mutable state"
    _lp_bundle_init_mutable_state "$BUNDLE_DIR"
    STEP=$((STEP + 1))
}

configure_properties() {
    local properties_args=()
    [[ -n "$DB_TYPE" ]] && properties_args+=("-d" "$DB_TYPE")
    properties_args+=("$BRANCH")

    lp_section "$STEP" "$TOTAL_STEPS" "Configuring portal properties" \
        "$_LP_SCRIPTS_DIR/commands/bundle/properties.sh" "${properties_args[@]}"
    STEP=$((STEP + 1))
}

write_meta() {
    local source_label="${1:-scratch}"
    lp_step "$STEP" "$TOTAL_STEPS" "Writing provenance metadata"
    _lp_bundle_write_meta "$BUNDLE_DIR" "$source_label" "$BRANCH" "$WORKTREE_DIR"
    STEP=$((STEP + 1))
}

build_from_base() {
    TOTAL_STEPS=4
    [[ -d "$BUNDLE_DIR" ]] && TOTAL_STEPS=5
    STEP=1

    clone_from_base || return $?
    [[ $BUILD_SKIPPED -eq 1 ]] && return 0
    configure_properties || return $?
    write_meta "base:$FROM_BASE" || return $?

    lp_success "Bundle cloned from base '$FROM_BASE' at '$BUNDLE_DIR'."
    echo
    lp_info "INFO: Bundle built from base skips 'ant all', so portal tooling"
    lp_info "      (gradle wrapper, node, yarn, jest, etc.) was NOT installed"
    lp_info "      in '$WORKTREE_DIR'."
    lp_info "      Run 'lp portal setup -s $BRANCH' to install missing tooling"
    lp_info "      (use -s to also publish portal SNAPSHOT jars to local .m2)."
}

build_from_scratch() {
    TOTAL_STEPS=4
    if [[ -d "$BUNDLE_DIR" ]]; then
        TOTAL_STEPS=5
    fi
    STEP=1

    prepare_bundle_directory || return $?
    [[ $BUILD_SKIPPED -eq 1 ]] && return 0
    run_build || return $?
    configure_properties || return $?
    write_meta "scratch" || return $?

    lp_success "Bundle built at '$BUNDLE_DIR'."
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    if [[ -n "$FROM_BASE" ]]; then
        build_from_base
    else
        build_from_scratch
    fi
}

main "$@"
