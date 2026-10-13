#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

_lp_loaded_custom_windows() {
    bash -c 'source "$1" && printf "%s" "$SESSION_CUSTOM_WINDOWS"' _ "$XDG_CONFIG_HOME/lp/config"
}

_lp_run_init_with_windows_answer() {
    local answer="$1"
    printf 'y\n\n\n\n\n\n\n\n\n\n\n%s\n\n' "$answer" |
        "$_LP_SCRIPTS_DIR/commands/config/init.sh"
}

@test "init keeps a typed custom-window value with spaces, quotes and \$LP_* literal" {
    local literal='agent:claude --name "$LP_SESSION_NAME"'

    run _lp_run_init_with_windows_answer "$literal"

    [ "$status" -eq 0 ]
    [ "$(_lp_loaded_custom_windows)" = "$literal" ]
}

@test "init keeps an embedded single quote in a custom-window value" {
    local literal="a:echo 'hi'"

    run _lp_run_init_with_windows_answer "$literal"

    [ "$status" -eq 0 ]
    [ "$(_lp_loaded_custom_windows)" = "$literal" ]
}

@test "re-running init with all defaults round-trips an existing custom-window value" {
    local literal='agent:claude --name "$LP_SESSION_NAME"'
    printf "SESSION_CUSTOM_WINDOWS='%s'\n" "$literal" >> "$XDG_CONFIG_HOME/lp/config"

    run _lp_run_init_with_windows_answer ""

    [ "$status" -eq 0 ]
    [ "$(_lp_loaded_custom_windows)" = "$literal" ]
}
