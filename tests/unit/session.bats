#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

@test "rebuild stops when there is no 'bundle' window in the session" {
    export TMUX=1
    lp_stub tmux '
case "$1" in
    display-message) echo "sess" ;;
    list-windows) echo "other" ;;
esac
'

    run bash -c "'$_LP_SCRIPTS_DIR/commands/session/rebuild.sh' < /dev/null"

    [ "$status" -ne 0 ]
    ! grep -q "send-keys" "$CALLS_LOG"
}

@test "restart stops without restarting when the bundle pane never goes idle" {
    export TMUX=1
    lp_stub sleep 0
    lp_stub tmux '
case "$1" in
    display-message)
        if [[ "$2" == "-t" ]]; then echo "java"; else echo "sess"; fi
        ;;
    list-windows) echo "bundle" ;;
esac
'

    run bash -c "echo y | '$_LP_SCRIPTS_DIR/commands/session/restart.sh'"

    [ "$status" -ne 0 ]
    ! grep -q "send-keys.*lp bundle start" "$CALLS_LOG"
}

@test "restart restarts once the bundle pane goes idle" {
    export TMUX=1
    lp_stub sleep 0

    local probe_count_file="$TEST_HOME/probe_count"
    echo 0 > "$probe_count_file"

    lp_stub tmux "
case \"\$1\" in
    display-message)
        if [[ \"\$2\" == \"-t\" ]]; then
            count=\$(cat '$probe_count_file')
            count=\$((count + 1))
            echo \$count > '$probe_count_file'
            if [[ \$count -ge 2 ]]; then
                echo bash
            else
                echo java
            fi
        else
            echo sess
        fi
        ;;
    list-windows) echo bundle ;;
esac
"

    run bash -c "echo y | '$_LP_SCRIPTS_DIR/commands/session/restart.sh'"

    [ "$status" -eq 0 ]
    [ "$(grep -c "send-keys.*lp bundle start" "$CALLS_LOG")" -eq 1 ]
}

@test "update stops before delegating when no tmux session is targeted" {
    unset TMUX
    lp_stub tmux 0

    run "$_LP_SCRIPTS_DIR/commands/session/update.sh" -d "new description"

    [ "$status" -ne 0 ]
    [[ "$output" != *"[1/"* ]]
}

@test "describe stops without success output when the status-line update fails" {
    lp_stub tmux '
case "$1" in
    has-session) exit 0 ;;
    show-option) exit 0 ;;
    set-option)
        if [[ "$4" == "status-left" ]]; then exit 1; fi
        exit 0
        ;;
    *) exit 0 ;;
esac
'

    run "$_LP_SCRIPTS_DIR/commands/session/describe.sh" mybranch "a new description"

    [ "$status" -ne 0 ]
    [[ "$output" != *"Description updated."* ]]
}

@test "add refuses to add a window outside tmux" {
    unset TMUX
    lp_stub tmux 0

    run "$_LP_SCRIPTS_DIR/commands/session/add.sh" mywindow

    [ "$status" -ne 0 ]
    ! grep -q "new-window" "$CALLS_LOG"
}

stub_tmux_version() {
    lp_stub tmux "
case \"\$1\" in
    -V) echo '$1' ;;
    has-session) exit 1 ;;
esac
"
}

@test "start passes the LP_* session variables to new-session" {
    mkdir -p "$HOME/dev/projects/liferay-portal-my rel-7.4"
    stub_tmux_version "tmux 3.7c"
    lp_stub mktemp 'echo "$HOME/tmpfile"'

    run bash -c "'$_LP_SCRIPTS_DIR/commands/session/start.sh' 'my rel-7.4' < /dev/null"

    local call
    call=$(grep "^tmux new-session" "$CALLS_LOG")
    [[ "$call" == *"-e LP_SESSION_NAME=my rel-7_4 "* ]]
    [[ "$call" == *"-e LP_BRANCH=my rel-7.4 "* ]]
    [[ "$call" == *"-e LP_WORKTREE_DIR=$HOME/dev/projects/liferay-portal-my rel-7.4 "* ]]
    [[ "$call" == *"-e LP_BUNDLE_DIR=$HOME/dev/bundles/my rel-7.4 "* ]]
}

@test "start refuses tmux older than 3.2 without creating a session" {
    mkdir -p "$HOME/dev/projects/liferay-portal-feat"
    stub_tmux_version "tmux 3.1"

    run bash -c "'$_LP_SCRIPTS_DIR/commands/session/start.sh' feat < /dev/null"

    [ "$status" -ne 0 ]
    [[ "$output" == *"3.2"* ]]
    ! grep -q "new-session" "$CALLS_LOG"
}

@test "start accepts non-numeric tmux versions" {
    mkdir -p "$HOME/dev/projects/liferay-portal-feat"
    stub_tmux_version "tmux next-3.4"
    lp_stub mktemp 'echo "$HOME/tmpfile"'

    run bash -c "'$_LP_SCRIPTS_DIR/commands/session/start.sh' feat < /dev/null"

    grep -q "^tmux new-session" "$CALLS_LOG"
}

stub_bundle_probe() {
    local branch="$1"
    local nc_exit="$2"
    lp_stub tmux "
case \"\$1\" in
    show-option) echo '$branch' ;;
    list-panes) echo /dev/pts/9 ;;
esac
"
    lp_stub ps 'echo "/usr/bin/java -jar catalina.jar"'
    lp_stub nc "$nc_exit"
}

write_port_offset() {
    local branch="$1"
    local offset="$2"
    mkdir -p "$HOME/dev/bundles/$branch"
    echo "$offset" > "$HOME/dev/bundles/$branch/.worktree-port-offset"
}

@test "icon shows the rocket with the offset http port when the bundle is up" {
    write_port_offset feat 3
    stub_bundle_probe feat 0

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" feat

    [ "$status" -eq 0 ]
    [ "$output" = "🚀 :8083  " ]
    grep -q "^nc -z localhost 8083" "$CALLS_LOG"
}

@test "icon shows the starting icon when the server runs but the port is closed" {
    write_port_offset feat 3
    stub_bundle_probe feat 1

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" feat

    [ "$status" -eq 0 ]
    [ "$output" = "🔄  " ]
}

@test "icon shows the build icon while build.sh runs in the bundle pane" {
    stub_bundle_probe feat 1
    lp_stub ps 'echo "bash /home/u/dev/scripts/commands/bundle/build.sh -y"'

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" feat

    [ "$status" -eq 0 ]
    [ "$output" = "🔨  " ]
}

@test "icon shows the build icon while ant runs, even if the port is open" {
    stub_bundle_probe feat 0
    lp_stub ps 'printf "%s\n" "/bin/sh /usr/share/ant/bin/ant all" "java -cp ant-launcher.jar org.apache.tools.ant.launch.Launcher all"'

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" feat

    [ "$status" -eq 0 ]
    [ "$output" = "🔨  " ]
}

@test "icon shows nothing when the port is open but no server runs in the pane" {
    stub_bundle_probe feat 0
    lp_stub ps 'echo "-zsh"'

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" feat

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "icon uses the default http port for master" {
    stub_bundle_probe master 0

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" master

    [ "$status" -eq 0 ]
    [ "$output" = "🚀 :8080  " ]
}

@test "icon takes the port offset from the session's branch, not its tmux-safe name" {
    write_port_offset release-7.4 5
    stub_bundle_probe release-7.4 0

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" release-7_4

    [ "$status" -eq 0 ]
    [ "$output" = "🚀 :8085  " ]
}

@test "icon falls back to the session name when the branch option is empty" {
    write_port_offset feat 2
    stub_bundle_probe "" 0

    run "$_LP_SCRIPTS_DIR/commands/session/icon.sh" feat

    [ "$status" -eq 0 ]
    [ "$output" = "🚀 :8082  " ]
}
