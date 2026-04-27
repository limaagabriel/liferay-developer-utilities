#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"

VERBOSE=1
lp_init_command "portal" "sf" "$@"

parse_arguments() {
	ANT_TASK="format-source-current-branch"
	ANT_ARGS=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-a|--all)
				ANT_TASK="format-source-all"
				shift
				;;
			-e|--extension)
				if [[ -z "$2" ]]; then
					lp_error "-e/--extension requires an extension (without dot)."
					return 1
				fi
				ANT_ARGS+=("-Dsource.file.extensions=$2")
				shift 2
				;;
			-c|--check)
				if [[ -z "$2" ]]; then
					lp_error "-c/--check requires a check name."
					return 1
				fi
				ANT_ARGS+=("-Dsource.check.names=$2")
				shift 2
				;;
			*) shift ;;
		esac
	done
}

main() {
	parse_arguments "$@" || return $?

	local workspace_dir
	workspace_dir=$(lp_resolve_workspace_dir) || return $?

	local portal_impl_dir="$workspace_dir/portal-impl"
	if [[ ! -d "$portal_impl_dir" ]]; then
		lp_error "Could not find portal-impl directory at $portal_impl_dir"
		return 1
	fi

	lp_info "Running source formatter ($ANT_TASK) in $portal_impl_dir"
	cd "$portal_impl_dir" || return 1
	lp_run ant "$ANT_TASK" "${ANT_ARGS[@]}"
}

main "$@"
