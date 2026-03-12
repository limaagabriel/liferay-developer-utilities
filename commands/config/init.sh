#!/bin/bash
# Usage: lp config init

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Interactively create the per-user lp configuration file."
    echo ""
    echo "Usage: lp config init"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp config init"
    exit 0
fi

_LP_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"

# Check if config file already exists (task 4.3)
if [[ -f "$_LP_USER_CONFIG" ]]; then
    lp_info "A config file already exists at '$_LP_USER_CONFIG'."
    printf "Overwrite it? [y/N] "
    read -r _confirm
    case "$_confirm" in
        [yY]|[yY][eE][sS]) ;;
        *)
            lp_info "Aborted. Existing config left unchanged."
            exit 0
            ;;
    esac
fi

lp_info "Creating per-user lp configuration."
lp_info "Press Enter to accept the default shown in brackets."
echo ""

# Prompt helper: _lp_prompt <var_name> <description> <default>
_lp_prompt() {
    local var="$1"
    local desc="$2"
    local default="$3"
    printf "%s [%s]: " "$desc" "$default"
    read -r _input
    if [[ -z "$_input" ]]; then
        printf -v "$var" '%s' "$default"
    else
        printf -v "$var" '%s' "$_input"
    fi
}

# Prompt for each variable (task 4.1 / 4.2)
_lp_prompt _BASE_PROJECT_DIR "Base project directory" "$HOME/dev/projects"
_lp_prompt _MAIN_REPO_NAME   "Main repository name"   "liferay-portal"
_lp_prompt _MAIN_REPO_DIR    "Main repository path"   "$_BASE_PROJECT_DIR/$_MAIN_REPO_NAME"
_lp_prompt _BUNDLES_DIR      "Bundles directory"       "$HOME/dev/bundles"
_lp_prompt _ENABLE_AUTOCOMPLETE "Enable tab completion (yes/no)" "yes"

# Create config directory if needed (task 4.4)
_LP_CONFIG_DIR="$(dirname "$_LP_USER_CONFIG")"
if [[ ! -d "$_LP_CONFIG_DIR" ]]; then
    mkdir -p "$_LP_CONFIG_DIR"
fi

# Write the config file (task 4.5)
cat > "$_LP_USER_CONFIG" <<EOF
# lp per-user configuration
# This file is sourced as bash (KEY=value format).
# Do NOT add executable statements, function definitions, or arbitrary code.
# Regenerate with: lp config init

BASE_PROJECT_DIR=$_BASE_PROJECT_DIR
MAIN_REPO_NAME=$_MAIN_REPO_NAME
MAIN_REPO_DIR=$_MAIN_REPO_DIR
BUNDLES_DIR=$_BUNDLES_DIR
ENABLE_AUTOCOMPLETE=$_ENABLE_AUTOCOMPLETE
EOF

# Success message (task 4.6)
echo ""
lp_success "Config written to '$_LP_USER_CONFIG'."
lp_info "Run 'lp config' to verify the resolved values."
