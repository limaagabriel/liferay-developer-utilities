#!/bin/bash

source "$_LP_SCRIPTS_DIR/lib/init.sh"

download_patch() {
	local url="$1"
	local tmp_patch="$2"

	lp_step 1 2 "Downloading patch from $url"

	if ! curl -fsSL "$url" -o "$tmp_patch"; then
		lp_error "Failed to download patch from: $url"

		return 1 2>/dev/null || exit 1
	fi
}

apply_patch() {
	local commit="$1"
	local tmp_patch="$2"

	lp_step 2 2 "Applying patch"

	if [[ "$commit" -eq 1 ]]; then
		lp_run git am "$tmp_patch" || return $?
	else
		lp_run git apply "$tmp_patch" || return $?
	fi

	lp_success "Patch applied successfully."
}

main() {
	lp_init_command "git" "patch" "$@"

	local commit=0
	local url=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--commit|-c)
				commit=1
				shift
				;;
			--verbose|-v)
				shift
				;;
			-*)
				lp_error "Unknown option: $1"
				lp_error "Usage: lp git patch [-c] [-v] <url>"

				return 1 2>/dev/null || exit 1
				;;
			*)
				url="$1"
				shift
				;;
		esac
	done

	if [[ -z "$url" ]]; then
		lp_error "Usage: lp git patch [-c] [-v] <url>"

		return 1 2>/dev/null || exit 1
	fi

	local tmp_patch=$(mktemp /tmp/lp-patch-XXXXXXXX.patch)
	trap "rm -f '$tmp_patch'" EXIT

	download_patch "$url" "$tmp_patch"
	apply_patch "$commit" "$tmp_patch"
}

main "$@"
