#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "drop" "$@"

parse_arguments() {
    ASSUME_YES=0
    BRANCHES=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y) ASSUME_YES=1; shift ;;
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCHES+=("$1"); shift ;;
        esac
    done

    if [[ ${#BRANCHES[@]} -eq 0 ]]; then
        local fallback="$(lp_get_reference_branch)"
        BRANCHES=("$fallback")
    fi
}

confirm_drop() {
    [[ "$ASSUME_YES" -eq 1 ]] && return 0

    if [[ ${#BRANCHES[@]} -eq 1 ]]; then
        local confirm
        printf "%sDrop the database '%s'? [y/N] " "$(_lp_prefix)" "${BRANCHES[0]}"
        read -r confirm
        if [[ "$confirm" != "y" ]]; then
            lp_info "Aborted."
            exit 0
        fi
        return 0
    fi

    lp_info "The following databases will be dropped:"
    for branch in "${BRANCHES[@]}"; do
        lp_info "  - $branch"
    done

    local confirm
    printf "%sProceed? [y/N] " "$(_lp_prefix)"
    read -r confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        exit 0
    fi
}

drop_database() {
    local branch="$1"
    lp_step "$CURRENT_STEP" "$TOTAL_STEPS" "Dropping database '$branch'"
    lp_run docker exec -e MYSQL_PWD=root mysql mysql -uroot -e "drop database if exists \`$branch\`;"
    ((CURRENT_STEP++))
}

main() {
    parse_arguments "$@"
    confirm_drop

    TOTAL_STEPS=${#BRANCHES[@]}
    CURRENT_STEP=1
    for branch in "${BRANCHES[@]}"; do
        drop_database "$branch"
    done

    lp_success "Done!"
}

main "$@"
