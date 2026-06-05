#!/bin/bash

_lp_database_backend_from_file() {
    local properties_file="$1"
    [[ -f "$properties_file" ]] || {
        lp_error "portal-ext.properties not found at $properties_file"
        return 1
    }

    local driver
    driver=$(grep "^jdbc.default.driverClassName" "$properties_file" 2>/dev/null \
        | head -n1 | cut -d'=' -f2-)
    case "$driver" in
        com.mysql.cj.jdbc.Driver) echo "mysql" ;;
        org.postgresql.Driver)     echo "postgresql" ;;
        *)                         echo "hypersonic" ;;
    esac
}

lp_database_backend() {
    local branch="$1"
    lp_branch_vars "$branch" || return 1
    _lp_database_backend_from_file "$BUNDLE_DIR/portal-ext.properties"
}

lp_database_runtime_running() {
    local backend="$1"
    [[ -z "$backend" ]] && return 1
    docker ps --format '{{.Names}}' | grep -q "^${backend}$"
}

lp_database_exists() {
    local branch="$1"
    lp_branch_vars "$branch" || return 1
    local properties_file="$BUNDLE_DIR/portal-ext.properties"
    [[ -f "$properties_file" ]] || return 1

    local backend
    backend=$(_lp_database_backend_from_file "$properties_file")
    lp_database_runtime_running "$backend" || return 1

    case "$backend" in
        mysql)
            [[ -n "$(docker exec -e MYSQL_PWD=root mysql mysql -uroot -N -e \
                "show databases like '$branch';" 2>/dev/null)" ]]
            ;;
        postgresql)
            docker exec postgresql psql -U postgres -tAc \
                "select 1 from pg_database where datname='$branch';" 2>/dev/null | grep -q 1
            ;;
        *)
            return 1
            ;;
    esac
}

lp_database_drop() {
    local branch="$1"
    lp_branch_vars "$branch" || return 1
    local properties_file="$BUNDLE_DIR/portal-ext.properties"
    [[ -f "$properties_file" ]] || return 1

    local backend
    backend=$(_lp_database_backend_from_file "$properties_file")
    case "$backend" in
        mysql)
            docker exec -e MYSQL_PWD=root mysql mysql -uroot -e \
                "drop database if exists \`$branch\`;"
            ;;
        postgresql)
            docker exec postgresql psql -U postgres -c \
                "drop database if exists \"$branch\";"
            ;;
        *)
            return 1
            ;;
    esac
}

lp_database_unsupported() {
    local cmd="$1"
    lp_info "lp database $cmd is not applicable to the hypersonic backend (embedded; no runtime state)."
    lp_info "Switch to MySQL with: lp database switch mysql"
    lp_info "Or to PostgreSQL with: lp database switch postgresql"
}

lp_database_log_backend() {
    local branch="$1"
    lp_branch_vars "$branch" || return 1
    lp_database_status_line "$BUNDLE_DIR/portal-ext.properties"
}

lp_database_status_line() {
    local properties_file="$1"
    local backend
    backend=$(_lp_database_backend_from_file "$properties_file")

    case "$backend" in
        mysql)
            local db_name
            db_name=$(grep "^jdbc.default.url" "$properties_file" \
                | sed "s|.*localhost:3307/||;s|?.*||")
            if [[ -n "$db_name" ]]; then
                lp_info "Current database: MySQL ($db_name)"
            else
                lp_info "Current database: MySQL"
            fi
            ;;
        postgresql)
            local db_name
            db_name=$(grep "^jdbc.default.url" "$properties_file" \
                | sed "s|.*localhost:5433/||;s|?.*||")
            if [[ -n "$db_name" ]]; then
                lp_info "Current database: PostgreSQL ($db_name)"
            else
                lp_info "Current database: PostgreSQL"
            fi
            ;;
        *)
            lp_info "Current database: Hypersonic"
            ;;
    esac
}
