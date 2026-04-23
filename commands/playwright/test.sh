#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "playwright" "test" "$@"

parse_arguments() {
    ITERATIONS=1
    TEST_NAME=""
    GREP_OPTION=""
    UI_FLAG=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n)
                ITERATIONS="$2"
                shift 2
                ;;
            -g)
                GREP_OPTION="$2"
                shift 2
                ;;
            --ui)
                UI_FLAG=1
                shift
                ;;
            --verbose|-v)
                shift
                ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                TEST_NAME="$1"
                shift
                ;;
        esac
    done
}

validate_environment() {
    if [[ -z "$TEST_NAME" ]]; then
        lp_error "Error: No test name specified."
        echo "Usage: lp playwright test [options] <test-name>"
        return 1 2>/dev/null || exit 1
    fi

    if ! lp_detect_worktree; then
        lp_error "Error: Not currently in a worktree."
        return 1 2>/dev/null || exit 1
    fi

    PLAYWRIGHT_DIR="$LP_DETECTED_WORKTREE_DIR/modules/test/playwright"

    if [[ ! -d "$PLAYWRIGHT_DIR" ]]; then
        lp_error "Error: Playwright directory not found at '$PLAYWRIGHT_DIR'."
        return 1 2>/dev/null || exit 1
    fi
}

run_test_iterations() {
    cd "$PLAYWRIGHT_DIR" || { return 1 2>/dev/null || exit 1; }

    SUCCESS_COUNT=0
    PW_ARGS=()
    if [[ -n "$GREP_OPTION" ]]; then
        PW_ARGS+=("-g" "$GREP_OPTION")
    fi
    if [[ "$UI_FLAG" -eq 1 ]]; then
        PW_ARGS+=("--ui")
    fi

    for ((i=1; i<=ITERATIONS; i++)); do
        lp_step "$i" "$ITERATIONS" "Executing test: $TEST_NAME"

        if lp_run npx playwright test "${PW_ARGS[@]}" "$TEST_NAME"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            lp_success "Iteration $i: SUCCESS"
        else
            local exit_code=$?
            lp_error "Iteration $i: FAILURE (Exit code: $exit_code)"
        fi

        local rate
        rate=$(awk -v s="$SUCCESS_COUNT" -v i="$i" 'BEGIN {printf "%.2f", s / i * 100}')
        lp_info "Current success rate: $SUCCESS_COUNT/$i ($rate%)"
        lp_info "--------------------------------------------------"
    done
}

display_final_report() {
    local total_rate
    total_rate=$(awk -v s="$SUCCESS_COUNT" -v iter="$ITERATIONS" 'BEGIN {printf "%.2f", s / iter * 100}')
    
    lp_info "=================================================="
    lp_info "Final Report for $TEST_NAME"
    lp_info "Success Rate: $SUCCESS_COUNT/$ITERATIONS ($total_rate%)"
    lp_info "=================================================="
}

main() {
    parse_arguments "$@"
    validate_environment
    run_test_iterations
    display_final_report

    if [[ $SUCCESS_COUNT -lt $ITERATIONS ]]; then
        return 1 2>/dev/null || exit 1
    fi
}

main "$@"
