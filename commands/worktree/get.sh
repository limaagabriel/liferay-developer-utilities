#!/bin/bash
# Usage: lp worktree get
# Returns the current reference branch for the session.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

lp_info "${LP_WORKTREE_REFERENCE_BRANCH:-master}"
