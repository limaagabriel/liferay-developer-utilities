#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

_lp_write_worktree_properties() {
    local worktree_dir="$1"
    local bundle_dir="$2"
    mkdir -p "$worktree_dir"
    echo "app.server.parent.dir=$bundle_dir" > "$worktree_dir/app.server.testuser.properties"
}

@test "reset.sh stops before resetting when the bundle directory is missing" {
    run "$_LP_SCRIPTS_DIR/commands/bundle/reset.sh" -y aaa

    [ "$status" -ne 0 ]
    [[ "$output" != *"Resetting"* ]]
}

@test "properties.sh stops without running further steps when the bundle dir can't be created" {
    if [[ "$(id -u)" -eq 0 ]]; then
        skip "permissions are not enforced when running as root"
    fi

    _lp_write_worktree_properties "$HOME/dev/projects/liferay-portal" "$HOME/dev/bundles/aaa"
    mkdir -p "$HOME/dev/bundles"
    chmod a-w "$HOME/dev/bundles"

    run "$_LP_SCRIPTS_DIR/commands/bundle/properties.sh" master

    chmod u+w "$HOME/dev/bundles"

    [ "$status" -ne 0 ]
    [[ "$output" != *"[2/"* ]]
}

@test "properties.sh stops before configuring ports when starting mysql fails" {
    _lp_write_worktree_properties "$HOME/dev/projects/liferay-portal" "$HOME/dev/bundles/master"
    export ENABLE_PORT_OFFSET=yes
    lp_stub docker '
        if [[ "$*" == *"compose"* && "$*" == *"up"* ]]; then exit 1; fi
        exit 0
    '

    run "$_LP_SCRIPTS_DIR/commands/bundle/properties.sh" -d mysql master

    [ "$status" -ne 0 ]
    [[ "$output" == *"Starting MySQL"* ]]
    [[ "$output" != *"Using port offset"* ]]
    [[ "$output" != *"Ports configured"* ]]
}

@test "refresh.sh stops before ant deploy when portal setup fails" {
    _lp_write_worktree_properties "$HOME/dev/projects/liferay-portal" "$HOME/dev/bundles/master"
    mkdir -p "$HOME/dev/bundles/master"
    lp_stub ant '
        if [[ "$*" == *"setup-profile-dxp"* ]]; then exit 1; fi
        exit 0
    '

    run "$_LP_SCRIPTS_DIR/commands/bundle/refresh.sh" master

    [ "$status" -ne 0 ]
    ! grep -q "ant deploy" "$CALLS_LOG"
}
