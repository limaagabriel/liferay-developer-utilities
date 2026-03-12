#!/bin/bash
# Usage: source lp worktree unset
# Resets the reference branch to master.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

unset LP_WORKTREE_REFERENCE_BRANCH
lp_info "Reference branch reset to master"
