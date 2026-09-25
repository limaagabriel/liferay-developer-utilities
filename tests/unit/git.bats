#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

@test "patch.sh stops before applying when the download fails" {
    lp_stub curl 1
    lp_stub git 0

    run "$_LP_SCRIPTS_DIR/commands/git/patch.sh" "https://example.test/some.patch"

    [ "$status" -ne 0 ]
    ! grep -q "git am\|git apply" "$CALLS_LOG"
}

@test "bisect-step.sh exits 128 when the tmux build session fails to start" {
    lp_stub git '
        case "$1 $2" in
            "rev-parse --short") echo "abc1234"; exit 0 ;;
            "bisect log") exit 0 ;;
        esac
        exit 0
    '
    lp_stub tmux '
        case "$1" in
            has-session) exit 1 ;;
            new-session) exit 1 ;;
        esac
        exit 0
    '

    run "$_LP_SCRIPTS_DIR/commands/git/bisect-step.sh" master

    [ "$status" -eq 128 ]
}

@test "bisect-step.sh exits 128 when no branch is given" {
    lp_stub git '
        case "$1 $2" in
            "rev-parse --short") echo "abc1234"; exit 0 ;;
            "bisect log") exit 0 ;;
        esac
        exit 0
    '
    lp_stub tmux 0

    run bash -c "printf 's\n' | \"$_LP_SCRIPTS_DIR/commands/git/bisect-step.sh\""

    [ "$status" -eq 128 ]
    ! grep -q "tmux" "$CALLS_LOG"
}

@test "bisect.sh stops before running when git bisect start fails" {
    lp_stub git '
        case "$1 $2" in
            "bisect start") exit 1 ;;
            "rev-parse --short") echo "abc1234"; exit 0 ;;
            "bisect log") exit 0 ;;
        esac
        exit 0
    '

    run "$_LP_SCRIPTS_DIR/commands/git/bisect.sh" -g aaa -b bbb master

    [ "$status" -ne 0 ]
    ! grep -q "bisect run" "$CALLS_LOG"
    [[ "$output" != *"complete"* ]]
}
