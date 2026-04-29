#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "env" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            --help|-h)    shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                if [[ -z "$BRANCH" ]]; then
                    BRANCH="$1"
                else
                    lp_error "Too many arguments: $1"
                    return 1 2>/dev/null || exit 1
                fi
                shift
                ;;
        esac
    done

    lp_resolve_branch --reference --default-master
}

main() {
    parse_arguments "$@" || return $?

    local offset http osgi
    offset=$(lp_bundle_offset "$BRANCH")
    http=$(lp_bundle_port http "$BRANCH")
    osgi=$(lp_bundle_port osgi "$BRANCH")

    echo "export LP_BUNDLE_BRANCH=\"$BRANCH\""
    echo "export LP_BUNDLE_PORT_OFFSET=\"$offset\""
    echo "export PORTAL_URL=\"http://localhost:$http\""
    echo "export LIFERAY_HTTP_PORT=\"$http\""
    echo "export LIFERAY_OSGI_CONSOLE=\"localhost:$osgi\""
}

main "$@"
