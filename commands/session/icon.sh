#!/bin/bash
# Internal command used by tmux to display the bundle running icon.
# Usage: lp session icon <session_name>

# We need to find the scripts directory. 
# Since this script is in commands/session/icon.sh, we can find it relative to itself.
_LP_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "$_LP_SCRIPTS_DIR/lib/session.sh"

if _lp_is_bundle_running "$1"; then
    echo " 🚀"
fi
