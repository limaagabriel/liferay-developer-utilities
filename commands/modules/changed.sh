#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "modules" "changed" "$@"

parse_arguments() {
    UNCOMMITTED=0
    BASE_BRANCH="master"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--uncommitted)
                UNCOMMITTED=1
                shift
                ;;
            *)
                BASE_BRANCH="$1"
                shift
                ;;
        esac
    done
}

validate_environment() {
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$GIT_ROOT" ]]; then
        lp_error "Error: Not in a git repository."
        return 1 2>/dev/null || exit 1
    fi
}

get_changed_files() {
    if [[ $UNCOMMITTED -eq 1 ]]; then
        if [[ "${VERBOSE:-0}" -eq 1 ]]; then
            RAW_CHANGED_FILES=$( { git diff --name-only HEAD; git diff --name-only --cached; git ls-files --others --exclude-standard; } | sort -u )
        else
            RAW_CHANGED_FILES=$( { git diff --name-only HEAD; git diff --name-only --cached; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u )
        fi
    else
        if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
            lp_error "Error: Branch '$BASE_BRANCH' not found. Make sure it exists."
            return 1 2>/dev/null || exit 1
        fi

        local merge_base
        merge_base=$(git merge-base "$BASE_BRANCH" HEAD 2>/dev/null || echo "$BASE_BRANCH")

        if [[ "${VERBOSE:-0}" -eq 1 ]]; then
            RAW_CHANGED_FILES=$( { git diff --name-only "$merge_base"; git ls-files --others --exclude-standard; } | sort -u )
        else
            RAW_CHANGED_FILES=$( { git diff --name-only "$merge_base"; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u )
        fi
    fi

    CHANGED_FILES=$(echo "$RAW_CHANGED_FILES" | grep "^modules/")
}

find_module_root() {
    local dir_path="$1"
    
    while [[ -n "$dir_path" && "$dir_path" != "." && "$dir_path" != "/" ]]; do
        if [[ -f "$dir_path/bnd.bnd" || -f "$dir_path/package.json" || -f "$dir_path/client-extension.yaml" ]]; then
             echo "$dir_path"
             return
        fi

        if [[ -d "$dir_path/src" && ( -f "$dir_path/build.gradle" || -f "$dir_path/pom.xml" || -f "$dir_path/build.xml" ) ]]; then
             echo "$dir_path"
             return
        fi

        local parent_dir
        parent_dir=$(dirname "$dir_path")
        if [[ "$parent_dir" == "$dir_path" ]]; then
            break
        fi
        dir_path="$parent_dir"
    done
}

get_changed_modules() {
    if [[ -z "$CHANGED_FILES" ]]; then
        return
    fi

    local changed_dirs
    changed_dirs=$(echo "$CHANGED_FILES" | sed -E -e 's,[^/]*$,,g' -e 's,/$,,g' | grep -v '^$' | sort -u)

    if [[ -z "$changed_dirs" ]]; then
        return
    fi

    echo "$changed_dirs" | while read -r dir; do
        find_module_root "$dir"
    done | sort -u
}

main() {
    lp_init_command "modules" "changed" "$@" || {
        local ec=$?
        [[ $ec -eq 255 ]] && return 0 || return $ec
    }
    parse_arguments "$@"
    validate_environment

    (
        cd "$GIT_ROOT" || { return 1 2>/dev/null || exit 1; }

        get_changed_files

        local changed_modules
        changed_modules=$(get_changed_modules)

        if [[ -z "$changed_modules" ]]; then
            lp_info "No changed modules found compared to '$BASE_BRANCH'."
        else
            echo "$changed_modules"
        fi
    )
}

main "$@"
