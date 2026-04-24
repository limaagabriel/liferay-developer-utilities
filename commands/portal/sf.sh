#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"

main() {
	# Initialize with namespace "portal" and command "sf"
	# Set VERBOSE=1 before lp_init_command to make it default.
	VERBOSE=1
	lp_init_command "portal" "sf" "$@" || return 1

	# Early exit if help was requested (lp_init_command returns 0 but does not stop caller when sourced)
	for arg in "$@"; do
		if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
			return 0
		fi
	done

	local ant_task="format-source-current-branch"
	local ant_args=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-a|--all)
				ant_task="format-source-all"
				shift
				;;
			-e|--extension)
				if [[ -z "$2" ]]; then
					lp_error "Error: -e/--extension requires an extension (without dot)."
					return 1
				fi
				ant_args+=("-Dsource.file.extensions=$2")
				shift 2
				;;
			-c|--check)
				if [[ -z "$2" ]]; then
					lp_error "Error: -c/--check requires a check name."
					return 1
				fi
				ant_args+=("-Dsource.check.names=$2")
				shift 2
				;;
			-v|--verbose|-q|--quiet|-h|--help)
				# Already handled by lp_init_command, but we need to shift them out
				shift
				;;
			*)
				# Ignore unknown arguments or handle them if needed
				shift
				;;
		esac
	done

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

	local portal_impl_dir="$worktree_dir/portal-impl"

	if [[ ! -d "$portal_impl_dir" ]]; then
		lp_error "Error: Could not find portal-impl directory at $portal_impl_dir"
		return 1
	fi

	lp_info "Running source formatter ($ant_task) in $portal_impl_dir"
	cd "$portal_impl_dir" || return 1

	lp_run ant "$ant_task" "${ant_args[@]}"
}

main "$@"
