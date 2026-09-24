#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

@test "lp_stub records the git worktree list invocation from worktree/list.sh" {
    lp_stub git 0

    run "$_LP_SCRIPTS_DIR/commands/worktree/list.sh"

    [ "$status" -eq 0 ]
    grep -Eq '^git .*worktree list' "$CALLS_LOG"
}
