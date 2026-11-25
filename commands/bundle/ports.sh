#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "ports" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

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

    BRANCH="${BRANCH:-$(lp_get_reference_branch)}"
}

port_for() {
    local base
    base=$(_lp_port_base "$1")
    [[ -n "$base" ]] || { lp_error "Unknown port kind: $1"; return 1; }
    echo $((base + OFFSET))
}

_LP_MAX_PORT_OFFSET=99

offset_ports() {
    local offset=$1
    local kind
    for kind in $_LP_PORT_KINDS; do
        echo $(( $(_lp_port_base "$kind") + offset ))
    done
}

ports_in_use() {
    local port
    for port in $(offset_ports "$1"); do
        nc -z localhost "$port" 2>/dev/null && return 0
    done
    return 1
}

claimed_offsets() {
    local other_bundle offset
    echo 0
    for other_bundle in "$BUNDLES_DIR"/*; do
        [[ -d "$other_bundle" && "$other_bundle" != "$BUNDLE_DIR" ]] || continue
        [[ -f "$other_bundle/$_LP_BUNDLE_OFFSET_FILE" ]] || continue
        offset=$(cat "$other_bundle/$_LP_BUNDLE_OFFSET_FILE")
        case "$offset" in ""|*[!0-9]*) continue ;; esac
        echo "$offset"
    done
}

claimed_ports() {
    local offset
    for offset in $(claimed_offsets); do
        offset_ports "$offset"
    done
}

offset_overlaps_claimed() {
    local claimed port
    claimed=" $(claimed_ports | tr '\n' ' ') "
    for port in $(offset_ports "$1"); do
        case "$claimed" in *" $port "*) return 0 ;; esac
    done
    return 1
}

find_free_offset() {
    local offset=1
    while [[ "$offset" -le "$_LP_MAX_PORT_OFFSET" ]]; do
        if ! ports_in_use "$offset" && ! offset_overlaps_claimed "$offset"; then
            echo "$offset"
            return 0
        fi
        offset=$((offset + 1))
    done
    lp_error "No free port offset between 1 and $_LP_MAX_PORT_OFFSET."
    return 1
}

get_offset() {
    if [[ "$BRANCH" == "master" ]]; then
        echo 0
        return 0
    fi

    if [[ -f "$OFFSET_FILE" ]]; then
        cat "$OFFSET_FILE"
        return $?
    fi

    local offset
    offset=$(find_free_offset) || return $?
    echo "$offset" > "$OFFSET_FILE" || return $?
    echo "$offset"
}

# sed -z reads the whole file as one record, so [^>]* spans the newlines inside one element.
connector_port_script() {
    local marker="$1" port="$2"
    local element_start='<Connector[[:space:]]'
    local new_port='port="'"$port"'"'
    local marker_before_port='s#\('"$element_start"'[^>]*'"$marker"'[^>]*[[:space:]]\)port="[0-9]*"#\1'"$new_port"'#g'
    local port_before_marker='s#\('"$element_start"'\([^>]*[[:space:]]\)\{0,1\}\)port="[0-9]*"\([^>]*'"$marker"'\)#\1'"$new_port"'\3#g'
    echo "$marker_before_port"
    echo "$port_before_marker"
}

tomcat_ports_script() {
    local shutdown_port="$1" http_port="$2" ajp_port="$3" https_port="$4"
    echo 's#\(<Server[[:space:]]\([^>]*[[:space:]]\)\{0,1\}\)port="[0-9]*"#\1port="'"$shutdown_port"'"#g'
    connector_port_script 'protocol="HTTP/1\.1"' "$http_port"
    connector_port_script 'protocol="AJP/1\.3"' "$ajp_port"
    connector_port_script '\(SSLEnabled="true"\|Http11NioProtocol\)' "$https_port"
    echo 's#redirectPort="[0-9]*"#redirectPort="'"$https_port"'"#g'
}

configure_tomcat() {
    local tomcat_dir
    tomcat_dir=$(find "$BUNDLE_DIR" -maxdepth 1 -type d -name "tomcat-*" | head -n 1)
    [[ -n "$tomcat_dir" && -f "$tomcat_dir/conf/server.xml" ]] || return 0

    local shutdown_port http_port ajp_port https_port script
    shutdown_port=$(port_for shutdown) || return $?
    http_port=$(port_for http) || return $?
    ajp_port=$(port_for ajp) || return $?
    https_port=$(port_for https) || return $?
    script=$(tomcat_ports_script "$shutdown_port" "$http_port" "$ajp_port" "$https_port") || return $?
    lp_info "Updating Tomcat server.xml"

    sed -z -i -e "$script" "$tomcat_dir/conf/server.xml"
}

configure_portal_ext() {
    local properties_file="$BUNDLE_DIR/portal-ext.properties"
    [[ -f "$properties_file" ]] || return 0

    local osgi_port http_port
    osgi_port=$(port_for osgi) || return $?
    http_port=$(port_for http) || return $?
    lp_info "Updating portal-ext.properties"
    lp_set_property "$properties_file" "module.framework.properties.osgi.console" "localhost:$osgi_port" || return $?
    lp_set_property "$properties_file" "portal.instance.inet.socket.address" "localhost:$http_port"
}

detect_es_version() {
    local portal_osgi_dir="$BUNDLE_DIR/osgi/portal"
    if [[ -f "$portal_osgi_dir/com.liferay.portal.search.elasticsearch8.impl.jar" ]]; then
        echo "elasticsearch8"
    elif [[ -f "$portal_osgi_dir/com.liferay.portal.search.elasticsearch7.impl.jar" ]]; then
        echo "elasticsearch7"
    fi
}

configure_elasticsearch() {
    local es_version
    es_version=$(detect_es_version)
    if [[ -z "$es_version" ]]; then
        lp_info "Skipping search config (no Elasticsearch engine jar found)"
        return 0
    fi

    local es_config="$OSGI_CONFIGS_DIR/com.liferay.portal.search.$es_version.configuration.ElasticsearchConfiguration.config"
    local http_port transport_port
    http_port=$(port_for es-http) || return $?
    transport_port=$(port_for es-transport) || return $?
    lp_info "Updating $es_version config"
    lp_set_property "$es_config" "sidecarHttpPort" "\"$http_port\"" || return $?
    lp_set_property "$es_config" "transportTcpPort" "\"$transport_port\"" || return $?
    lp_set_property "$es_config" "networkBindHost" "\"127.0.0.1\"" || return $?
    lp_set_property "$es_config" "networkPublishHost" "\"127.0.0.1\""
}

remove_stale_connector_configs() {
    local stale
    for stale in \
        "com.liferay.arquillian.extension.portal.configuration.ArquillianConnector.config" \
        "com.liferay.portal.dataguard.configuration.DataGuardConnector.config"; do
        rm -f "$OSGI_CONFIGS_DIR/$stale" || return $?
    done
}

configure_arquillian_dataguard() {
    local arquillian_port dataguard_port
    arquillian_port=$(port_for arquillian) || return $?
    dataguard_port=$(port_for dataguard) || return $?
    lp_info "Updating Arquillian and DataGuard configs"
    remove_stale_connector_configs || return $?
    echo "port=\"$arquillian_port\"" > "$OSGI_CONFIGS_DIR/com.liferay.arquillian.extension.junit.bridge.connector.ArquillianConnector.config" || return $?
    echo "port=\"$dataguard_port\"" > "$OSGI_CONFIGS_DIR/com.liferay.data.guard.connector.DataGuardConnector.config"
}

configure_jpda() {
    local tomcat_dir
    tomcat_dir=$(find "$BUNDLE_DIR" -maxdepth 1 -type d -name "tomcat-*" | head -n 1)
    [[ -n "$tomcat_dir" ]] || return 0

    local setenv="$tomcat_dir/bin/setenv.sh"
    local jpda_port
    jpda_port=$(port_for jpda) || return $?
    lp_info "Updating Tomcat setenv.sh JPDA_ADDRESS"

    if [[ ! -f "$setenv" ]]; then
        echo "#!/bin/bash" > "$setenv" || return $?
        chmod +x "$setenv" || return $?
    fi
    sed -i '/^export JPDA_ADDRESS=/d' "$setenv" || return $?
    lp_set_property "$setenv" "JPDA_ADDRESS" "\"localhost:$jpda_port\""
}

configure_glowroot() {
    local glowroot_admin="$BUNDLE_DIR/glowroot/admin.json"
    [[ -f "$glowroot_admin" ]] || return 0

    local glowroot_port
    glowroot_port=$(port_for glowroot) || return $?

    if command -v jq &> /dev/null; then
        lp_info "Updating Glowroot admin.json using jq"
        local tmp_file
        tmp_file=$(mktemp)
        jq ".web.port = $glowroot_port" "$glowroot_admin" > "$tmp_file" && mv "$tmp_file" "$glowroot_admin"
    else
        lp_info "Updating Glowroot admin.json using sed (jq not found)"
        sed -i "s|\"port\":[[:space:]]*[0-9]*|\"port\": $glowroot_port|" "$glowroot_admin"
    fi
}

write_test_properties() {
    local properties_file="$WORKTREE_DIR/test.${LIFERAY_USER}.properties"
    local portal_url="$1"
    local arquillian_port key
    arquillian_port=$(port_for arquillian) || return $?

    lp_info "Updating $properties_file"
    for key in default.portal.url instance.url test.url; do
        lp_set_property "$properties_file" "$key" "$portal_url" || return $?
    done
    lp_set_property "$properties_file" "systemProp.liferay.arquillian.port" "$arquillian_port"
}

write_gradle_properties() {
    local gradle_properties="$WORKTREE_DIR/.gradle/gradle.properties"
    [[ -f "$gradle_properties" ]] || return 0

    local arquillian_port
    arquillian_port=$(port_for arquillian) || return $?
    lp_info "Updating $gradle_properties"
    lp_set_property "$gradle_properties" "systemProp.liferay.arquillian.port" "$arquillian_port"
}

write_gradle_init_script() {
    local init_dir="$WORKTREE_DIR/.gradle/init.d"
    local init_script="$init_dir/worktree-ports.gradle"
    local http_port
    http_port=$(port_for http) || return $?

    lp_info "Writing $init_script"
    mkdir -p "$init_dir" || return $?
    printf '%s\n' \
        'allprojects {' \
        $'\tafterEvaluate { project ->' \
        $'\t\tdef extension = project.extensions.findByName("testIntegrationTomcat")' \
        '' \
        $'\t\tif (extension != null) {' \
        $'\t\t\textension.portNumber = '"$http_port" \
        $'\t\t}' \
        $'\t}' \
        '}' > "$init_script"
}

write_playwright_env() {
    local playwright_dir="$WORKTREE_DIR/modules/test/playwright"
    [[ -d "$playwright_dir" ]] || return 0

    lp_info "Updating $playwright_dir/.env.local"
    lp_set_property "$playwright_dir/.env.local" "PORTAL_URL" "$1"
}

configure_worktree_tests() {
    local portal_url
    portal_url="http://localhost:$(port_for http)" || return $?

    write_test_properties "$portal_url" || return $?
    write_gradle_properties || return $?
    write_gradle_init_script || return $?
    write_playwright_env "$portal_url"
}

apply_ports() {
    OFFSET=$(get_offset) || return $?
    lp_info "Using port offset: $OFFSET (Branch: $BRANCH)"

    if [[ "$OFFSET" -eq 0 && "$BRANCH" != "master" ]]; then
        lp_error "Could not determine a valid port offset."
        return 1
    fi

    OSGI_CONFIGS_DIR="$BUNDLE_DIR/osgi/configs"
    mkdir -p "$OSGI_CONFIGS_DIR" || return $?

    configure_tomcat || return $?
    configure_portal_ext || return $?
    configure_elasticsearch || return $?
    configure_arquillian_dataguard || return $?
    configure_glowroot || return $?
    configure_jpda || return $?
    [[ "$OFFSET" -eq 0 ]] || configure_worktree_tests || return $?

    lp_success "Ports configured with offset $OFFSET."
}

main() {
    parse_arguments "$@" || return $?
    lp_branch_vars "$BRANCH" || return $?
    lp_validate_worktree || return $?
    lp_load_bundle_dir || return $?

    OFFSET_FILE="$BUNDLE_DIR/.worktree-port-offset"
    apply_ports || return $?
}

main "$@"
