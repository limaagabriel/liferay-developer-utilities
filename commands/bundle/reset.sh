#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "reset" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"
source "$_LP_SCRIPTS_DIR/lib/database.sh"

parse_arguments() {
    ASSUME_YES=0
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y) ASSUME_YES=1; shift ;;
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done

    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"
}

confirm_reset() {
    if [[ "$ASSUME_YES" -eq 1 ]]; then
        return 0
    fi

    if ! lp_confirm "Reset the bundle and database for '$BRANCH'?"; then
        lp_info "Aborted."
        return 1
    fi
}

validate_bundle() {
    if [[ ! -d "$BUNDLE_DIR" ]]; then
        lp_error "Bundle directory '$BUNDLE_DIR' does not exist."
        return 1 2>/dev/null || exit 1
    fi
}

get_total_steps() {
    local total=1 # bundle root caches is always cleaned
    local tomcat_dir
    tomcat_dir=$(find "$BUNDLE_DIR" -maxdepth 1 -type d -name "tomcat-*" 2>/dev/null | head -n 1)
    [[ -n "$tomcat_dir" ]] && ((total++))
    [[ -d "$BUNDLE_DIR/data" ]] && ((total++))
    echo "$total"
}

clean_tomcat_caches() {
    local tomcat_dir
    tomcat_dir=$(find "$BUNDLE_DIR" -maxdepth 1 -type d -name "tomcat-*" 2>/dev/null | head -n 1)

    if [[ -n "$tomcat_dir" ]]; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Cleaning Tomcat caches ($tomcat_dir)"
        lp_run rm -rf "$tomcat_dir/work" \
            "$tomcat_dir/temp" \
            "$tomcat_dir/osgi/state" \
            "$tomcat_dir/osgi/work" \
            "$tomcat_dir/data" || return $?
        ((CURRENT_STEP++))
    fi
}

clean_bundle_root_caches() {
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Cleaning bundle root caches and data"
    lp_run rm -rf "$BUNDLE_DIR/osgi/state" "$BUNDLE_DIR/osgi/work" || return $?
    ((CURRENT_STEP++))
}

clean_hypersonic_data() {
    if [[ -d "$BUNDLE_DIR/data" ]]; then
        lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Cleaning Hypersonic data"
        lp_run rm -rf "$BUNDLE_DIR/data" || return $?
        ((CURRENT_STEP++))
    fi
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    validate_bundle
    confirm_reset || return 0
    lp_info "Resetting bundle database and caches for branch '$BRANCH'..."

    local backend
    backend=$(lp_database_backend "$BRANCH")
    local db_active=0
    [[ "$backend" == "mysql" || "$backend" == "postgresql" ]] && db_active=1

    TOTAL_STEPS=$(get_total_steps)
    [[ $db_active -eq 1 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
    CURRENT_STEP=1

    if [[ "$backend" == "mysql" ]]; then
        lp_section "$CURRENT_STEP" "$TOTAL_STEPS" "Resetting MySQL database '$BRANCH'" \
            "$_LP_SCRIPTS_DIR/commands/mysql/reset.sh" --yes "$BRANCH"
        ((CURRENT_STEP++))
    elif [[ "$backend" == "postgresql" ]]; then
        lp_section "$CURRENT_STEP" "$TOTAL_STEPS" "Resetting PostgreSQL database '$BRANCH'" \
            "$_LP_SCRIPTS_DIR/commands/postgresql/reset.sh" --yes "$BRANCH"
        ((CURRENT_STEP++))
    fi

    clean_tomcat_caches
    clean_bundle_root_caches
    clean_hypersonic_data

    if lp_port_offset_enabled; then
        "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" "$BRANCH"
    fi

    lp_success "Bundle database and caches reset successfully for branch '$BRANCH'."
}

main "$@"
