#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "portal" "buildLang" "$@"

main() {
	local workspace_dir
	workspace_dir=$(lp_resolve_workspace_dir) || return $?

	local lang_module_dir="$workspace_dir/modules/apps/portal-language/portal-language-lang"
	if [[ ! -d "$lang_module_dir" ]]; then
		lp_error "Could not find portal-language-lang directory at $lang_module_dir"
		return 1
	fi

	lp_info "Changing directory to $lang_module_dir"
	cd "$lang_module_dir" || return 1

	lp_info "Running buildLang task"
	set -- "buildLang"
	source "$_LP_SCRIPTS_DIR/commands/portal/gw.sh"
}

main "$@"
