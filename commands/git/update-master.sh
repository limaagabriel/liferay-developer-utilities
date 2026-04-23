#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

update_master_branch() {
	local main_repo_dir="$1"

	lp_step 1 5 "Navigating to master worktree: $main_repo_dir"

	cd "$main_repo_dir" || { return 1 2>/dev/null || exit 1; }

	lp_step 2 5 "Checking out master branch"

	lp_run git checkout master || return $?

	lp_step 3 5 "Fetching all remotes"

	lp_run git fetch --all || return $?

	lp_step 4 5 "Pulling from upstream master"

	lp_run git pull upstream master || return $?

	lp_step 5 5 "Pushing to origin master"

	lp_run git push origin master || return $?

	lp_success "Successfully updated master branch."
}

main() {
	lp_init_command "git" "update-master" "$@"

	update_master_branch "$MAIN_REPO_DIR"
}

main "$@"
