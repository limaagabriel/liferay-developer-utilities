#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

clean_up_existing_session() {
	local session_name="$1"

	if tmux has-session -t "$session_name" 2>/dev/null; then
		lp_step 1 3 "Cleaning up existing tmux session '$session_name'"

		tmux kill-session -t "$session_name"
	fi
}

remove_existing_bundle() {
	local bundle_dir="$1"

	if [[ -d "$bundle_dir" ]]; then
		lp_step 2 3 "Removing existing bundle directory '$bundle_dir'"

		rm -rf "$bundle_dir"
	fi
}

start_build_in_tmux() {
	local session_name="$1"
	local worktree_dir="$2"
	local user_shell="${SHELL:-bash}"

	lp_step 3 3 "Starting build and bundle in tmux session '$session_name'"
	lp_info "Command: lp bundle build -y && lp bundle start"

	tmux new-session -d -s "$session_name" -c "$worktree_dir" "$user_shell -ic 'source \"$_LP_SCRIPTS_DIR/lp.sh\"; lp bundle build -y && lp bundle start; exec $user_shell'"

	lp_info "Monitoring the build:"
	lp_info "  tmux attach -t $session_name"
	lp_info ""
}

get_user_verdict() {
	local current_commit="$1"

	lp_info "Once the portal is ready, provide your verdict below."

	while true; do
		read -p "Result for $current_commit? [g]ood / [b]ad / [s]kip: " choice

		case "$choice" in
			g|good)
				lp_success "Marking $current_commit as GOOD"

				return 0 2>/dev/null || exit 0
				;;
			b|bad)
				lp_error "Marking $current_commit as BAD"

				return 1 2>/dev/null || exit 1
				;;
			s|skip)
				lp_info "Skipping $current_commit"

				return 125 2>/dev/null || exit 125
				;;
			*)
				lp_info "Invalid choice. Please enter g, b, or s."
				;;
		esac
	done
}

main() {
	lp_init_command "git" "bisect-step" "$@"

	local branch="$1"

	if [[ -z "$branch" ]]; then
		lp_error "Error: Branch name is required for bisect-step."

		return 1 2>/dev/null || exit 1
	fi

	lp_branch_vars "$branch"

	local session_name="lp-bisect-$branch"
	local current_commit=$(git rev-parse --short HEAD)

	echo ""
	lp_info "------------------------------------------------------------"
	lp_info "Bisection Step: Testing commit $current_commit"

	git bisect log | grep -v "^#" | head -n 1
	echo ""

	clean_up_existing_session "$session_name"
	remove_existing_bundle "$BUNDLE_DIR"
	start_build_in_tmux "$session_name" "$WORKTREE_DIR"
	get_user_verdict "$current_commit"
}

main "$@"
