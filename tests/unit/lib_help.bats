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

@test "lp_top_level_help prints namespaces with aliases" {
    run lp_top_level_help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: lp <namespace> <command> [args...]"* ]]
    [[ "$output" == *"worktree (w)  —  Manage git worktrees for portal branches"* ]]
    [[ "$output" == *"session (s)  —  Manage tmux-based development sessions"* ]]
}

@test "_lp_ns_alias resolves shorthand to real namespace" {
    [ "$(_lp_ns_alias w)" = "worktree" ]
    [ "$(_lp_ns_alias b)" = "bundle" ]
    [ "$(_lp_ns_alias p)" = "portal" ]
    [ "$(_lp_ns_alias pw)" = "playwright" ]
    [ "$(_lp_ns_alias ms)" = "mysql" ]
    [ "$(_lp_ns_alias s)" = "session" ]
    [ "$(_lp_ns_alias c)" = "config" ]
    [ "$(_lp_ns_alias g)" = "git" ]
    [ "$(_lp_ns_alias se)" = "self" ]
    [ "$(_lp_ns_alias m)" = "modules" ]
}

@test "_lp_ns_alias passes through real namespace names unchanged" {
    [ "$(_lp_ns_alias worktree)" = "worktree" ]
    [ "$(_lp_ns_alias unknown)" = "unknown" ]
}

@test "_lp_ns_alias_for returns shorthand for real namespace" {
    [ "$(_lp_ns_alias_for worktree)" = "w" ]
    [ "$(_lp_ns_alias_for mysql)" = "ms" ]
    [ "$(_lp_ns_alias_for modules)" = "m" ]
    [ -z "$(_lp_ns_alias_for unknown)" ]
}

@test "lp_namespace_help prints commands for a namespace" {
    run lp_namespace_help "worktree"
    [ "$status" -eq 0 ]
    [[ "$output" == *"lp worktree  —  Manage git worktrees for portal branches"* ]]
    [[ "$output" == *"add         Add a new git worktree for a branch"* ]]
    [[ "$output" == *"Usage:   lp worktree add [options] <branch>"* ]]
}
