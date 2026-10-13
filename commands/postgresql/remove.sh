#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "postgresql" "remove" "$@"

parse_arguments() {
    ASSUME_YES=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y) ASSUME_YES=1; shift ;;
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                lp_error "Unexpected argument: $1"
                return 1 2>/dev/null || exit 1
                ;;
        esac
    done
}

confirm_removal() {
    [[ "$ASSUME_YES" -eq 1 ]] && return 0

    if ! lp_confirm "Remove the shared PostgreSQL container? This will destroy ALL databases."; then
        lp_info "Aborted."
        return 1
    fi
}

remove_postgresql_container() {
    cd "$_LP_SCRIPTS_DIR/commands/postgresql" || { return 1 2>/dev/null || exit 1; }

    lp_step 1 1 "Removing PostgreSQL container"
    lp_run docker compose -f template.yaml down -v || return $?
}

main() {
    parse_arguments "$@" || return $?
    confirm_removal || return 0
    remove_postgresql_container || return $?
    lp_success "PostgreSQL has been removed."
}

main "$@"
