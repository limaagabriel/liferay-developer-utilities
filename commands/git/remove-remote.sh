#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

remove_remote() {
	local name="$1"

	lp_step 1 2 "Navigating to master worktree: $MAIN_REPO_DIR"

	cd "$MAIN_REPO_DIR" || { return 1 2>/dev/null || exit 1; }

	lp_step 2 2 "Checking if remote '$name' exists"

	if git remote | grep -q "^$name$"; then
		lp_run git remote remove "$name" || return $?
		lp_success "Remote '$name' removed."
	else
		lp_info "Remote '$name' does not exist. Nothing to do."
	fi
}

main() {
	lp_init_command "git" "remove-remote" "$@"

	local name=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--verbose|-v)
				shift
				;;
			-*)
				lp_error "Unknown option: $1"
				lp_error "Usage: lp git remove-remote [-v] <name>"

				return 1 2>/dev/null || exit 1
				;;
			*)
				name="$1"
				shift
				;;
		esac
	done

	if [[ -z "$name" ]]; then
		lp_error "Error: Remote name is required."
		lp_error "Usage: lp git remove-remote [-v] <name>"

		return 1 2>/dev/null || exit 1
	fi

	remove_remote "$name"
}

main "$@"
