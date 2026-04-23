#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

update_ee_branch() {
	local ee_repo_dir="$1"

	lp_step 1 5 "Navigating to EE repository: $ee_repo_dir"

	cd "$ee_repo_dir" || { return 1 2>/dev/null || exit 1; }

	lp_step 2 5 "Checking out ee branch"

	lp_run git checkout ee || return $?

	lp_step 3 5 "Fetching all remotes"

	lp_run git fetch --all || return $?

	lp_step 4 5 "Pulling from upstream ee"

	lp_run git pull upstream ee || return $?

	lp_step 5 5 "Pushing to origin ee"

	lp_run git push origin ee || return $?

	lp_success "Successfully updated ee branch."
}

main() {
	lp_init_command "git" "update-ee" "$@"

	update_ee_branch "$EE_REPO_DIR"
}

main "$@"
