#!/bin/bash
# Liferay Portal development path configuration.
# Source this file in other scripts; do not execute it directly.

# Guard: detect if the script is being executed instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: config must be sourced, not executed."
    echo "Usage: source $(basename "${BASH_SOURCE[0]}")"
    exit 1
fi

# ---------------------------------------------------------------------------
# Per-user config (task 2.1 / 2.2 / 2.3)
# ---------------------------------------------------------------------------

_LP_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"

if [[ ! -f "$_LP_USER_CONFIG" ]]; then
    echo "lp: no per-user config found at '$_LP_USER_CONFIG'." >&2
    echo "lp: run 'lp config init' to set up your configuration." >&2
    return 1
fi

source "$_LP_USER_CONFIG"

# ---------------------------------------------------------------------------
# Configurable variables with defaults (task 2.4 / 2.5)
# ---------------------------------------------------------------------------

BASE_PROJECT_DIR="${BASE_PROJECT_DIR:=$HOME/dev/projects}"
MAIN_REPO_NAME="${MAIN_REPO_NAME:=liferay-portal}"
MAIN_REPO_DIR="${MAIN_REPO_DIR:=$BASE_PROJECT_DIR/$MAIN_REPO_NAME}"
BUNDLES_DIR="${BUNDLES_DIR:=$HOME/dev/bundles}"
ENABLE_AUTOCOMPLETE="${ENABLE_AUTOCOMPLETE:=yes}"
ENABLE_ALIASES="${ENABLE_ALIASES:=yes}"

# ---------------------------------------------------------------------------
# Warn for any expected variable that is still unset (task 2.6)
# ---------------------------------------------------------------------------

for _lp_var in BASE_PROJECT_DIR MAIN_REPO_NAME MAIN_REPO_DIR BUNDLES_DIR ENABLE_AUTOCOMPLETE ENABLE_ALIASES; do
    eval "_lp_val=\"\${$_lp_var}\""
    if [[ -z "$_lp_val" ]]; then
        echo "lp: warning: '$_lp_var' is unset after loading config." >&2
    fi
done
unset _lp_var _lp_val

# Sets WORKTREE_DIR and BUNDLE_DIR for a given branch name.
# Usage: lp_branch_vars <branch-name>
lp_branch_vars() {
    local branch="$1"
    WORKTREE_DIR="$BASE_PROJECT_DIR/${MAIN_REPO_NAME}-$branch"
    BUNDLE_DIR="$BUNDLES_DIR/$branch"
}

# Detects if the current directory is within a managed worktree.
# Sets LP_DETECTED_WORKTREE_DIR and LP_DETECTED_BRANCH.
# Returns 0 if found, 1 otherwise.
lp_detect_worktree() {
    local current_dir
    current_dir=$(pwd)

    if [[ "$current_dir" == "$BASE_PROJECT_DIR/${MAIN_REPO_NAME}-"* ]]; then
        local branch="${current_dir#$BASE_PROJECT_DIR/${MAIN_REPO_NAME}-}"
        branch="${branch%%/*}"
        LP_DETECTED_BRANCH="$branch"
        LP_DETECTED_WORKTREE_DIR="$BASE_PROJECT_DIR/${MAIN_REPO_NAME}-$branch"
        return 0
    elif [[ "$current_dir" == "$MAIN_REPO_DIR"* ]]; then
        LP_DETECTED_BRANCH="master"
        LP_DETECTED_WORKTREE_DIR="$MAIN_REPO_DIR"
        return 0
    fi

    return 1
}
