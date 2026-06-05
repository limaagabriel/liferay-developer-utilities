#!/usr/bin/env bats

setup() {
    load '../test_helper'
    source "$_LP_SCRIPTS_DIR/lib/output.sh"

    TMP_BUNDLE="$(mktemp -d)"
    PROPERTIES_FILE="$TMP_BUNDLE/portal-ext.properties"

    lp_branch_vars() { BUNDLE_DIR="$TMP_BUNDLE"; }

    source "$_LP_SCRIPTS_DIR/lib/database.sh"
}

teardown() {
    rm -rf "$TMP_BUNDLE"
}

@test "lp_database_backend returns mysql when jdbc.default.driverClassName is uncommented" {
    cat > "$PROPERTIES_FILE" <<EOF
jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver
jdbc.default.url=jdbc:mysql://localhost:3307/test
EOF
    run lp_database_backend "test-branch"
    [ "$status" -eq 0 ]
    [ "$output" = "mysql" ]
}

@test "lp_database_backend returns postgresql when jdbc.default.driverClassName is org.postgresql.Driver" {
    cat > "$PROPERTIES_FILE" <<EOF
jdbc.default.driverClassName=org.postgresql.Driver
jdbc.default.url=jdbc:postgresql://localhost:5433/test
EOF
    run lp_database_backend "test-branch"
    [ "$status" -eq 0 ]
    [ "$output" = "postgresql" ]
}

@test "lp_database_backend returns postgresql when mysql is commented but postgresql is not" {
    cat > "$PROPERTIES_FILE" <<EOF
# jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver
# jdbc.default.url=jdbc:mysql://localhost:3307/lportal
# jdbc.default.username=root
# jdbc.default.password=root
jdbc.default.driverClassName=org.postgresql.Driver
jdbc.default.url=jdbc:postgresql://localhost:5433/feature_xyz
jdbc.default.username=postgres
jdbc.default.password=postgres
EOF
    run lp_database_backend "test-branch"
    [ "$status" -eq 0 ]
    [ "$output" = "postgresql" ]
}

@test "lp_database_backend returns hypersonic when both blocks are commented (multi-block file)" {
    cat > "$PROPERTIES_FILE" <<EOF
# jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver
# jdbc.default.url=jdbc:mysql://localhost:3307/lportal
# jdbc.default.username=root
# jdbc.default.password=root
# jdbc.default.driverClassName=org.postgresql.Driver
# jdbc.default.url=jdbc:postgresql://localhost:5433/lportal
# jdbc.default.username=postgres
# jdbc.default.password=postgres
EOF
    run lp_database_backend "test-branch"
    [ "$status" -eq 0 ]
    [ "$output" = "hypersonic" ]
}

@test "lp_database_backend returns hypersonic when jdbc.default.driverClassName is commented" {
    cat > "$PROPERTIES_FILE" <<EOF
# jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver
EOF
    run lp_database_backend "test-branch"
    [ "$status" -eq 0 ]
    [ "$output" = "hypersonic" ]
}

@test "lp_database_backend returns hypersonic when jdbc properties absent" {
    cat > "$PROPERTIES_FILE" <<EOF
locale.default=en_US
EOF
    run lp_database_backend "test-branch"
    [ "$status" -eq 0 ]
    [ "$output" = "hypersonic" ]
}

@test "lp_database_backend errors when portal-ext.properties is missing" {
    run lp_database_backend "test-branch"
    [ "$status" -ne 0 ]
    [[ "$output" == *"portal-ext.properties not found"* ]]
}

@test "lp_database_unsupported prints info and returns 0" {
    run lp_database_unsupported "status"
    [ "$status" -eq 0 ]
    [[ "$output" == *"lp database status is not applicable to the hypersonic backend"* ]]
    [[ "$output" == *"Switch to MySQL with: lp database switch mysql"* ]]
}

@test "lp_database_status_line prints MySQL with schema name when jdbc.default.url has database" {
    cat > "$PROPERTIES_FILE" <<EOF
jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver
jdbc.default.url=jdbc:mysql://localhost:3307/feature_xyz?useUnicode=true
EOF
    run lp_database_status_line "$PROPERTIES_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current database: MySQL (feature_xyz)"* ]]
}

@test "lp_database_status_line prints MySQL without name when jdbc.default.url missing" {
    cat > "$PROPERTIES_FILE" <<EOF
jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver
EOF
    run lp_database_status_line "$PROPERTIES_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current database: MySQL"* ]]
}

@test "lp_database_status_line prints Hypersonic when driverClassName commented" {
    cat > "$PROPERTIES_FILE" <<EOF
# jdbc.default.driverClassName=com.mysql.cj.jdbc.Driver
EOF
    run lp_database_status_line "$PROPERTIES_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current database: Hypersonic"* ]]
}

@test "lp_database_status_line prints PostgreSQL with schema name when jdbc.default.url has database" {
    cat > "$PROPERTIES_FILE" <<EOF
jdbc.default.driverClassName=org.postgresql.Driver
jdbc.default.url=jdbc:postgresql://localhost:5433/feature_xyz
EOF
    run lp_database_status_line "$PROPERTIES_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current database: PostgreSQL (feature_xyz)"* ]]
}

@test "lp_database_status_line prints PostgreSQL without name when jdbc.default.url missing" {
    cat > "$PROPERTIES_FILE" <<EOF
jdbc.default.driverClassName=org.postgresql.Driver
EOF
    run lp_database_status_line "$PROPERTIES_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current database: PostgreSQL"* ]]
}

@test "lp_database_status_line prints Hypersonic when only the org.postgresql.Driver is commented" {
    cat > "$PROPERTIES_FILE" <<EOF
# jdbc.default.driverClassName=org.postgresql.Driver
EOF
    run lp_database_status_line "$PROPERTIES_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current database: Hypersonic"* ]]
}
