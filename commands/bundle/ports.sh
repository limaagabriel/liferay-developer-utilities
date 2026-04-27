#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "ports" "$@"

parse_arguments() {
    BRANCH=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) shift ;;
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done

    BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
    BRANCH="${BRANCH:-master}"
}

ports_in_use() {
    local offset=$1
    local ports=($((8080 + offset)) $((8005 + offset)) $((11311 + offset)) $((9201 + offset)) $((9301 + offset)) $((4000 + offset)))
    for port in "${ports[@]}"; do
        nc -z localhost "$port" 2>/dev/null && return 0
    done
    return 1
}

offset_claimed_by_other_bundle() {
    local offset=$1
    for other_bundle in "$BUNDLES_DIR"/*; do
        [[ -d "$other_bundle" && "$other_bundle" != "$BUNDLE_DIR" ]] || continue
        [[ -f "$other_bundle/.worktree-port-offset" ]] || continue
        [[ "$(cat "$other_bundle/.worktree-port-offset")" == "$offset" ]] && return 0
    done
    return 1
}

get_offset() {
    if [[ "$BRANCH" == "master" ]]; then
        echo 0
        return
    fi

    if [[ -f "$OFFSET_FILE" ]]; then
        cat "$OFFSET_FILE"
        return
    fi

    local offset=1
    while true; do
        if ! ports_in_use "$offset" && ! offset_claimed_by_other_bundle "$offset"; then
            echo "$offset" > "$OFFSET_FILE"
            echo "$offset"
            return
        fi
        ((offset++))
    done
}

configure_tomcat() {
    local tomcat_dir
    tomcat_dir=$(find "$BUNDLE_DIR" -maxdepth 1 -type d -name "tomcat-*" | head -n 1)
    [[ -n "$tomcat_dir" && -f "$tomcat_dir/conf/server.xml" ]] || return 0

    local server_xml="$tomcat_dir/conf/server.xml"
    lp_info "Updating Tomcat server.xml"

    sed -i "s|<Server port=\"[0-9]*\"|<Server port=\"$((8005 + OFFSET))\"|" "$server_xml"
    sed -i "s|\(<Connector [^>]*\)protocol=\"HTTP/1.1\"\([^>]*\)port=\"[0-9]*\"|\1protocol=\"HTTP/1.1\"\2port=\"$((8080 + OFFSET))\"|" "$server_xml"
    sed -i "s|\(<Connector [^>]*\)port=\"[0-9]*\"\([^>]*\)protocol=\"HTTP/1.1\"|\1port=\"$((8080 + OFFSET))\"\2protocol=\"HTTP/1.1\"|" "$server_xml"
    sed -i "s|\(<Connector [^>]*\)protocol=\"AJP/1.3\"\([^>]*\)port=\"[0-9]*\"|\1protocol=\"AJP/1.3\"\2port=\"$((8009 + OFFSET))\"|" "$server_xml"
    sed -i "s|\(<Connector [^>]*\)port=\"[0-9]*\"\([^>]*\)protocol=\"AJP/1.3\"|\1port=\"$((8009 + OFFSET))\"\2protocol=\"AJP/1.3\"|" "$server_xml"
    sed -i "s|redirectPort=\"[0-9]*\"|redirectPort=\"$((8443 + OFFSET))\"|g" "$server_xml"
}

configure_portal_ext() {
    local properties_file="$BUNDLE_DIR/portal-ext.properties"
    [[ -f "$properties_file" ]] || return 0

    lp_info "Updating portal-ext.properties"
    sed -i "/^module.framework.properties.osgi.console=/d" "$properties_file"
    sed -i "/^portal.instance.inet.socket.address=/d" "$properties_file"
    echo "module.framework.properties.osgi.console=localhost:$((11311 + OFFSET))" >> "$properties_file"
    echo "portal.instance.inet.socket.address=localhost:$((8080 + OFFSET))" >> "$properties_file"
}

configure_elasticsearch() {
    local es_config="$OSGI_CONFIGS_DIR/com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config"
    lp_info "Updating Elasticsearch config"
    echo "sidecarHttpPort=\"$((9201 + OFFSET))\"" > "$es_config"
    echo "transportTcpPort=\"$((9301 + OFFSET))\"" >> "$es_config"
}

configure_arquillian_dataguard() {
    lp_info "Updating Arquillian and DataGuard configs"
    echo "port=\"$((32763 + OFFSET))\"" > "$OSGI_CONFIGS_DIR/com.liferay.arquillian.extension.portal.configuration.ArquillianConnector.config"
    echo "port=\"$((42763 + OFFSET))\"" > "$OSGI_CONFIGS_DIR/com.liferay.portal.dataguard.configuration.DataGuardConnector.config"
}

configure_glowroot() {
    local glowroot_admin="$BUNDLE_DIR/glowroot/admin.json"
    [[ -f "$glowroot_admin" ]] || return 0

    if command -v jq &> /dev/null; then
        lp_info "Updating Glowroot admin.json using jq"
        local tmp_file
        tmp_file=$(mktemp)
        jq ".web.port = $((4000 + OFFSET))" "$glowroot_admin" > "$tmp_file" && mv "$tmp_file" "$glowroot_admin"
    else
        lp_info "Updating Glowroot admin.json using sed (jq not found)"
        sed -i "s|\"port\":[[:space:]]*[0-9]*|\"port\": $((4000 + OFFSET))|" "$glowroot_admin"
    fi
}

apply_ports() {
    OFFSET=$(get_offset)
    lp_info "Using port offset: $OFFSET (Branch: $BRANCH)"

    if [[ "$OFFSET" -eq 0 && "$BRANCH" != "master" ]]; then
        lp_error "Could not determine a valid port offset."
        return 1
    fi

    OSGI_CONFIGS_DIR="$BUNDLE_DIR/osgi/configs"
    mkdir -p "$OSGI_CONFIGS_DIR"

    configure_tomcat
    configure_portal_ext
    configure_elasticsearch
    configure_arquillian_dataguard
    configure_glowroot

    lp_success "Ports configured with offset $OFFSET."
}

main() {
    parse_arguments "$@"
    lp_branch_vars "$BRANCH"
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?
    
    OFFSET_FILE="$BUNDLE_DIR/.worktree-port-offset"
    apply_ports
}

main "$@"
