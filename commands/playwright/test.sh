#!/bin/bash
# Usage: lp playwright test [options] <test-name>
# Options:
#   -n <number>  Number of iterations (default: 1)
#   -h, --help   Show this help

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Run Playwright tests in the current worktree."
    echo ""
    echo "Usage: lp playwright test [options] <test-name>"
    echo ""
    echo "Options:"
    echo "  -n <number>  Number of times to run the test (default: 1)"
    echo "  -v, --verbose Show full playwright output"
    echo "  -h, --help    Show this help"
    echo ""
    echo "Examples:"
    echo "  lp playwright test tests/my-test.spec.ts"
    echo "  lp playwright test -n 5 tests/flaky-test.spec.ts"
    exit 0
fi

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

ITERATIONS=1
TEST_NAME=""
VERBOSE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n)
            ITERATIONS="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        -*)
            lp_error "Unknown option: $1"
            exit 1
            ;;
        *)
            TEST_NAME="$1"
            shift
            ;;
    esac
done

if [[ -z "$TEST_NAME" ]]; then
    lp_error "Error: No test name specified."
    echo "Usage: lp playwright test [options] <test-name>"
    exit 1
fi

if ! lp_detect_worktree; then
    lp_error "Error: Not currently in a worktree."
    exit 1
fi

PLAYWRIGHT_DIR="$LP_DETECTED_WORKTREE_DIR/modules/test/playwright"

if [[ ! -d "$PLAYWRIGHT_DIR" ]]; then
    lp_error "Error: Playwright directory not found at '$PLAYWRIGHT_DIR'."
    exit 1
fi

cd "$PLAYWRIGHT_DIR" || exit 1

lp_info "Environment info:"
lp_info "  Node: $(node -v 2>&1 || echo "not found")"
lp_info "  npm:  $(npm -v 2>&1 || echo "not found")"

lp_info "Installing dependencies in $PLAYWRIGHT_DIR..."
lp_run npm install || { lp_error "npm install failed."; exit 1; }

SUCCESS_COUNT=0

for ((i=1; i<=ITERATIONS; i++)); do
    lp_step "$i" "$ITERATIONS" "Executing test: $TEST_NAME"
    
    # Run the test. Using npx playwright test <test_name>
    # We use lp_run to capture output on failure unless VERBOSE is set.
    lp_run npx playwright test "$TEST_NAME"
    EXIT_CODE=$?
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        lp_success "Iteration $i: SUCCESS"
    else
        lp_error "Iteration $i: FAILURE (Exit code: $EXIT_CODE)"
    fi
    
    # Calculate current success rate
    # Using awk for floating point math since bash is integer-only
    RATE=$(awk "BEGIN {printf \"%.2f\", ($SUCCESS_COUNT / $i) * 100}")
    lp_info "Current success rate: $SUCCESS_COUNT/$i ($RATE%)"
    echo "--------------------------------------------------"
done

# Final report
TOTAL_RATE=$(awk "BEGIN {printf \"%.2f\", ($SUCCESS_COUNT / $ITERATIONS) * 100}")
lp_info "=================================================="
lp_info "Final Report for $TEST_NAME"
lp_info "Success Rate: $SUCCESS_COUNT/$ITERATIONS ($TOTAL_RATE%)"
lp_info "=================================================="

if [[ $SUCCESS_COUNT -lt $ITERATIONS ]]; then
    exit 1
fi
