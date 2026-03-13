#!/bin/bash
# Usage: lp session exit
# Detaches from the current tmux session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Exit the current development session (detach from tmux)."
    echo ""
    echo "Usage: lp session exit"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    exit 0
fi

if [[ -n "$TMUX" ]]; then
    lp_info "Exiting session (detaching)..."
    tmux detach-client
else
    lp_error "Not currently in a tmux session."
    exit 1
fi
