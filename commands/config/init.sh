#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "config" "init" "$@"

check_existing_config() {
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"

    if [[ -f "$config_file" ]]; then
        lp_info "A config file already exists at '$config_file'."
        printf "Overwrite it? [y/N] "
        read -r confirm
        case "$confirm" in
            [yY]|[yY][eE][sS]) ;;
            *)
                lp_info "Aborted. Existing config left unchanged."
                return 0 2>/dev/null || exit 0
                ;;
        esac
    fi
}

prompt_for_value() {
    local var_name="$1"
    local description="$2"
    local default_value="$3"
    local input_value

    printf "%s [%s]: " "$description" "$default_value"
    read -r input_value

    if [[ -z "$input_value" ]]; then
        printf -v "$var_name" '%s' "$default_value"
    else
        printf -v "$var_name" '%s' "$input_value"
    fi
}

prompt_for_all_values() {
    lp_info "Creating per-user lp configuration."
    lp_info "Press Enter to accept the default shown in brackets."
    echo ""

    prompt_for_value BASE_PROJECT_DIR_VAL "Base project directory" "$HOME/dev/projects"
    prompt_for_value MAIN_REPO_NAME_VAL "Main repository name" "liferay-portal"
    prompt_for_value EE_REPO_NAME_VAL "EE repository name" "liferay-portal-ee"
    prompt_for_value BUNDLES_DIR_VAL "Bundles directory" "$HOME/dev/bundles"
    prompt_for_value LIFERAY_USER_VAL "Liferay user name (for property files)" "$(whoami)"
    prompt_for_value ENABLE_AUTOCOMPLETE_VAL "Enable tab completion (yes/no)" "yes"
    prompt_for_value ENABLE_ALIASES_VAL "Enable simplified aliases (yes/no)" "yes"
    prompt_for_value WORKTREE_LIMIT_VAL "Worktree limit" "8"
    prompt_for_value DEFAULT_DATABASE_VAL "Default database (hypersonic|mysql)" "hypersonic"
    prompt_for_value SESSION_CUSTOM_WINDOWS_VAL "Custom tmux windows (name1:cmd1,name2:cmd2)" ""
}

write_config_file() {
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"
    local config_dir="$(dirname "$config_file")"

    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi

    cat > "$config_file" <<EOF
# lp per-user configuration
# This file is sourced as bash (KEY=value format).
# Do NOT add executable statements, function definitions, or arbitrary code.
# Regenerate with: lp config init

BASE_PROJECT_DIR=$BASE_PROJECT_DIR_VAL
MAIN_REPO_NAME=$MAIN_REPO_NAME_VAL
EE_REPO_NAME=$EE_REPO_NAME_VAL
BUNDLES_DIR=$BUNDLES_DIR_VAL
LIFERAY_USER=$LIFERAY_USER_VAL
ENABLE_AUTOCOMPLETE=$ENABLE_AUTOCOMPLETE_VAL
ENABLE_ALIASES=$ENABLE_ALIASES_VAL
WORKTREE_LIMIT=$WORKTREE_LIMIT_VAL
DEFAULT_DATABASE=$DEFAULT_DATABASE_VAL
SESSION_CUSTOM_WINDOWS=$SESSION_CUSTOM_WINDOWS_VAL
EOF
}

main() {
    check_existing_config
    prompt_for_all_values
    write_config_file

    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"
    echo ""
    lp_success "Config written to '$config_file'."
    lp_info "Run 'lp config' to verify the resolved values."
}

main "$@"
