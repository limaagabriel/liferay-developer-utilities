#!/usr/bin/env bats

setup() {
    load '../test_helper'
    source "$_LP_SCRIPTS_DIR/lib/output.sh"
}

@test "lp_info prints with prefix" {
    run lp_info "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test message"* ]]
}

@test "lp_step prints with correct format" {
    run lp_step 1 5 "test step"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[1/5]"* ]]
    [[ "$output" == *"test step"* ]]
}

@test "lp_error prints to stderr" {
    run lp_error "test error"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test error"* ]]
}

@test "lp_format_duration formats seconds correctly" {
    run lp_format_duration 65
    [[ "$output" == *"1m 5s"* ]]
    
    run lp_format_duration 3661
    [[ "$output" == *"1h 1m 1s"* ]]
}

@test "lp_run executes command and suppresses output by default" {
    VERBOSE=0
    run lp_run echo "hidden"
    [[ "$output" == "" ]]
}

@test "lp_run shows output if VERBOSE=1" {
    VERBOSE=1
    run lp_run echo "visible"
    [[ "$output" == *"visible"* ]]
}

@test "lp_run shows tail of output if command fails" {
    VERBOSE=0
    test_fail() {
        lp_run bash -c "echo 'line 1'; echo 'line 2'; exit 1"
    }
    run test_fail
    [ "$status" -eq 1 ]
    [[ "$output" == *"line 1"* ]]
    [[ "$output" == *"line 2"* ]]
}
