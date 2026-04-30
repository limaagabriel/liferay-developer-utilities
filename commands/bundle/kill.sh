#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "kill" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

parse_arguments() {
    ASSUME_YES=0
    BRANCH=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)     ASSUME_YES=1; shift ;;
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

    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"
}

confirm_kill() {
    if [[ "$ASSUME_YES" -eq 1 ]]; then
        return 0
    fi

    local confirm
    read -p " Kill bundle for '$BRANCH' (pid $1, port $2)? [y/N] " confirm
    if [[ "$confirm" != "y" ]]; then
        lp_info "Aborted."
        return 1
    fi
}

main() {
    parse_arguments "$@" || return $?

    local port
    port=$(lp_bundle_port http "$BRANCH")

    if [[ -z "$port" ]]; then
        lp_error "Could not resolve HTTP port for branch '$BRANCH'."
        return 1 2>/dev/null || exit 1
    fi

    local pid
    pid=$(netstat -tunlp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -n1)

    if [[ -z "$pid" ]]; then
        lp_info "No bundle process listening on port $port (branch '$BRANCH')."
        return 0
    fi

    confirm_kill "$pid" "$port" || return 0

    lp_step 1 1 "Killing bundle for '$BRANCH' (pid $pid, port $port)"
    if lp_run kill -9 "$pid"; then
        lp_success "Done!"
    else
        lp_error "Failed to kill process $pid"
        return 1 2>/dev/null || exit 1
    fi
}

main "$@"
