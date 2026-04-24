#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"

main() {
	# Initialize with namespace "portal" and command "buildLang"
	lp_init_command "portal" "buildLang" "$@" || {
		local ec=$?
		[[ $ec -eq 255 ]] && return 0 || return $ec
	}

	# Detect if we are in a worktree to run inside it
	local worktree_dir
	if lp_detect_worktree; then
		worktree_dir="$LP_DETECTED_WORKTREE_DIR"
	else
		# If not in a managed worktree, check if we are in a git repo
		if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			worktree_dir=$(git rev-parse --show-toplevel)
		else
			lp_error "Error: Not in a Liferay Portal repository or worktree."
			return 1
		fi
	fi

	local lang_module_dir="$worktree_dir/modules/apps/portal-language/portal-language-lang"

	if [[ ! -d "$lang_module_dir" ]]; then
		lp_error "Error: Could not find portal-language-lang directory at $lang_module_dir"
		return 1
	fi

	lp_info "Changing directory to $lang_module_dir"
	cd "$lang_module_dir" || return 1

	lp_info "Running buildLang task"
	
	# Execute lp portal gw buildLang by sourcing the gw script
	# This ensures we use the project's gradle wrapper logic
	set -- "buildLang"
	source "$_LP_SCRIPTS_DIR/commands/portal/gw.sh"
}

main "$@"
