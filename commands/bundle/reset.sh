#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "reset" "$@"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
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

validate_bundle() {
    if [[ ! -d "$BUNDLE_DIR" ]]; then
        lp_error "Bundle directory '$BUNDLE_DIR' does not exist."
        return 1 2>/dev/null || exit 1
    fi
}

is_mysql_active() {
    local properties_file="$1"

    if [[ ! -f "$properties_file" ]]; then
        return 1
    fi

    # Check if the properties are not commented out
    grep -q "^jdbc.default.driverClassName" "$properties_file"
}

clean_tomcat_caches() {
    local tomcat_dir
    tomcat_dir=$(find "$BUNDLE_DIR" -maxdepth 1 -type d -name "tomcat-*" | head -n 1)

    if [[ -n "$tomcat_dir" ]]; then
        lp_step 1 3 "Cleaning Tomcat caches ($tomcat_dir)"
        lp_run rm -rf "$tomcat_dir/work" \
            "$tomcat_dir/temp" \
            "$tomcat_dir/osgi/state" \
            "$tomcat_dir/osgi/work" \
            "$tomcat_dir/data" || return $?
    fi
}

clean_bundle_root_caches() {
    lp_step 2 3 "Cleaning bundle root caches and data"
    lp_run rm -rf "$BUNDLE_DIR/osgi/state" "$BUNDLE_DIR/osgi/work" || return $?
}

clean_hypersonic_data() {
    if [[ -d "$BUNDLE_DIR/data" ]]; then
        lp_step 3 3 "Cleaning Hypersonic data"
        lp_run rm -rf "$BUNDLE_DIR/data" || return $?
    fi
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    validate_bundle
    lp_info "Resetting bundle database and caches for branch '$BRANCH'..."

    if is_mysql_active "$BUNDLE_DIR/portal-ext.properties"; then
        "$_LP_SCRIPTS_DIR/commands/mysql/reset.sh" --yes "$BRANCH"
    fi

    clean_tomcat_caches
    clean_bundle_root_caches
    clean_hypersonic_data
    lp_success "Bundle database and caches reset successfully for branch '$BRANCH'."
}

main "$@"
