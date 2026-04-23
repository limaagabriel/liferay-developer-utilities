#!/usr/bin/env bats

setup() {
    load '../test_helper'
    
    # Create a mock scripts directory structure
    MOCK_SCRIPTS_DIR=$(mktemp -d)
    mkdir -p "$MOCK_SCRIPTS_DIR/lib"
    
    # Backup original scripts dir and update _LP_SCRIPTS_DIR
    export _LP_SCRIPTS_DIR_BAK="$_LP_SCRIPTS_DIR"
    export _LP_SCRIPTS_DIR="$MOCK_SCRIPTS_DIR"
    
    # Create mock files
    cat > "$MOCK_SCRIPTS_DIR/config.sh" <<EOF
BASE_PROJECT_DIR=/tmp/lp
MAIN_REPO_DIR=/tmp/lp/liferay-portal
EOF
    
    # Mock help library
    cat > "$MOCK_SCRIPTS_DIR/lib/help.sh" <<EOF
lp_print_command_help() { echo "mock help for \$1 \$2"; }
EOF

    # Mock worktree library
    cat > "$MOCK_SCRIPTS_DIR/lib/worktree.sh" <<EOF
# mock
EOF
    
    # Copy the real init.sh to test it
    cp "$_LP_SCRIPTS_DIR_BAK/lib/init.sh" "$MOCK_SCRIPTS_DIR/lib/"
    
    # We also need output.sh because init.sh might source it
    cp "$_LP_SCRIPTS_DIR_BAK/lib/output.sh" "$MOCK_SCRIPTS_DIR/lib/"
}

teardown() {
    rm -rf "$MOCK_SCRIPTS_DIR"
    export _LP_SCRIPTS_DIR="$_LP_SCRIPTS_DIR_BAK"
}

@test "lp_init_command sources config and set VERBOSE=0 by default" {
    source "$_LP_SCRIPTS_DIR/lib/init.sh"
    
    test_init() {
        lp_init_command "worktree" "add"
        echo "VERBOSE=$VERBOSE"
    }
    run test_init
    [ "$status" -eq 0 ]
    [[ "$output" == *"VERBOSE=0"* ]]
}

@test "lp_init_command handles --help by printing it and exiting" {
    source "$_LP_SCRIPTS_DIR/lib/init.sh"
    
    # It should call lp_print_command_help from our mock lib/help.sh
    run lp_init_command "worktree" "add" "--help"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mock help for worktree add"* ]]
}

@test "lp_init_command handles --verbose" {
    source "$_LP_SCRIPTS_DIR/lib/init.sh"
    
    test_verbose() {
        lp_init_command "worktree" "add" "$@"
        echo "VERBOSE=$VERBOSE"
    }
    
    run test_verbose
    [[ "$output" == *"VERBOSE=0"* ]]

    run test_verbose "--verbose"
    [[ "$output" == *"VERBOSE=1"* ]]
    
    run test_verbose "-v"
    [[ "$output" == *"VERBOSE=1"* ]]
}
