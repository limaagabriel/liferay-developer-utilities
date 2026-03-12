#!/bin/bash
# Usage: source lp portal cdm
# Fuzzy module search and change directory in the current git repository.
# Requires: fzf

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Fuzzy module search and change directory in the current git repository."
    echo ""
    echo "Usage: lp portal cdm"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Note: This command requires 'fzf' to be installed."
    echo ""
    echo "Examples:"
    echo "  lp portal cdm"
    return 0 2>/dev/null || exit 0
fi

# Original cdm logic (cd_module function)
if ! command -v fzf >/dev/null 2>&1; then
    lp_error "Error: 'fzf' is not installed. Please install it to use this command."
    return 1 2>/dev/null || exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    lp_error "Error: Not in a git repository."
    return 1 2>/dev/null || exit 1
fi

local git_dir="$(git rev-parse --show-toplevel)"

local module_dir="$(
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

                #
                # Get the directory name with sed instead of dirname because it is much faster
                #

                sed -E \
                        -e 's,[^/]*$,,g' \
                        \
                        -e 's,/$,,g' \
                        -e '/^$/d' |

                #
                # Remove duplicates because some modules have more than one *.bnd file
                #

                uniq |

                #
                # Pass the results to fzf
                #
                fzf \
                        --exit-0 \
                        --no-multi \
                        --select-1 \
                ;
)"

if [ -n "${module_dir}" ]
then
        cd "${git_dir}/${module_dir}" || return 1 2>/dev/null || exit 1
        lp_info "Moved to module: ${module_dir}"
fi
