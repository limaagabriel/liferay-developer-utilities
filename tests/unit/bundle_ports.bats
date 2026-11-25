#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

_lp_write_server_xml() {
    local shutdown="$1" http="$2" https="$3" ajp="$4"
    cat <<XML
<Server port="$shutdown" shutdown="SHUTDOWN">
  <Service name="Catalina">
    <Connector maxThreads="75" port="$http" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="$https"
               />
    <Connector executor="tomcatThreadPool" protocol="HTTP/1.1"
               connectionTimeout="20000"
               port="$http"
               redirectPort="$https"
               />
    <Connector port="$https" protocol="org.apache.coyote.http11.Http11NioProtocol"
               maxThreads="150" SSLEnabled="true"
               />
    <Connector protocol="HTTP/1.1"
               SSLEnabled="true"
               port="$https"
               />
    <Connector protocol="HTTP/1.1" />
    <Listener port="7777" className="HTTP/1.1"/>
    <Connector protocol="AJP/1.3"
               address="::1"
               port="$ajp"
               redirectPort="$https"
               />
    <Connector port="$ajp" protocol="AJP/1.3"
               redirectPort="$https"
               />
    <Connector protocol="AJP/1.3" />
    <Listener port="7777" className="AJP/1.3"/>
  </Service>
</Server>
XML
}

_lp_make_port_fixture() {
    local branch="${1:-feature}"
    local offset="${2:-3}"
    local bundle_dir="$HOME/dev/bundles/$branch"

    _lp_write_worktree_properties "$HOME/dev/projects/liferay-portal-$branch" "$bundle_dir"
    mkdir -p "$bundle_dir/tomcat-x/bin" "$bundle_dir/tomcat-x/conf"
    echo "module.framework.properties.osgi.console=localhost:11312" > "$bundle_dir/portal-ext.properties"
    printf 'export JPDA_ADDRESS=localhost:8000\nJPDA_ADDRESS="8000"\n' > "$bundle_dir/tomcat-x/bin/setenv.sh"
    _lp_write_server_xml 8005 8080 8443 8009 > "$bundle_dir/tomcat-x/conf/server.xml"
    echo "$offset" > "$bundle_dir/.worktree-port-offset"
    lp_stub nc 1
}

_lp_set_property() {
    run bash -c 'source "$_LP_SCRIPTS_DIR/lib/output.sh"; source "$_LP_SCRIPTS_DIR/lib/bundle.sh"; lp_set_property "$@"' _ "$@"
}

@test "lp_set_property creates a missing file" {
    _lp_set_property "$TEST_HOME/new.properties" a.b 1

    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_HOME/new.properties")" = "a.b=1" ]
}

@test "lp_set_property starts a new line when the file has no trailing newline" {
    printf 'first=1' > "$TEST_HOME/f.properties"

    _lp_set_property "$TEST_HOME/f.properties" a.b 2

    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_HOME/f.properties")" = $'first=1\na.b=2' ]
}

@test "lp_set_property treats dots in the key literally" {
    printf 'axb=1\na.b=old\n' > "$TEST_HOME/f.properties"

    _lp_set_property "$TEST_HOME/f.properties" a.b new

    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_HOME/f.properties")" = $'axb=1\na.b=new' ]
}

@test "lp_set_property is idempotent" {
    printf 'x=1\n' > "$TEST_HOME/f.properties"

    _lp_set_property "$TEST_HOME/f.properties" a.b 1
    _lp_set_property "$TEST_HOME/f.properties" a.b 1

    [ "$(grep -c '^a\.b=' "$TEST_HOME/f.properties")" -eq 1 ]
    [ "$(wc -l < "$TEST_HOME/f.properties")" -eq 2 ]
}

@test "lp_set_property fails when the file is not writable" {
    if [[ "$(id -u)" -eq 0 ]]; then
        skip "permissions are not enforced when running as root"
    fi
    printf 'x=1\n' > "$TEST_HOME/f.properties"
    chmod a-w "$TEST_HOME/f.properties"

    _lp_set_property "$TEST_HOME/f.properties" a.b 1

    [ "$status" -ne 0 ]
    [ "$(cat "$TEST_HOME/f.properties")" = "x=1" ]
}

@test "ports.sh is idempotent and writes offset ports once" {
    _lp_make_port_fixture feature 3
    local bundle_dir="$HOME/dev/bundles/feature"

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature
    [ "$status" -eq 0 ]
    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature
    [ "$status" -eq 0 ]

    local ext="$bundle_dir/portal-ext.properties"
    local setenv="$bundle_dir/tomcat-x/bin/setenv.sh"
    [ "$(grep -c '^module.framework.properties.osgi.console=localhost:11314$' "$ext")" -eq 1 ]
    [ "$(grep -c '^portal.instance.inet.socket.address=localhost:8083$' "$ext")" -eq 1 ]
    [ "$(grep -c '^JPDA_ADDRESS="localhost:8003"$' "$setenv")" -eq 1 ]
    [ "$(grep -c 'JPDA_ADDRESS' "$setenv")" -eq 1 ]
    [ "$(grep -c 'export JPDA_ADDRESS' "$setenv")" -eq 0 ]
    grep -q '<Server port="8008"' "$bundle_dir/tomcat-x/conf/server.xml"
}

@test "ports.sh moves every tomcat port in multi-line connectors and is idempotent" {
    _lp_make_port_fixture feature 3
    local server_xml="$HOME/dev/bundles/feature/tomcat-x/conf/server.xml"
    local expected="$TEST_HOME/expected-server.xml"
    _lp_write_server_xml 8008 8083 8446 8012 > "$expected"

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature
    [ "$status" -eq 0 ]
    diff "$expected" "$server_xml"

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature
    [ "$status" -eq 0 ]
    diff "$expected" "$server_xml"
}

@test "ports.sh stops without reporting success when portal-ext.properties can't be written" {
    if [[ "$(id -u)" -eq 0 ]]; then
        skip "permissions are not enforced when running as root"
    fi
    _lp_make_port_fixture feature 3
    chmod a-w "$HOME/dev/bundles/feature/portal-ext.properties"

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -ne 0 ]
    [[ "$output" != *"Ports configured"* ]]
}

@test "ports.sh writes Arquillian and DataGuard configs under the real connector PIDs" {
    _lp_make_port_fixture feature 3
    local configs="$HOME/dev/bundles/feature/osgi/configs"

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ "$(cat "$configs/com.liferay.arquillian.extension.junit.bridge.connector.ArquillianConnector.config")" = 'port="32766"' ]
    [ "$(cat "$configs/com.liferay.data.guard.connector.DataGuardConnector.config")" = 'port="42766"' ]
}

@test "ports.sh removes the old wrong-name Arquillian and DataGuard configs" {
    _lp_make_port_fixture feature 3
    local configs="$HOME/dev/bundles/feature/osgi/configs"
    mkdir -p "$configs"
    echo 'port="1"' > "$configs/com.liferay.arquillian.extension.portal.configuration.ArquillianConnector.config"
    echo 'port="2"' > "$configs/com.liferay.portal.dataguard.configuration.DataGuardConnector.config"

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ ! -e "$configs/com.liferay.arquillian.extension.portal.configuration.ArquillianConnector.config" ]
    [ ! -e "$configs/com.liferay.portal.dataguard.configuration.DataGuardConnector.config" ]
}

_lp_touch_osgi_jar() {
    local jar_dir="$HOME/dev/bundles/feature/osgi/portal"
    mkdir -p "$jar_dir"
    touch "$jar_dir/$1"
}

_lp_es_config() {
    echo "$HOME/dev/bundles/feature/osgi/configs/com.liferay.portal.search.$1.configuration.ElasticsearchConfiguration.config"
}

@test "ports.sh configures the ES8 sidecar on offset ports bound to loopback" {
    _lp_make_port_fixture feature 3
    _lp_touch_osgi_jar com.liferay.portal.search.elasticsearch8.impl.jar
    mkdir -p "$(dirname "$(_lp_es_config elasticsearch8)")"
    echo 'productionModeEnabled="false"' > "$(_lp_es_config elasticsearch8)"

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    local config
    config=$(_lp_es_config elasticsearch8)
    [ "$status" -eq 0 ]
    [ ! -e "$(_lp_es_config elasticsearch7)" ]
    [ "$(grep -c '^sidecarHttpPort="9204"$' "$config")" -eq 1 ]
    [ "$(grep -c '^transportTcpPort="9304"$' "$config")" -eq 1 ]
    [ "$(grep -c '^networkBindHost="127.0.0.1"$' "$config")" -eq 1 ]
    [ "$(grep -c '^networkPublishHost="127.0.0.1"$' "$config")" -eq 1 ]
    [ "$(grep -c '^productionModeEnabled="false"$' "$config")" -eq 1 ]
}

@test "ports.sh configures the ES7 sidecar when only the ES7 engine jar exists" {
    _lp_make_port_fixture feature 3
    _lp_touch_osgi_jar com.liferay.portal.search.elasticsearch7.impl.jar

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ ! -e "$(_lp_es_config elasticsearch8)" ]
    [ "$(grep -c '^sidecarHttpPort="9204"$' "$(_lp_es_config elasticsearch7)")" -eq 1 ]
}

@test "ports.sh ignores the commerce elasticsearch7 jar when detecting an ES8 bundle" {
    _lp_make_port_fixture feature 3
    _lp_touch_osgi_jar com.liferay.portal.search.elasticsearch8.impl.jar
    _lp_touch_osgi_jar com.liferay.commerce.elasticsearch7.jar

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ -f "$(_lp_es_config elasticsearch8)" ]
    [ ! -e "$(_lp_es_config elasticsearch7)" ]
}

@test "ports.sh skips search config without an engine jar" {
    _lp_make_port_fixture feature 3

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ ! -e "$(_lp_es_config elasticsearch7)" ]
    [ ! -e "$(_lp_es_config elasticsearch8)" ]
}

@test "ports.sh does not duplicate search config keys when run twice" {
    _lp_make_port_fixture feature 3
    _lp_touch_osgi_jar com.liferay.portal.search.elasticsearch8.impl.jar

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature
    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ "$(wc -l < "$(_lp_es_config elasticsearch8)")" -eq 4 ]
}

_lp_ports_at() {
    local base
    for base in 8080 8443 8005 8009 11311 9201 9301 32763 42763 4000 8000; do
        echo $((base + $1))
    done
}

_lp_claim_offsets() {
    local offset
    for offset in "$@"; do
        mkdir -p "$HOME/dev/bundles/other$offset"
        echo "$offset" > "$HOME/dev/bundles/other$offset/.worktree-port-offset"
    done
}

_lp_fresh_port_fixture() {
    _lp_make_port_fixture feature 3
    rm "$HOME/dev/bundles/feature/.worktree-port-offset"
}

@test "ports.sh skips an offset whose ajp port is busy" {
    _lp_fresh_port_fixture
    lp_stub nc '[[ "${@: -1}" == 8010 ]] && exit 0; exit 1'

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ "$(cat "$HOME/dev/bundles/feature/.worktree-port-offset")" = "2" ]
}

@test "ports.sh picks an offset sharing no port with master or other claimed offsets" {
    _lp_fresh_port_fixture
    _lp_claim_offsets 1 2 3 4

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    local chosen taken
    chosen=$(cat "$HOME/dev/bundles/feature/.worktree-port-offset")
    [ "$chosen" -ne 5 ]
    taken=" $(for offset in 0 1 2 3 4; do _lp_ports_at "$offset"; done | tr '\n' ' ') "
    for port in $(_lp_ports_at "$chosen"); do
        [[ "$taken" != *" $port "* ]]
    done
}

@test "ports.sh reuses an existing offset file unchanged" {
    _lp_make_port_fixture feature 7
    _lp_claim_offsets 1 2 3

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -eq 0 ]
    [ "$(cat "$HOME/dev/bundles/feature/.worktree-port-offset")" = "7" ]
}

@test "ports.sh fails without writing an offset file when no offset is free" {
    _lp_fresh_port_fixture
    lp_stub nc 0

    run "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" feature

    [ "$status" -ne 0 ]
    [[ "$output" == *"No free port offset"* ]]
    [[ "$output" != *"Ports configured"* ]]
    [ ! -e "$HOME/dev/bundles/feature/.worktree-port-offset" ]
}
