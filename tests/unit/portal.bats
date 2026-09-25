#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

@test "sample.sh deploys remaining extensions and reports the one that failed" {
    local workspace="$HOME/dev/projects/liferay-portal/workspaces/liferay-sample-workspace/client-extensions"
    mkdir -p "$workspace/ext-a" "$workspace/ext-b"

    lp_stub zsh '
        echo "zsh-pwd $PWD" >> "$CALLS_LOG"
        case "$PWD" in
            */ext-a) exit 1 ;;
            *) exit 0 ;;
        esac
    '

    run "$_LP_SCRIPTS_DIR/commands/portal/sample.sh"

    [ "$status" -eq 1 ]
    [ "$(grep -c "^zsh " "$CALLS_LOG")" -eq 2 ]
    grep -q "zsh-pwd .*/ext-a$" "$CALLS_LOG"
    grep -q "zsh-pwd .*/ext-b$" "$CALLS_LOG"
    [[ "$output" == *"Failed to deploy: ext-a"* ]]
    [[ "$output" != *"Successfully deployed"* ]]
}
