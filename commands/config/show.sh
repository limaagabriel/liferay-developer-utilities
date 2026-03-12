#!/bin/bash
# Usage: lp config [show]

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Show the currently resolved lp configuration."
    echo ""
    echo "Usage: lp config"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp config"
    exit 0
fi

_LP_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"

if [[ -f "$_LP_USER_CONFIG" ]]; then
    lp_info "Config file: $_LP_USER_CONFIG"
else
    lp_info "Config file: (none — using built-in defaults)"
fi

source "$_LP_SCRIPTS_DIR/config.sh" 2>/dev/null || true

# If config.sh returned early (no user config), the defaults are not set.
# Apply them directly here so show always prints something useful.
BASE_PROJECT_DIR="${BASE_PROJECT_DIR:=$HOME/dev/projects}"
MAIN_REPO_NAME="${MAIN_REPO_NAME:=liferay-portal}"
MAIN_REPO_DIR="${MAIN_REPO_DIR:=$BASE_PROJECT_DIR/$MAIN_REPO_NAME}"
BUNDLES_DIR="${BUNDLES_DIR:=$HOME/dev/bundles}"
ENABLE_AUTOCOMPLETE="${ENABLE_AUTOCOMPLETE:=yes}"

echo ""
lp_info "BASE_PROJECT_DIR    = $BASE_PROJECT_DIR"
lp_info "MAIN_REPO_NAME      = $MAIN_REPO_NAME"
lp_info "MAIN_REPO_DIR       = $MAIN_REPO_DIR"
lp_info "BUNDLES_DIR         = $BUNDLES_DIR"
lp_info "ENABLE_AUTOCOMPLETE = $ENABLE_AUTOCOMPLETE"
