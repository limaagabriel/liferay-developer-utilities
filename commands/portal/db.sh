#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

is_mysql_active() {
	local properties_file="$1"

	if [[ ! -f "$properties_file" ]]; then
		return 1
	fi

	grep -q "^jdbc.default.driverClassName" "$properties_file"
}

ensure_property_present() {
	local properties_file="$1"
	local key="$2"
	local default_value="$3"

	if ! grep -q "^[#[:space:]]*$key=" "$properties_file"; then
		echo "$default_value" >> "$properties_file"
	fi
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
	local db_name="$2"

	local mysql_driver="jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver"
	local mysql_url_prefix="jdbc.default.url=jdbc:mysql://localhost:3307/"
	local mysql_url_suffix="?useUnicode=true&characterEncoding=UTF-8&useFastDateParsing=false"
	local mysql_user="jdbc.default.username=root"
	local mysql_password="jdbc.default.password=root"

	local full_mysql_url="${mysql_url_prefix}${db_name}${mysql_url_suffix}"

	ensure_property_present "$properties_file" "jdbc.default.driverClassName" "$mysql_driver"
	ensure_property_present "$properties_file" "jdbc.default.url" "$full_mysql_url"
	ensure_property_present "$properties_file" "jdbc.default.username" "$mysql_user"
	ensure_property_present "$properties_file" "jdbc.default.password" "$mysql_password"

	local escaped_url=$(echo "$full_mysql_url" | sed 's/&/\\\&/g')

	sed -i "s|^[#[:space:]]*jdbc.default.driverClassName=.*|$mysql_driver|" "$properties_file"
	sed -i "s|^[#[:space:]]*jdbc.default.url=.*|$escaped_url|" "$properties_file"
	sed -i "s|^[#[:space:]]*jdbc.default.username=.*|$mysql_user|" "$properties_file"
	sed -i "s|^[#[:space:]]*jdbc.default.password=.*|$mysql_password|" "$properties_file"

	lp_success "Switched to MySQL ($db_name)."
	lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
}

main() {
	lp_init_command "portal" "db" "$@"

	local properties_file="$HOME/portal-ext.properties"

	if [[ ! -f "$properties_file" ]]; then
		lp_error "Error: $properties_file not found. Please create it first."

		return 1 2>/dev/null || exit 1
	fi

	if [[ -z "$1" ]]; then
		show_current_status "$properties_file"

		return 0 2>/dev/null || exit 0
	fi

	local argument=$(echo "$1" | tr '[:upper:]' '[:lower:]')

	if [[ "$argument" == "hypersonic" || "$argument" == "hsql" ]]; then
		switch_to_hypersonic "$properties_file"
	else
		local db_name="lportal"

		if [[ "$argument" != "mysql" ]]; then
			db_name="$1"
		fi

		switch_to_mysql "$properties_file" "$db_name"
	fi
}

main "$@"
