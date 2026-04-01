#!/bin/bash
# Usage: lp portal db [mysql|hypersonic|database_name]
# Switches between mysql (with optional db name) and hypersonic.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Switch between mysql (with optional db name) and hypersonic."
    echo ""
    echo "Usage: lp portal db [mysql|hypersonic|database_name]"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp portal db mysql"
    echo "  lp portal db hypersonic"
    echo "  lp portal db lportal_test   # Switch to mysql and use lportal_test database"
    echo ""
    echo "If no argument is provided, it shows the current database being used."
    return 0 2>/dev/null || exit 0
fi

PROPERTIES_FILE="$HOME/portal-ext.properties"

MYSQL_DRIVER="jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver"
MYSQL_URL_PREFIX="jdbc.default.url=jdbc:mysql://localhost:3307/"
MYSQL_URL_SUFFIX="?useUnicode=true&characterEncoding=UTF-8&useFastDateParsing=false"
MYSQL_USER="jdbc.default.username=root"
MYSQL_PASSWORD="jdbc.default.password=root"

# Function to check if mysql is active
is_mysql_active() {
    if [ ! -f "$PROPERTIES_FILE" ]; then
        return 1
    fi
    grep -q "^jdbc.default.driverClassName" "$PROPERTIES_FILE"
}

# Ensure properties file exists
if [ ! -f "$PROPERTIES_FILE" ]; then
    lp_error "Error: $PROPERTIES_FILE not found. Please create it first."
    return 1 2>/dev/null || exit 1
fi

# No argument provided: show current status
if [ -z "$1" ]; then
    if is_mysql_active; then
        # Try to extract database name from URL if possible
        DB_NAME=$(grep "^jdbc.default.url" "$PROPERTIES_FILE" | sed "s|.*localhost:3307/||;s|?.*||")
        if [ -n "$DB_NAME" ]; then
            lp_info "Current database: MySQL ($DB_NAME)"
        else
            lp_info "Current database: MySQL"
        fi
    else
        lp_info "Current database: Hypersonic"
    fi
    return 0 2>/dev/null || exit 0
fi

ARG=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Helper to ensure a property is present (commented or not)
ensure_property_present() {
    local key="$1"
    local default_value="$2"
    if ! grep -q "^[#[:space:]]*$key=" "$PROPERTIES_FILE"; then
        echo "$default_value" >> "$PROPERTIES_FILE"
    fi
}

if [[ "$ARG" == "hypersonic" || "$ARG" == "hsql" ]]; then
    if ! is_mysql_active; then
        lp_info "Database is already Hypersonic."
    else
        # Comment mysql properties
        sed -i "s/^[[:space:]]*jdbc.default.driverClassName=/# jdbc.default.driverClassName=/" "$PROPERTIES_FILE"
        sed -i "s/^[[:space:]]*jdbc.default.url=/# jdbc.default.url=/" "$PROPERTIES_FILE"
        sed -i "s/^[[:space:]]*jdbc.default.username=/# jdbc.default.username=/" "$PROPERTIES_FILE"
        sed -i "s/^[[:space:]]*jdbc.default.password=/# jdbc.default.password=/" "$PROPERTIES_FILE"
        
        lp_success "Switched to Hypersonic."
        lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
    fi
else
    # Treat as mysql switch. If $1 is not "mysql", it's a specific database name.
    DB_NAME="lportal"
    if [[ "$ARG" != "mysql" ]]; then
        DB_NAME="$1"
    fi
    
    FULL_MYSQL_URL="${MYSQL_URL_PREFIX}${DB_NAME}${MYSQL_URL_SUFFIX}"

    # Ensure all properties exist in some form (commented or not)
    ensure_property_present "jdbc.default.driverClassName" "$MYSQL_DRIVER"
    ensure_property_present "jdbc.default.url" "$FULL_MYSQL_URL"
    ensure_property_present "jdbc.default.username" "$MYSQL_USER"
    ensure_property_present "jdbc.default.password" "$MYSQL_PASSWORD"

    # Escape & for sed replacement string
    # We don't need to escape ? in the replacement string, but & must be escaped as \&
    ESCAPED_URL=$(echo "$FULL_MYSQL_URL" | sed 's/&/\\\&/g')

    # We replace any line starting with # (plus optional space) and the key, or just the key
    sed -i "s|^[#[:space:]]*jdbc.default.driverClassName=.*|$MYSQL_DRIVER|" "$PROPERTIES_FILE"
    sed -i "s|^[#[:space:]]*jdbc.default.url=.*|$ESCAPED_URL|" "$PROPERTIES_FILE"
    sed -i "s|^[#[:space:]]*jdbc.default.username=.*|$MYSQL_USER|" "$PROPERTIES_FILE"
    sed -i "s|^[#[:space:]]*jdbc.default.password=.*|$MYSQL_PASSWORD|" "$PROPERTIES_FILE"
    
    lp_success "Switched to MySQL ($DB_NAME)."
    lp_info "Note: This won't switch the database for a running bundle, only for new bundle executions."
fi
