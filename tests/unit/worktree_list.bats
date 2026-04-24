#!/usr/bin/env bats

load "../test_helper"

setup() {
    export _LP_SCRIPTS_DIR="$_LP_SCRIPTS_DIR"
    export HOME_ORIG="$HOME"
    export TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/lp"
    
    cat > "$XDG_CONFIG_HOME/lp/config" <<EOF
BASE_PROJECT_DIR="$HOME/dev/projects"
MAIN_REPO_NAME="liferay-portal"
MAIN_REPO_DIR="\$BASE_PROJECT_DIR/\$MAIN_REPO_NAME"
EE_REPO_DIR="\$BASE_PROJECT_DIR/liferay-portal-ee"
BUNDLES_DIR="\$HOME/dev/bundles"
LIFERAY_USER="testuser"
EOF

    mkdir -p "$HOME/dev/projects/liferay-portal"
    
    # Mock git
    mkdir -p "$HOME/bin"
    cat > "$HOME/bin/git" <<EOF
#!/bin/bash
if [[ "\$*" == *"worktree list"* ]]; then
    echo "/path/to/worktree1 abc1234 [branch1]"
else
    command git "\$@"
fi
EOF
    chmod +x "$HOME/bin/git"
    export PATH="$HOME/bin:$PATH"
}

teardown() {
    rm -rf "$TEST_HOME"
    export HOME="$HOME_ORIG"
}

@test "worktree list should show worktrees without verbose flag" {
    # Run the script directly
    run "$_LP_SCRIPTS_DIR/commands/worktree/list.sh"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Active Liferay Portal (Master) worktrees:"* ]]
    [[ "$output" == *"/path/to/worktree1 abc1234 [branch1]"* ]]
}
