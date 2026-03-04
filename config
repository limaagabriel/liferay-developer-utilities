#!/bin/bash
# Liferay Portal development path configuration.
# Source this file in other scripts; do not execute it directly.

# Guard: detect if the script is being executed instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: config must be sourced, not executed."
    echo "Usage: source $(basename "${BASH_SOURCE[0]}")"
    exit 1
fi

BASE_PROJECT_DIR=~/dev/projects
MAIN_REPO_DIR=$BASE_PROJECT_DIR/liferay-portal
BUNDLES_DIR=~/dev/bundles

# Sets WORKTREE_DIR and BUNDLE_DIR for a given branch name.
# Usage: lp_branch_vars <branch-name>
lp_branch_vars() {
    local branch="$1"
    WORKTREE_DIR="$BASE_PROJECT_DIR/liferay-portal-$branch"
    BUNDLE_DIR="$BUNDLES_DIR/$branch"
}
