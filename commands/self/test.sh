#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "self" "test" "$@"

run_tests() {
    lp_step 1 1 "Running BATS unit tests"
    
    if ! command -v bats >/dev/null 2>&1; then
        lp_error "'bats' is not installed. Please install it (e.g. 'brew install bats-core' or 'sudo apt install bats')."
        return 1 2>/dev/null || exit 1
    fi

    bats "$_LP_SCRIPTS_DIR/tests/unit"
}

main() {
    run_tests
}

main "$@"
