#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "config" "show" "$@"

display_config_source() {
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"

    if [[ -f "$config_file" ]]; then
        lp_info "Config file: $config_file"
    else
        lp_info "Config file: (none — using built-in defaults)"
    fi
}

display_config_values() {
    echo ""
    lp_info "BASE_PROJECT_DIR           = $BASE_PROJECT_DIR"
    lp_info "MAIN_REPO_NAME             = $MAIN_REPO_NAME"
    lp_info "EE_REPO_NAME               = $EE_REPO_NAME"
    lp_info "MAIN_REPO_DIR              = $MAIN_REPO_DIR"
    lp_info "EE_REPO_DIR                = $EE_REPO_DIR"
    lp_info "BUNDLES_DIR                = $BUNDLES_DIR"
    lp_info "LIFERAY_USER               = $LIFERAY_USER"
    lp_info "ENABLE_AUTOCOMPLETE        = $ENABLE_AUTOCOMPLETE"
    lp_info "ENABLE_ALIASES             = $ENABLE_ALIASES"
    lp_info "WORKTREE_LIMIT             = $WORKTREE_LIMIT"
    lp_info "DEFAULT_DATABASE           = $DEFAULT_DATABASE"
    lp_info "SESSION_CUSTOM_WINDOWS     = $SESSION_CUSTOM_WINDOWS"
}

main() {
    display_config_source
    display_config_values
}

main "$@"
