#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

# Entry format: "<namespace>/<command>" for scripts run directly, or
# "<namespace>/<command>:sourced" for scripts that must be sourced (run
# under bash, and under zsh too when it's installed).
COMMANDS=(
    "worktree/remove"
    "worktree/add:sourced"
    "worktree/clean"
    "worktree/cd:sourced"
    "worktree/root:sourced"
    "worktree/list"
    "mysql/start"
    "mysql/reset"
    "mysql/drop"
    "postgresql/start"
    "postgresql/reset"
    "postgresql/drop"
    "bundle/reset"
    "bundle/refresh"
    "bundle/remove"
    "bundle/ports"
    "bundle/properties"
    "bundle/db"
    "bundle/cd:sourced"
    "session/add"
    "session/update"
    "session/start"
    "git/patch"
    "git/bisect"
)

@test "every registered command rejects an unknown option without running a step" {
    local failures=()
    local entry ns_cmd script

    for entry in "${COMMANDS[@]}"; do
        ns_cmd="$entry"

        if [[ "$entry" == *:sourced ]]; then
            ns_cmd="${entry%:sourced}"
            script="$_LP_SCRIPTS_DIR/commands/$ns_cmd.sh"

            run lp_source_run bash "$script" --lp-bogus-flag
            [[ "$status" -ne 0 ]] || failures+=("$entry (bash, status=0)")
            [[ "$output" != *"[1/"* ]] || failures+=("$entry (bash, ran a step)")

            if command -v zsh >/dev/null 2>&1; then
                run lp_source_run zsh "$script" --lp-bogus-flag
                [[ "$status" -ne 0 ]] || failures+=("$entry (zsh, status=0)")
                [[ "$output" != *"[1/"* ]] || failures+=("$entry (zsh, ran a step)")
            fi
        else
            script="$_LP_SCRIPTS_DIR/commands/$ns_cmd.sh"

            run "$script" --lp-bogus-flag
            [[ "$status" -ne 0 ]] || failures+=("$entry (status=0)")
            [[ "$output" != *"[1/"* ]] || failures+=("$entry (ran a step)")
        fi
    done

    if [[ ${#failures[@]} -gt 0 ]]; then
        printf 'unknown-option regressions: %s\n' "${failures[*]}" >&2
        return 1
    fi
}
