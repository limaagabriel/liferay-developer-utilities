#!/bin/bash
# Usage: lp playwright trace [options] <trace-file>
# Options:
#   -h, --help   Show this help

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Open a Playwright trace file in the trace viewer."
    echo ""
    echo "Usage: lp playwright trace <trace-file>"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help"
    echo ""
    echo "Examples:"
    echo "  lp playwright trace playwright-report/trace.zip"
    echo "  lp playwright trace /path/to/trace.zip"
    exit 0
fi

source "$_LP_SCRIPTS_DIR/config.sh" || exit 1

TRACE_FILE="$1"

if [[ -z "$TRACE_FILE" ]]; then
    lp_error "Error: No trace file specified."
    echo "Usage: lp playwright trace <trace-file>"
    exit 1
fi

if [[ ! -f "$TRACE_FILE" ]]; then
    lp_error "Error: Trace file not found at '$TRACE_FILE'."
    exit 1
fi

# Resolve absolute path before changing directories
ABS_TRACE_FILE=$(cd "$(dirname "$TRACE_FILE")" && echo "$PWD/$(basename "$TRACE_FILE")")

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

if [[ ! -d "node_modules" ]]; then
    lp_info "Installing dependencies in $PLAYWRIGHT_DIR..."
    lp_run npm install || { lp_error "npm install failed."; exit 1; }
    lp_info ""
fi

lp_info "Opening trace viewer for $TRACE_FILE..."
npx playwright show-trace "$ABS_TRACE_FILE"
