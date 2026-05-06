#!/bin/bash

lp_database_backend() {
    local branch="$1"
    lp_branch_vars "$branch" || return 1

    local properties_file="$BUNDLE_DIR/portal-ext.properties"
    [[ -f "$properties_file" ]] || {
        lp_error "portal-ext.properties not found at $properties_file"
        return 1
    }

    if grep -q "^jdbc.default.driverClassName" "$properties_file"; then
        echo "mysql"
    else
        echo "hypersonic"
    fi
}

lp_database_unsupported() {
    local cmd="$1"
    lp_info "lp database $cmd is not applicable to the hypersonic backend (embedded; no runtime state)."
    lp_info "Switch to MySQL with: lp database switch mysql"
}

lp_database_status_line() {
    local properties_file="$1"
    if grep -q "^jdbc.default.driverClassName" "$properties_file"; then
        local db_name
        db_name=$(grep "^jdbc.default.url" "$properties_file" | sed "s|.*localhost:3307/||;s|?.*||")
        if [[ -n "$db_name" ]]; then
            lp_info "Current database: MySQL ($db_name)"
        else
            lp_info "Current database: MySQL"
        fi
    else
        lp_info "Current database: Hypersonic"
    fi
}
