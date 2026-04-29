#!/bin/bash
# lib/reference.sh — Helpers for the session's reference branch.
#
# The reference branch is exposed via LP_WORKTREE_REFERENCE_BRANCH so it can
# survive across child processes within the same shell session.

# lp_get_reference_branch
# Echoes the session's reference branch, defaulting to 'master' when unset.
lp_get_reference_branch() {
    echo "${LP_WORKTREE_REFERENCE_BRANCH:-master}"
}

# lp_set_reference_branch <branch>
# Exports the session's reference branch.
lp_set_reference_branch() {
    export LP_WORKTREE_REFERENCE_BRANCH="$1"
}

# lp_unset_reference_branch
# Clears the session's reference branch.
lp_unset_reference_branch() {
    unset LP_WORKTREE_REFERENCE_BRANCH
}
