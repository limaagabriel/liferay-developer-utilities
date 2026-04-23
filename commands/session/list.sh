#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "session" "list" "$@"
source "$_LP_SCRIPTS_DIR/lib/session.sh"

check_dependencies() {
    if ! command -v tmux >/dev/null 2>&1; then
        lp_error "'tmux' is not installed. Please install it to use sessions."
        return 1 2>/dev/null || exit 1
    fi
}

get_tmux_info() {
    tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}' 2>/dev/null
}

get_worktree_branches() {
    git -C "$MAIN_REPO_DIR" worktree list | grep -o '\[.*\]' | tr -d '[]'
}

print_session_details() {
    local session="$1"
    local windows="$2"
    local attached="$3"
    
    local status_parts=()
    if [[ "$attached" -gt 0 ]]; then
        status_parts+=("attached")
    fi

    local description
    description=$(tmux show-option -t "$session" -qv @lp-description)
    if [[ -n "$description" ]]; then
        description=" — $description"
    fi

    local status_name
    status_name=$(tmux show-option -t "$session" -qv @lp-status)
    local emoji
    emoji=$(_lp_status_emoji "$status_name")
    
    local status_emoji_part=""
    if [[ -n "$emoji" ]]; then
        status_emoji_part=" $emoji"
    fi

    if _lp_is_bundle_running "$session"; then
        status_parts+=("bundle running")
    fi

    local status=""
    if [[ ${#status_parts[@]} -gt 0 ]]; then
        local IFS=','
        status=" (${status_parts[*]})"
    fi

    lp_info "  $session ($windows windows)$status$status_emoji_part$description"
}

list_sessions() {
    local tmux_info
    tmux_info=$(get_tmux_info)

    if [[ -z "$tmux_info" ]]; then
        lp_info "No active tmux sessions found."
        return 0
    fi

    local worktree_branches
    worktree_branches=$(get_worktree_branches)

    lp_info "Active Liferay Portal sessions:"
    lp_info "-------------------------------"

    local found_any=false
    while IFS='|' read -r session windows attached; do
        [[ -z "$session" ]] && continue
        if echo "$worktree_branches" | grep -qxw "$session"; then
            print_session_details "$session" "$windows" "$attached"
            found_any=true
        fi
    done <<< "$tmux_info"

    if ! $found_any; then
        lp_info "No active Liferay Portal sessions found."
    fi
}

main() {
    check_dependencies
    list_sessions
}

main "$@"
