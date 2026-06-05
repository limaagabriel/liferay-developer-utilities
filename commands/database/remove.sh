#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "database" "remove" "$@"
source "$_LP_SCRIPTS_DIR/lib/database.sh"

parse_arguments() {
    BRANCH=""
    FORWARD_ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) FORWARD_ARGS+=("$1"); shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

main() {
    parse_arguments "$@" || return $?
    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"

    local backend
    backend=$(lp_database_backend "$BRANCH") || return $?
    lp_database_log_backend "$BRANCH"

    case "$backend" in
        mysql)
            exec "$_LP_SCRIPTS_DIR/commands/mysql/remove.sh" "${FORWARD_ARGS[@]}"
            ;;
        postgresql)
            exec "$_LP_SCRIPTS_DIR/commands/postgresql/remove.sh" "${FORWARD_ARGS[@]}"
            ;;
        hypersonic)
            lp_database_unsupported "remove"
            return 0
            ;;
        *)
            lp_error "Unsupported backend: $backend"
            return 1 2>/dev/null || exit 1
            ;;
    esac
}

main "$@"
