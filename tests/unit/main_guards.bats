#!/usr/bin/env bats

load "../test_helper"

setup() {
    load '../test_helper'
    source "$_LP_SCRIPTS_DIR/tests/lint_main_guards.sh"
}

# Writes commands/fixture/<name>.sh under a scratch root (never the real
# repo) with the given main() body, and echoes the scratch root.
_lp_lint_write_fixture() {
    local name="$1"
    local body="$2"
    local root="$BATS_TEST_TMPDIR/fixture-$name"
    mkdir -p "$root/commands/fixture"

    {
        echo '#!/bin/bash'
        echo 'work() { :; }'
        echo 'main() {'
        printf '%s\n' "$body"
        echo '}'
        echo 'main "$@"'
    } > "$root/commands/fixture/$name.sh"

    printf '%s' "$root"
}

@test "every command's main() guards its fallible calls" {
    run lint_main_guards "$_LP_SCRIPTS_DIR"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "lint_main_guards flags an unguarded parse_arguments call in main" {
    local scratch="$BATS_TEST_TMPDIR/unguarded-parse-arguments"
    mkdir -p "$scratch/commands/worktree"
    cp "$_LP_SCRIPTS_DIR/commands/worktree/list.sh" "$scratch/commands/worktree/list.sh"
    sed -i.bak 's/parse_arguments "\$@" || return \$?/parse_arguments "$@"/' "$scratch/commands/worktree/list.sh"
    rm -f "$scratch/commands/worktree/list.sh.bak"

    run lint_main_guards "$scratch"

    [ "$status" -ne 0 ]
    [[ "$output" == *"list.sh"*"parse_arguments"* ]]

    [ -z "$(git -C "$_LP_SCRIPTS_DIR" status --porcelain -- commands/worktree/list.sh)" ]
}

@test "a call followed only by an output helper is flagged, not treated as tail" {
    local scratch
    scratch="$(_lp_lint_write_fixture "trailing-success" '    work
    lp_success "Done!"')"

    run lint_main_guards "$scratch"

    [ "$status" -ne 0 ]
    [[ "$output" == *"trailing-success.sh"*"work"* ]]
}

@test "a call followed only by echo is flagged, not treated as tail" {
    local scratch
    scratch="$(_lp_lint_write_fixture "trailing-echo" '    work
    echo done')"

    run lint_main_guards "$scratch"

    [ "$status" -ne 0 ]
    [[ "$output" == *"trailing-echo.sh"*"work"* ]]
}

@test "a tail if/else whose branches end in a call is not flagged" {
    local scratch
    scratch="$(_lp_lint_write_fixture "tail-if-else" '    if [[ -n "$X" ]]; then
        work
    else
        work
    fi')"

    run lint_main_guards "$scratch"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "a call followed by return \$? stays tail and is not flagged" {
    local scratch
    scratch="$(_lp_lint_write_fixture "trailing-return-status" '    work
    return $?')"

    run lint_main_guards "$scratch"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
