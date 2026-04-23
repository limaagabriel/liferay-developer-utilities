#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

check_dependencies() {
	if ! command -v fzf >/dev/null 2>&1; then
		lp_error "Error: 'fzf' is not installed. Please install it to use this command."

		return 1 2>/dev/null || exit 1
	fi

	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		lp_error "Error: Not in a git repository."

		return 1 2>/dev/null || exit 1
	fi
}

find_module_directory() {
	local git_dir="$1"

	git -C "${git_dir}" ls-files -- \
		':!:**/samples/**' \
		':!:**/src/**' \
		':!:portal-web/test/**' \
		\
		'*.bnd' \
		'*build.gradle' \
		'*build.xml' \
		'*client-extension.yaml' \
		'*package.json' \
		'*pom.xml' \
		'*settings.gradle' \
		'*test.properties' |
		sed -E \
			-e 's,[^/]*$,,g' \
			-e 's,/$,,g' \
			-e '/^$/d' |
		uniq |
		fzf \
			--exit-0 \
			--no-multi \
			--select-1
}

main() {
	lp_init_command "portal" "cdm" "$@"

	check_dependencies || return 1 2>/dev/null || exit 1

	local git_dir="$(git rev-parse --show-toplevel)"
	local module_dir=$(find_module_directory "$git_dir")

	if [[ -n "${module_dir}" ]]; then
		cd "${git_dir}/${module_dir}" || return 1 2>/dev/null || exit 1
		lp_info "Moved to module: ${module_dir}"
	fi
}

main "$@"
