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

@test "lp_print_command_help bundle refresh prints description, usage, options, and examples" {
    run lp_print_command_help "bundle" "refresh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Refresh portal jars in the active bundle"* ]]
    [[ "$output" == *"Usage: lp bundle refresh"* ]]
    [[ "$output" == *"-q, --quiet"* ]]
    [[ "$output" == *"lp bundle refresh"* ]]
}

@test "_lp_ns_cmds bundle includes refresh" {
    cmds=$(_lp_ns_cmds bundle)
    [[ " $cmds " == *" refresh "* ]]
}

@test "lp_print_command_help bundle build documents --no-refresh" {
    run lp_print_command_help "bundle" "build"
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n, --no-refresh"* ]]
    [[ "$output" == *"requires --from-base"* ]]
}

@test "_LP_NAMESPACES includes database" {
    [[ " $_LP_NAMESPACES " == *" database "* ]]
}

@test "_lp_ns_alias resolves db to database" {
    [ "$(_lp_ns_alias db)" = "database" ]
}

@test "_lp_ns_alias_for returns db for database" {
    [ "$(_lp_ns_alias_for database)" = "db" ]
}

@test "_lp_ns_desc returns description for database" {
    desc=$(_lp_ns_desc database)
    [ -n "$desc" ]
}

@test "_lp_ns_cmds database lists all 7 commands" {
    cmds=$(_lp_ns_cmds database)
    [[ " $cmds " == *" status "* ]]
    [[ " $cmds " == *" reset "* ]]
    [[ " $cmds " == *" drop "* ]]
    [[ " $cmds " == *" switch "* ]]
    [[ " $cmds " == *" start "* ]]
    [[ " $cmds " == *" stop "* ]]
    [[ " $cmds " == *" remove "* ]]
}

@test "lp_print_command_help database reset prints description, usage, options, and examples" {
    run lp_print_command_help "database" "reset"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Reset the database for a branch"* ]]
    [[ "$output" == *"Usage: lp database reset"* ]]
    [[ "$output" == *"Examples:"* ]]
}

@test "lp_print_command_help database status notes mysql-only support" {
    run lp_print_command_help "database" "status"
    [ "$status" -eq 0 ]
    [[ "$output" == *"(mysql only)"* ]]
}

@test "lp_print_command_help database switch documents hypersonic|mysql positional" {
    run lp_print_command_help "database" "switch"
    [ "$status" -eq 0 ]
    [[ "$output" == *"hypersonic"* ]]
    [[ "$output" == *"mysql"* ]]
}
