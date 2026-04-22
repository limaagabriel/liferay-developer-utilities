#!/bin/bash
# Usage: lp modules changed [base_branch]
# List all changed modules in the current branch comparing to a base branch.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "List all changed modules in the current branch comparing to a base branch."
    echo ""
    echo "Usage: lp modules changed [base_branch]"
    echo ""
    echo "Arguments:"
    echo "  base_branch  The branch to compare against (defaults to master)"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp modules changed"
    echo "  lp modules changed ee"
    return 0 2>/dev/null || exit 0
fi

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$GIT_ROOT" ]]; then
    lp_error "Error: Not in a git repository."
    exit 1
fi

BASE_BRANCH=${1:-master}

# Use a subshell to ensure we operate from the git root
# and don't affect the caller's PWD if sourced.
(
    cd "$GIT_ROOT" || exit 1

    if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
        lp_error "Error: Branch '$BASE_BRANCH' not found. Make sure it exists."
        exit 1
    fi

    # Get the merge base to avoid including changes made to the base branch since divergence
    MERGE_BASE=$(git merge-base "$BASE_BRANCH" HEAD 2>/dev/null || echo "$BASE_BRANCH")

    # Get list of changed files compared to merge base
    # git diff "$MERGE_BASE" includes both committed changes on the branch AND uncommitted changes in the working tree
    # Also include untracked files
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then
        RAW_CHANGED_FILES=$( { git diff --name-only "$MERGE_BASE"; git ls-files --others --exclude-standard; } | sort -u )
    else
        RAW_CHANGED_FILES=$( { git diff --name-only "$MERGE_BASE"; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u )
    fi

    # Filter: Only include changes within the 'modules/' directory.
    CHANGED_FILES=$(echo "$RAW_CHANGED_FILES" | grep "^modules/")

    if [[ -z "$CHANGED_FILES" ]]; then
        lp_info "No changed files found in modules/ compared to '$BASE_BRANCH'."
        exit 0
    fi

    # Function to find the module root for a given file
    find_module_root() {
        local dir_path="$1"
        
        while [[ -n "$dir_path" && "$dir_path" != "." && "$dir_path" != "/" ]]; do
            # Module markers
            if [[ -f "$dir_path/bnd.bnd" || -f "$dir_path/package.json" || -f "$dir_path/client-extension.yaml" ]]; then
                 echo "$dir_path"
                 return
            fi

            # Special case for some modules that only have build.gradle/xml and are in modules/
            if [[ -d "$dir_path/src" && ( -f "$dir_path/build.gradle" || -f "$dir_path/pom.xml" || -f "$dir_path/build.xml" ) ]]; then
                 echo "$dir_path"
                 return
            fi

            # Check if we've reached a point where dirname won't change anything
            local parent_dir
            parent_dir=$(dirname "$dir_path")
            if [[ "$parent_dir" == "$dir_path" ]]; then
                break
            fi
            dir_path="$parent_dir"
        done
    }

    # Extract unique directories from changed files
    CHANGED_DIRS=$(echo "$CHANGED_FILES" | sed -E -e 's,[^/]*$,,g' -e 's,/$,,g' | grep -v '^$' | sort -u)

    if [[ -z "$CHANGED_DIRS" ]]; then
        # Check if any files are at the root
        # (they don't belong to a module, so we can just exit)
        lp_info "No changed modules found compared to '$BASE_BRANCH'."
        exit 0
    fi

    CHANGED_MODULES=$(
        echo "$CHANGED_DIRS" | while read -r dir; do
            find_module_root "$dir"
        done | sort -u
    )

    if [[ -z "$CHANGED_MODULES" ]]; then
        lp_info "No changed modules found compared to '$BASE_BRANCH'."
    else
        echo "$CHANGED_MODULES"
    fi
)
