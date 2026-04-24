#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "mysql" "drop" "$@"

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

BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
BRANCH="${BRANCH:-master}"

confirm_drop() {
    if [[ "$ASSUME_YES" -eq 1 ]]; then
        return 0
    fi

    local confirm
    read -p " Drop the database '$BRANCH'? [y/N] " confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        return 0 2>/dev/null || exit 0
    fi
}

drop_database() {
    lp_step 1 1 "Dropping database '$BRANCH'"
    lp_run docker exec -e MYSQL_PWD=root mysql mysql -uroot -e "drop database if exists \`$BRANCH\`;"
}

main() {
    confirm_drop
    drop_database
    lp_success "Database '$BRANCH' dropped."
}

main "$@"
