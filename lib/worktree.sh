#!/bin/bash
# lib/worktree.sh — Worktree management and branch resolution helpers.

# lp_resolve_branch [options]
# Resolves the branch name from current context or flags.
# Options:
#   --default-master  Defaults to 'master' if no branch is detected.
#   --reference       Prioritize LP_WORKTREE_REFERENCE_BRANCH if set.
#   --require         Exits with an error if no branch can be resolved.
#   --vars            Automatically calls lp_branch_vars "$BRANCH".
lp_resolve_branch() {
    local default_master=0
    local use_reference=0
    local require=0
    local set_vars=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --default-master) default_master=1; shift ;;
            --reference)      use_reference=1; shift ;;
            --require)        require=1; shift ;;
            --vars)           set_vars=1; shift ;;
            *)                shift ;;
        esac
    done

    # 1. If BRANCH is already set (usually from arguments), we're good
    if [[ -n "$BRANCH" ]]; then
        [[ "$set_vars" -eq 1 ]] && lp_branch_vars "$BRANCH"
        return 0
    fi

    # 2. Try reference branch if requested
    if [[ "$use_reference" -eq 1 && -n "$LP_WORKTREE_REFERENCE_BRANCH" ]]; then
        BRANCH="$LP_WORKTREE_REFERENCE_BRANCH"
        [[ "$set_vars" -eq 1 ]] && lp_branch_vars "$BRANCH"
        return 0
    fi

    # 3. Try to detect from current directory
    if lp_detect_worktree; then
        BRANCH="$LP_DETECTED_BRANCH"
        WORKTREE_DIR="$LP_DETECTED_WORKTREE_DIR"
        [[ "$set_vars" -eq 1 ]] && lp_branch_vars "$BRANCH"
        return 0
    fi

    # 4. Fallback to master if requested
    if [[ "$default_master" -eq 1 ]]; then
        BRANCH="master"
        [[ "$set_vars" -eq 1 ]] && lp_branch_vars "$BRANCH"
        return 0
    fi

    # 5. Fail if required
    if [[ "$require" -eq 1 ]]; then
        lp_error "Error: Not currently in a worktree. Please provide a branch name."
        lp_error "Usage: lp worktree set [branch-name]"
        return 1 2>/dev/null || exit 1
    fi

    return 1
}

# lp_validate_worktree [worktree_dir] [branch_name]
# Validates that the worktree directory exists.
# If no arguments provided, uses global $WORKTREE_DIR and $BRANCH.
lp_validate_worktree() {
    local wt_dir="${1:-$WORKTREE_DIR}"
    local branch="${2:-$BRANCH}"

    if [[ ! -d "$wt_dir" ]]; then
        lp_error "Error: Worktree directory does not exist: $wt_dir"
        if [[ -n "$branch" ]]; then
            lp_info "Tip: Create the worktree first with 'lp worktree add $branch'"
        fi
        return 1 2>/dev/null || exit 1
    fi
}

# lp_load_bundle_dir [worktree_dir]
# Loads BUNDLE_DIR from the app.server.properties file in the given worktree.
# Uses $WORKTREE_DIR if no argument is provided.
lp_load_bundle_dir() {
    local wt_dir="${1:-$WORKTREE_DIR}"
    local props_file="$wt_dir/app.server.${LIFERAY_USER}.properties"

    if [[ ! -f "$props_file" ]]; then
        lp_error "Error: Properties file not found at '$props_file'."
        return 1 2>/dev/null || exit 1
    fi

    # Parse app.server.parent.dir, handling spaces and ignoring comments
    local dir
    dir=$(sed -n 's/^[[:space:]]*app.server.parent.dir[[:space:]]*=[[:space:]]*\(.*\)$/\1/p' "$props_file" | tail -n 1)

    # Trim trailing carriage return if any (for Windows-edited files)
    dir=$(echo "$dir" | tr -d '\r')

    # Trim leading/trailing whitespace from the captured value
    dir=$(echo "$dir" | xargs)

    if [[ -z "$dir" ]]; then
        lp_error "Error: Could not find 'app.server.parent.dir' in '$props_file'."
        return 1 2>/dev/null || exit 1
    fi

    BUNDLE_DIR="$dir"
}

# lp_resolve_workspace_dir
# Echoes the workspace root (managed worktree dir, else current git toplevel).
# Returns 1 with an error if neither is detected.
lp_resolve_workspace_dir() {
    if lp_detect_worktree; then
        echo "$LP_DETECTED_WORKTREE_DIR"
        return 0
    fi
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git rev-parse --show-toplevel
        return 0
    fi
    lp_error "Not in a Liferay Portal repository or worktree."
    return 1
}
