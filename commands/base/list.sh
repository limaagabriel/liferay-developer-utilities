#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "base" "list" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    NAMES_ONLY=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --names)       NAMES_ONLY=1; shift ;;
            --verbose|-v)  shift ;;
            --help|-h)     shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                lp_error "Too many arguments: $1"
                return 1 2>/dev/null || exit 1
                ;;
        esac
    done
}

list_names() {
    [[ -d "$BASE_BUNDLES_DIR" ]] || return 0
    local entry
    for entry in "$BASE_BUNDLES_DIR"/*/; do
        [[ -d "$entry" ]] || continue
        basename "$entry"
    done
}

list_table() {
    if [[ ! -d "$BASE_BUNDLES_DIR" ]]; then
        lp_info "No base bundles. Run 'lp base build <name>' to create one."
        return 0
    fi

    local has_any=0
    local entry
    for entry in "$BASE_BUNDLES_DIR"/*/; do
        [[ -d "$entry" ]] || continue
        has_any=1
        break
    done

    if [[ $has_any -eq 0 ]]; then
        lp_info "No base bundles. Run 'lp base build <name>' to create one."
        return 0
    fi

    printf "  %-20s %-8s %-6s %-10s %s\n" "NAME" "SIZE" "AGE" "COMMIT" "BRANCH"

    local name size age commit branch built_at
    for entry in "$BASE_BUNDLES_DIR"/*/; do
        [[ -d "$entry" ]] || continue
        name=$(basename "$entry")
        size=$(du -sh "$entry" 2>/dev/null | cut -f1)
        built_at=$(_lp_bundle_meta_get "$entry" "LP_BUNDLE_BUILT_AT")
        age=$(_lp_bundle_format_age "$built_at")
        commit=$(_lp_bundle_meta_get "$entry" "LP_BUNDLE_COMMIT_SHORT")
        [[ -z "$commit" ]] && commit="?"
        branch=$(_lp_bundle_meta_get "$entry" "LP_BUNDLE_BRANCH")
        [[ -z "$branch" ]] && branch="?"
        printf "  %-20s %-8s %-6s %-10s %s\n" "$name" "$size" "$age" "$commit" "$branch"
    done
}

main() {
    parse_arguments "$@" || return $?

    if [[ $NAMES_ONLY -eq 1 ]]; then
        list_names
    else
        list_table
    fi
}

main "$@"
