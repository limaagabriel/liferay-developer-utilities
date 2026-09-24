#!/usr/bin/env bash
# tests/command_helper.bash — shared harness for driving `lp` commands with
# stubbed tools and inspecting what ran.
#
# Load it from a bats test file with:
#   load "../command_helper"
#
# Call `lp_command_setup` from the test file's `setup()` and
# `lp_command_teardown` from `teardown()`.

_LP_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export _LP_SCRIPTS_DIR

lp_command_setup() {
    export HOME_ORIG="$HOME"
    export TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/lp"

    cat > "$XDG_CONFIG_HOME/lp/config" <<EOF
BASE_PROJECT_DIR="$HOME/dev/projects"
MAIN_REPO_NAME="liferay-portal"
MAIN_REPO_DIR="\$BASE_PROJECT_DIR/\$MAIN_REPO_NAME"
EE_REPO_DIR="\$BASE_PROJECT_DIR/liferay-portal-ee"
BUNDLES_DIR="\$HOME/dev/bundles"
LIFERAY_USER="testuser"
EOF

    mkdir -p "$HOME/dev/projects/liferay-portal"

    mkdir -p "$HOME/bin"
    export PATH="$HOME/bin:$PATH"

    export CALLS_LOG="$TEST_HOME/calls.log"
    : > "$CALLS_LOG"
}

lp_command_teardown() {
    rm -rf "$TEST_HOME"
    export HOME="$HOME_ORIG"
}

# lp_stub <bin> <exit-code-or-script>
#
# Writes a PATH stub at $TEST_HOME/bin/<bin> that appends "<bin> $*" to
# $CALLS_LOG, then either exits with the given numeric code, or — when the
# argument isn't a bare integer — runs it as the stub's script body (so a
# stub can succeed/fail per argument, e.g. fail only on `worktree remove`).
lp_stub() {
    local bin="$1"
    local spec="$2"
    local stub="$TEST_HOME/bin/$bin"

    {
        echo '#!/bin/bash'
        printf 'echo "%s $*" >> %q\n' "$bin" "$CALLS_LOG"
        if [[ "$spec" =~ ^-?[0-9]+$ ]]; then
            printf 'exit %s\n' "$spec"
        else
            echo "$spec"
        fi
    } > "$stub"
    chmod +x "$stub"
}

# lp_source_run <shell> <script> [args...]
#
# Runs a sourced-only script under `bash` or `zsh`, exporting
# _LP_SCRIPTS_DIR and the harness's env (PATH, HOME, CALLS_LOG, ...).
lp_source_run() {
    local shell="$1"
    local script="$2"
    shift 2

    LP_SOURCE_RUN_SCRIPT="$script" "$shell" -c \
        'source "$LP_SOURCE_RUN_SCRIPT" "$@"' \
        lp_source_run "$@"
}
