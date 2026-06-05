#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"
source "$_LP_SCRIPTS_DIR/lib/database.sh"

comment_all_jdbc_lines() {
	local properties_file="$1"
	sed -i "s|^[[:space:]]*jdbc\.default\.driverClassName=\(.*\)|# jdbc.default.driverClassName=\1|" "$properties_file"
	sed -i "s|^[[:space:]]*jdbc\.default\.url=\(.*\)|# jdbc.default.url=\1|" "$properties_file"
	sed -i "s|^[[:space:]]*jdbc\.default\.username=\(.*\)|# jdbc.default.username=\1|" "$properties_file"
	sed -i "s|^[[:space:]]*jdbc\.default\.password=\(.*\)|# jdbc.default.password=\1|" "$properties_file"
}

switch_to_hypersonic() {
	local properties_file="$1"

	if ! grep -q "^jdbc.default.driverClassName" "$properties_file"; then
		lp_info "Database is already Hypersonic."
		return 0
	fi

	comment_all_jdbc_lines "$properties_file"

	lp_success "Switched to Hypersonic."
	lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
}

switch_to_mysql() {
	local properties_file="$1"

	if grep -q "^jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver" "$properties_file"; then
		lp_info "Database is already MySQL."
		return 0
	fi

	comment_all_jdbc_lines "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver|jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver|" "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.url=jdbc:mysql://|jdbc.default.url=jdbc:mysql://|" "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.username=root|jdbc.default.username=root|" "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.password=root|jdbc.default.password=root|" "$properties_file"

	lp_success "Switched to MySQL."
	lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
}

switch_to_postgresql() {
	local properties_file="$1"

	if grep -q "^jdbc.default.driverClassName=org.postgresql.Driver" "$properties_file"; then
		lp_info "Database is already PostgreSQL."
		return 0
	fi

	comment_all_jdbc_lines "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.driverClassName=org.postgresql.Driver|jdbc.default.driverClassName=org.postgresql.Driver|" "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.url=jdbc:postgresql://|jdbc.default.url=jdbc:postgresql://|" "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.username=postgres|jdbc.default.username=postgres|" "$properties_file"
	sed -i "s|^[[:space:]]*#[[:space:]]*jdbc.default.password=postgres|jdbc.default.password=postgres|" "$properties_file"

	lp_success "Switched to PostgreSQL."
	lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
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

	branch="${branch:-$(lp_get_reference_branch)}"

	lp_branch_vars "$branch"

	local properties_file="$BUNDLE_DIR/portal-ext.properties"

	if [[ ! -f "$properties_file" ]]; then
		lp_error "Error: $properties_file not found."
		return 1 2>/dev/null || exit 1
	fi

	if [[ -z "$db_type" ]]; then
		lp_database_status_line "$properties_file"
		return 0 2>/dev/null || exit 0
	fi

	if [[ "$db_type" == "hypersonic" || "$db_type" == "hsql" ]]; then
		switch_to_hypersonic "$properties_file"
	elif [[ "$db_type" == "mysql" ]]; then
		switch_to_mysql "$properties_file"
	elif [[ "$db_type" == "postgresql" || "$db_type" == "pg" ]]; then
		switch_to_postgresql "$properties_file"
	else
		lp_error "Unknown database type: $db_type. Use 'hypersonic', 'mysql', or 'postgresql'."
		return 1 2>/dev/null || exit 1
	fi
}

main "$@"
