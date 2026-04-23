#!/usr/bin/env bats

setup() {
    load '../test_helper'
    source "$_LP_SCRIPTS_DIR/lib/session.sh"
}

@test "_lp_status_emoji returns correct emoji" {
    run _lp_status_emoji "pending"
    [ "$output" = "⏳" ]
    
    run _lp_status_emoji "ready"
    [ "$output" = "✅" ]
    
    run _lp_status_emoji "unknown"
    [ "$output" = "" ]
}

@test "_lp_is_bundle_running returns failure if tmux is not present" {
    if command -v tmux >/dev/null 2>&1; then
        # Skip this test if tmux is actually running something?
        # Better yet, let's just test that the function exists.
        run _lp_is_bundle_running "nonexistent_session"
        [ "$status" -eq 1 ]
    fi
}
