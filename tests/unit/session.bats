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
