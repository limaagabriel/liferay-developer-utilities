#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

run_bisect() {
	local good_commit="$1"
	local bad_commit="$2"
	local branch="$3"
	local worktree_dir="$4"

	lp_step 1 3 "Navigating to worktree: $worktree_dir"

	cd "$worktree_dir" || { return 1 2>/dev/null || exit 1; }

	lp_step 2 3 "Initializing git bisect from $good_commit to $bad_commit"

	lp_run git bisect start "$bad_commit" "$good_commit"

	lp_step 3 3 "Starting git bisect run"

	lp_info "For each iteration, the bundle will be built and started in tmux."
	lp_info "Tmux session name: lp-bisect-$branch"

	export _LP_SCRIPTS_DIR="$_LP_SCRIPTS_DIR"

	lp_run git bisect run "$_LP_SCRIPTS_DIR/commands/git/bisect-step.sh" "$branch"

	lp_success "Git bisect complete."

	lp_run git bisect log
}

main() {
	lp_init_command "git" "bisect" "$@"

	local good_commit=""
	local bad_commit=""
	local branch=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--good|-g)
				good_commit="$2"
				shift 2
				;;
			--bad|-b)
				bad_commit="$2"
				shift 2
				;;
			--verbose|-v)
				shift
				;;
			-*)
				lp_error "Unknown option: $1"

				return 1 2>/dev/null || exit 1
				;;
			*)
				if [[ -z "$branch" ]]; then
					branch="$1"
				else
					lp_error "Too many arguments: $1"

					return 1 2>/dev/null || exit 1
				fi

				shift
				;;
		esac
	done

	if [[ -z "$good_commit" || -z "$bad_commit" ]]; then
		lp_error "Error: Both --good and --bad commits are required."
		lp_error "Usage: lp git bisect -g <good> -b <bad> [branch]"

		return 1 2>/dev/null || exit 1
	fi

	BRANCH="$branch"
	lp_resolve_branch --reference --default-master --vars
	lp_validate_worktree

	run_bisect "$good_commit" "$bad_commit" "$BRANCH" "$WORKTREE_DIR"
}

main "$@"
