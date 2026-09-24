#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

BACKENDS=(mysql postgresql)

@test "start.sh stops without waiting when compose up fails" {
    for backend in "${BACKENDS[@]}"; do
        lp_stub docker '
            if [[ "$*" == *"compose"* && "$*" == *"up"* ]]; then exit 1; fi
            exit 0
        '

        run "$_LP_SCRIPTS_DIR/commands/$backend/start.sh" aaa

        [ "$status" -ne 0 ]
        [[ "$output" != *"Waiting"* ]]
    done
}

@test "start.sh gives up and shows a docker logs hint when the container never becomes ready" {
    for backend in "${BACKENDS[@]}"; do
        lp_stub docker '
            if [[ "$*" == *"compose"* && "$*" == *"up"* ]]; then exit 0; fi
            if [[ "$*" == *"select 1"* && "$*" != *"from"* ]]; then exit 1; fi
            exit 0
        '
        lp_stub sleep 0

        run "$_LP_SCRIPTS_DIR/commands/$backend/start.sh" aaa

        [ "$status" -ne 0 ]
        [[ "$output" == *"docker logs"* ]]
        [[ "$output" != *"[3/3]"* ]]
        ! grep -q "create schema\|create database" "$CALLS_LOG"
    done
}

@test "drop.sh drops the remaining branches and lists the ones that failed" {
    for backend in "${BACKENDS[@]}"; do
        lp_stub docker '
            if [[ "$*" == *"exec"* && "$*" == *"drop"* && "$*" == *"aaa"* ]]; then exit 1; fi
            exit 0
        '

        run "$_LP_SCRIPTS_DIR/commands/$backend/drop.sh" -y aaa bbb

        [ "$status" -eq 1 ]
        grep -q "bbb" "$CALLS_LOG"
        [[ "$output" == *"aaa"* ]]
    done
}

@test "reset.sh skips create when drop fails" {
    for backend in "${BACKENDS[@]}"; do
        lp_stub docker '
            if [[ "$*" == *"exec"* && "$*" == *"drop"* ]]; then exit 1; fi
            exit 0
        '

        run "$_LP_SCRIPTS_DIR/commands/$backend/reset.sh" --yes aaa

        [ "$status" -ne 0 ]
        ! grep -q "create" "$CALLS_LOG"
    done
}

@test "remove.sh and stop.sh stop without success output when compose fails" {
    for backend in "${BACKENDS[@]}"; do
        for cmd in remove stop; do
            lp_stub docker '
                if [[ "$*" == *"compose"* ]]; then exit 1; fi
                exit 0
            '

            run bash -c "printf 'y\n' | \"$_LP_SCRIPTS_DIR/commands/$backend/$cmd.sh\""

            [ "$status" -ne 0 ]
            [[ "$output" != *"has been"* ]]
        done
    done
}
