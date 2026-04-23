#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

add_remote() {
	local name="$1"
	local url="$2"

	lp_step 1 3 "Navigating to master worktree: $MAIN_REPO_DIR"

	cd "$MAIN_REPO_DIR" || { return 1 2>/dev/null || exit 1; }

	lp_step 2 3 "Checking if remote '$name' exists"

	if git remote | grep -q "^$name$"; then
		lp_info "Remote '$name' already exists. Skipping 'git remote add'."
	else
		lp_run git remote add "$name" "$url" || return $?
		lp_success "Remote '$name' added."
	fi

	lp_step 3 3 "Fetching all remotes"

	lp_run git fetch --all || return $?

	lp_success "Successfully added remote '$name' and fetched all."
}

main() {
	lp_init_command "git" "add-remote" "$@"

	local name=""
	local url=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--verbose|-v)
				shift
				;;
			-*)
				lp_error "Unknown option: $1"
				lp_error "Usage: lp git add-remote [-v] <name> <url>"

				return 1 2>/dev/null || exit 1
				;;
			*)
				if [[ -z "$name" ]]; then
					name="$1"
				elif [[ -z "$url" ]]; then
					url="$1"
				fi

				shift
				;;
		esac
	done

	if [[ -z "$name" || -z "$url" ]]; then
		lp_error "Error: Both remote name and URL are required."
		lp_error "Usage: lp git add-remote [-v] <name> <url>"

		return 1 2>/dev/null || exit 1
	fi

	add_remote "$name" "$url"
}

main "$@"
