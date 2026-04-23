#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "playwright" "trace" "$@"

parse_arguments() {
    TRACE_FILE="$1"

    if [[ -z "$TRACE_FILE" ]]; then
        lp_error "Error: No trace file specified."
        echo "Usage: lp playwright trace <trace-file>"
        return 1 2>/dev/null || exit 1
    fi

    if [[ ! -f "$TRACE_FILE" ]]; then
        lp_error "Error: Trace file not found at '$TRACE_FILE'."
        return 1 2>/dev/null || exit 1
    fi

    ABS_TRACE_FILE=$(cd "$(dirname "$TRACE_FILE")" && echo "$PWD/$(basename "$TRACE_FILE")")
}

validate_environment() {
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

show_trace() {
    cd "$PLAYWRIGHT_DIR" || { return 1 2>/dev/null || exit 1; }

    lp_info "Opening trace viewer for $TRACE_FILE..."
    npx playwright show-trace "$ABS_TRACE_FILE"
}

main() {
    parse_arguments "$@"
    validate_environment
    show_trace
}

main "$@"
