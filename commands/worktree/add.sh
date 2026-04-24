#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "worktree" "add" "$@"

parse_arguments() {
    BASE=""
    REMOTE=""
    BRANCH=""
    AUTO_CD=0
    AUTO_SESSION=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --base|-b)     BASE="$2"; shift 2 ;;
            --remote|-r)   REMOTE="$2"; shift 2 ;;
            --cd|-c)       AUTO_CD=1; shift ;;
            --session|-s)  AUTO_SESSION=1; shift ;;
            --verbose|-v)  shift ;;
            -*)
                lp_error "Unknown option: $1"
                lp_error "Usage: lp worktree add [options] <branch>"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done

    if [[ -z "$BRANCH" ]]; then
        lp_error "Usage: lp worktree add [options] <branch>"
        return 1 2>/dev/null || exit 1
    fi
}

get_total_steps() {
    local steps=2
    if [[ -d "$MAIN_REPO_DIR/.serena" ]]; then
        steps=3
    fi
    echo "$steps"
}

check_worktree_limit() {
    local current_worktree_count
    current_worktree_count=$(git -C "$MAIN_REPO_DIR" worktree list --porcelain | grep "^worktree" | grep -v "^worktree $MAIN_REPO_DIR$" | wc -l)
    
    if [[ $current_worktree_count -ge $WORKTREE_LIMIT ]]; then
        lp_info "Warning: You already have $current_worktree_count worktrees (limit is $WORKTREE_LIMIT)."
    fi
}

create_worktree() {
    local total_steps
    total_steps=$(get_total_steps)

    if [[ -n "$REMOTE" ]]; then
        local remote_branch="$REMOTE/$BRANCH"
        
        if ! git -C "$MAIN_REPO_DIR" rev-parse --verify --quiet "$remote_branch" > /dev/null; then
            lp_error "Error: Remote branch '$remote_branch' not found."
            lp_error "Try running 'git -C \"$MAIN_REPO_DIR\" fetch --all' first."
            return 1 2>/dev/null || exit 1
        fi

        lp_step 1 "$total_steps" "Creating worktree for branch '$BRANCH' from remote '$remote_branch'"
        lp_run git -C "$MAIN_REPO_DIR" worktree add --track -B "$BRANCH" "$WORKTREE_DIR" "$remote_branch" || return $?
    else
        if git -C "$MAIN_REPO_DIR" show-ref --verify --quiet "refs/heads/$BRANCH"; then
            lp_step 1 "$total_steps" "Creating worktree for existing branch '$BRANCH'"
            lp_run git -C "$MAIN_REPO_DIR" worktree add "$WORKTREE_DIR" "$BRANCH" || return $?
        else
            local start_point="${BASE:-master}"
            lp_step 1 "$total_steps" "Creating worktree for branch '$BRANCH' from '$start_point'"
            lp_run git -C "$MAIN_REPO_DIR" worktree add -b "$BRANCH" "$WORKTREE_DIR" "$start_point" || return $?
        fi
    fi
}

configure_worktree() {
    local total_steps
    total_steps=$(get_total_steps)

    if [[ -d "$MAIN_REPO_DIR/.serena" ]]; then
        lp_step 2 "$total_steps" "Copying .serena directory from master"
        cp -r "$MAIN_REPO_DIR/.serena" "$WORKTREE_DIR/"
    fi

    lp_step "$((total_steps))" "$total_steps" "Creating app.server.${LIFERAY_USER}.properties"
    cat > "$WORKTREE_DIR/app.server.${LIFERAY_USER}.properties" <<EOF
app.server.parent.dir=$BUNDLE_DIR
EOF
}

handle_post_add_actions() {
    lp_success "Worktree ready at $WORKTREE_DIR"

    if [[ $AUTO_SESSION -eq 1 ]]; then
        lp_info "Automatically starting session for $BRANCH (skipping build)..."
        "$_LP_SCRIPTS_DIR/commands/session/start.sh" --no-build "$BRANCH"
    fi

    if [[ $AUTO_CD -eq 1 ]]; then
        lp_info "Automatically changing directory to $WORKTREE_DIR..."
        source "$_LP_SCRIPTS_DIR/commands/worktree/cd.sh" "$BRANCH"
    else
        lp_info "Tip: run 'lp worktree cd $BRANCH' to navigate there."
    fi
}

main() {
    lp_init_command "worktree" "add" "$@" || {
        local ec=$?
        [[ $ec -eq 255 ]] && return 0 || return $ec
    }
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    check_worktree_limit
    create_worktree
    configure_worktree
    handle_post_add_actions
}

main "$@"
