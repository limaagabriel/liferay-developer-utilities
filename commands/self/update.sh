#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "self" "update" "$@"

validate_environment() {
    if [[ ! -d "$_LP_SCRIPTS_DIR/.git" ]]; then
        lp_error "Error: $_LP_SCRIPTS_DIR is not a git repository. Cannot update."
        return 1 2>/dev/null || exit 1
    fi
}

pull_latest_changes() {
    lp_step 1 1 "Pulling latest changes in $_LP_SCRIPTS_DIR"
    
    cd "$_LP_SCRIPTS_DIR" || { return 1 2>/dev/null || exit 1; }
    
    if [[ $VERBOSE -eq 1 ]]; then
        git pull
    else
        git pull >/dev/null 2>&1
    fi
}

main() {
    validate_environment
    if pull_latest_changes; then
        lp_success "lp has been updated successfully."
    else
        lp_error "Failed to update lp."
        return 1 2>/dev/null || exit 1
    fi
}

main "$@"
