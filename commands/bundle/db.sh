#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

is_mysql_active() {
	local properties_file="$1"

	if [[ ! -f "$properties_file" ]]; then
		return 1
	fi

	# Check if the properties are not commented out
	grep -q "^jdbc.default.driverClassName" "$properties_file"
}

show_current_status() {
	local properties_file="$1"

	if is_mysql_active "$properties_file"; then
		local db_name=$(grep "^jdbc.default.url" "$properties_file" | sed "s|.*localhost:3307/||;s|?.*||")

		if [[ -n "$db_name" ]]; then
			lp_info "Current database: MySQL ($db_name)"
		else
			lp_info "Current database: MySQL"
		fi
	else
		lp_info "Current database: Hypersonic"
	fi
}

switch_to_hypersonic() {
	local properties_file="$1"

	if ! is_mysql_active "$properties_file"; then
		lp_info "Database is already Hypersonic."
	else
		sed -i "s/^[[:space:]]*jdbc.default.driverClassName=/# jdbc.default.driverClassName=/" "$properties_file"
		sed -i "s/^[[:space:]]*jdbc.default.url=/# jdbc.default.url=/" "$properties_file"
		sed -i "s/^[[:space:]]*jdbc.default.username=/# jdbc.default.username=/" "$properties_file"
		sed -i "s/^[[:space:]]*jdbc.default.password=/# jdbc.default.password=/" "$properties_file"

		lp_success "Switched to Hypersonic."
		lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
	fi
}

switch_to_mysql() {
	local properties_file="$1"

	if is_mysql_active "$properties_file"; then
		lp_info "Database is already MySQL."
	else
		sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.driverClassName=/jdbc.default.driverClassName=/" "$properties_file"
		sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.url=/jdbc.default.url=/" "$properties_file"
		sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.username=/jdbc.default.username=/" "$properties_file"
		sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.password=/jdbc.default.password=/" "$properties_file"

		lp_success "Switched to MySQL."
		lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
	fi
}

main() {
	lp_init_command "bundle" "db" "$@"

	local db_type=""
	local branch=""

	if [[ $# -gt 0 ]]; then
		db_type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
		shift
	fi

	if [[ $# -gt 0 ]]; then
		branch="$1"
		shift
	fi

	branch="${branch:-$LP_WORKTREE_REFERENCE_BRANCH}"
	branch="${branch:-master}"

	lp_branch_vars "$branch"

	local properties_file="$BUNDLE_DIR/portal-ext.properties"

	if [[ ! -f "$properties_file" ]]; then
		lp_error "Error: $properties_file not found."
		return 1 2>/dev/null || exit 1
	fi

	if [[ -z "$db_type" ]]; then
		show_current_status "$properties_file"
		return 0 2>/dev/null || exit 0
	fi

	if [[ "$db_type" == "hypersonic" || "$db_type" == "hsql" ]]; then
		switch_to_hypersonic "$properties_file"
	elif [[ "$db_type" == "mysql" ]]; then
		switch_to_mysql "$properties_file"
	else
		lp_error "Unknown database type: $db_type. Use 'hypersonic' or 'mysql'."
		return 1 2>/dev/null || exit 1
	fi
}

main "$@"
