#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "postgresql" "start" "$@"

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

BRANCH="${BRANCH:-$(lp_get_reference_branch)}"

prepare_environment() {
    cd "$_LP_SCRIPTS_DIR/commands/postgresql" || { return 1 2>/dev/null || exit 1; }
}

start_postgresql_container() {
    lp_step 1 3 "Starting PostgreSQL container"

    if docker ps -a --format '{{.Names}}' | grep -q '^postgresql$'; then
        if ! docker ps --format '{{.Names}}' | grep -q '^postgresql$'; then
            lp_run docker compose -f ./template.yaml up -d || return $?
        fi
    else
        lp_run docker compose -f ./template.yaml up -d || return $?
    fi
}

wait_for_postgresql_ready() {
    lp_step 2 3 "Waiting for PostgreSQL to be ready"
    until docker exec postgresql psql -U postgres -c "select 1" &> /dev/null; do
        sleep 1
    done
}

initialize_database() {
    lp_step 3 3 "Creating database '$BRANCH'"

    if docker exec postgresql psql -U postgres -tAc \
            "select 1 from pg_database where datname='$BRANCH'" 2>/dev/null | grep -q 1; then
        lp_info "Database '$BRANCH' already exists, skipping creation."
    else
        lp_run docker exec postgresql psql -U postgres -c "create database \"$BRANCH\";" || return $?
    fi
}

main() {
    prepare_environment
    start_postgresql_container
    wait_for_postgresql_ready
    initialize_database
    lp_success "PostgreSQL is ready."
}

main "$@"
