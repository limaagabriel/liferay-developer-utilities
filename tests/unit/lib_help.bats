#!/usr/bin/env bats

setup() {
    load '../test_helper'
    source "$_LP_SCRIPTS_DIR/lib/help.sh"
}

@test "lp_print_command_help prints description, usage, options, and examples" {
    # Test for worktree/add
    run lp_print_command_help "worktree" "add"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Add a new git worktree for a branch"* ]]
    [[ "$output" == *"Usage: lp worktree add [options] <branch>"* ]]
    [[ "$output" == *"Options:"* ]]
    [[ "$output" == *"  -b, --base <branch>"* ]]
    [[ "$output" == *"Examples:"* ]]
    [[ "$output" == *"  lp worktree add main"* ]]
}

@test "lp_top_level_help prints namespaces" {
    run lp_top_level_help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: lp <namespace> <command> [args...]"* ]]
    [[ "$output" == *"worktree  —  Manage git worktrees for portal branches"* ]]
    [[ "$output" == *"session  —  Manage tmux-based development sessions"* ]]
}

@test "lp_namespace_help prints commands for a namespace" {
    run lp_namespace_help "worktree"
    [ "$status" -eq 0 ]
    [[ "$output" == *"lp worktree  —  Manage git worktrees for portal branches"* ]]
    [[ "$output" == *"add         Add a new git worktree for a branch"* ]]
    [[ "$output" == *"Usage:   lp worktree add [options] <branch>"* ]]
}
