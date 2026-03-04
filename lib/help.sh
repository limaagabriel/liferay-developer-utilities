#!/bin/bash
# lib/help.sh — Command registry and help display functions for lp.
#
# MAINTENANCE: When adding a new command, update the following functions:
#   _lp_ns_cmds     — add the command name to its namespace's list
#   _lp_cmd_desc    — add a one-line description
#   _lp_cmd_usage   — add the usage synopsis
#   _lp_cmd_opts    — add the options block
#   _lp_cmd_examples — add at least one example
#
# Uses case statements (no declare -A) for bash 3 / zsh compatibility.

# ---------------------------------------------------------------------------
# Registry — namespace list, command list, and per-command metadata
# ---------------------------------------------------------------------------

# Space-separated list of all namespaces (defines display order)
_LP_NAMESPACES="worktree bundle mysql"

# _lp_ns_desc <ns> — one-line description for a namespace
_lp_ns_desc() {
    case "$1" in
        worktree) echo "Manage git worktrees for portal branches" ;;
        bundle)   echo "Manage Liferay bundle directories" ;;
        mysql)    echo "Manage the MySQL Docker container" ;;
        *)        echo "" ;;
    esac
}

# _lp_ns_cmds <ns> — space-separated command list for a namespace (defines display order)
_lp_ns_cmds() {
    case "$1" in
        worktree) echo "add cd code list rebuild remove start" ;;
        bundle)   echo "cd remove" ;;
        mysql)    echo "reset start" ;;
        *)        echo "" ;;
    esac
}

# _lp_cmd_desc <ns> <cmd> — one-line description
_lp_cmd_desc() {
    case "$1/$2" in
        worktree/add)     echo "Add a new git worktree for a branch" ;;
        worktree/cd)      echo "Change the current directory to a worktree" ;;
        worktree/code)    echo "Open a worktree in VS Code" ;;
        worktree/list)    echo "List all active worktrees and their bundles" ;;
        worktree/rebuild) echo "Delete the bundle and rebuild it from the worktree" ;;
        worktree/remove)  echo "Remove a worktree and its bundle directory" ;;
        worktree/start)   echo "Start the Liferay server for a worktree" ;;
        bundle/cd)        echo "Change the current directory to a bundle" ;;
        bundle/remove)    echo "Remove a bundle directory" ;;
        mysql/reset)      echo "Reset the lportal database (drop and recreate)" ;;
        mysql/start)      echo "Start MySQL via Docker Compose and reset the database" ;;
        *)                echo "" ;;
    esac
}

# _lp_cmd_usage <ns> <cmd> — usage synopsis
_lp_cmd_usage() {
    case "$1/$2" in
        worktree/add)     echo "lp worktree add [-r <remote>] [-v] <branch>" ;;
        worktree/cd)      echo "lp worktree cd <branch>" ;;
        worktree/code)    echo "lp worktree code <branch>" ;;
        worktree/list)    echo "lp worktree list" ;;
        worktree/rebuild) echo "lp worktree rebuild [-v] <branch>" ;;
        worktree/remove)  echo "lp worktree remove [-v] <branch>" ;;
        worktree/start)   echo "lp worktree start [-b] [-v] [branch]" ;;
        bundle/cd)        echo "lp bundle cd <branch>" ;;
        bundle/remove)    echo "lp bundle remove [-v] <branch>" ;;
        mysql/reset)      echo "lp mysql reset [-v]" ;;
        mysql/start)      echo "lp mysql start [-v]" ;;
        *)                echo "" ;;
    esac
}

# _lp_cmd_opts <ns> <cmd> — options block (multi-line)
_lp_cmd_opts() {
    case "$1/$2" in
        worktree/add)
            echo "  -r, --remote <remote>   Track from a remote branch"
            echo "  -v, --verbose           Show full git output"
            echo "  -h, --help              Show this help"
            ;;
        worktree/cd)
            echo "  -h, --help   Show this help"
            ;;
        worktree/code)
            echo "  -h, --help   Show this help"
            ;;
        worktree/list)
            echo "  -h, --help   Show this help"
            ;;
        worktree/rebuild)
            echo "  -v, --verbose   Show full ant/git output"
            echo "  -h, --help      Show this help"
            ;;
        worktree/remove)
            echo "  -v, --verbose   Show full git output"
            echo "  -h, --help      Show this help"
            ;;
        worktree/start)
            echo "  -b              Run the build step before starting"
            echo "  -v, --verbose   Show full ant output (catalina log always shown)"
            echo "  -h, --help      Show this help"
            ;;
        bundle/cd)
            echo "  -h, --help   Show this help"
            ;;
        bundle/remove)
            echo "  -v, --verbose   Show full output"
            echo "  -h, --help      Show this help"
            ;;
        mysql/reset)
            echo "  -v, --verbose   Show full docker output"
            echo "  -h, --help      Show this help"
            ;;
        mysql/start)
            echo "  -v, --verbose   Show full docker output"
            echo "  -h, --help      Show this help"
            ;;
        *)
            echo "  (none)"
            ;;
    esac
}

# _lp_cmd_examples <ns> <cmd> — examples block (multi-line)
_lp_cmd_examples() {
    case "$1/$2" in
        worktree/add)
            echo "  lp worktree add main"
            echo "  lp worktree add -r origin feature-xyz"
            echo "  lp worktree add --verbose main"
            ;;
        worktree/cd)
            echo "  lp worktree cd main"
            ;;
        worktree/code)
            echo "  lp worktree code main"
            ;;
        worktree/list)
            echo "  lp worktree list"
            ;;
        worktree/rebuild)
            echo "  lp worktree rebuild main"
            echo "  lp worktree rebuild --verbose main"
            ;;
        worktree/remove)
            echo "  lp worktree remove main"
            ;;
        worktree/start)
            echo "  lp worktree start main"
            echo "  lp worktree start -b main"
            echo "  lp worktree start           # uses current directory"
            ;;
        bundle/cd)
            echo "  lp bundle cd main"
            ;;
        bundle/remove)
            echo "  lp bundle remove main"
            ;;
        mysql/reset)
            echo "  lp mysql reset"
            ;;
        mysql/start)
            echo "  lp mysql start"
            ;;
        *)
            echo "  (none)"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Help display — lp_top_level_help, lp_namespace_help
# ---------------------------------------------------------------------------

# lp_top_level_help — print all namespaces and their commands with descriptions
lp_top_level_help() {
    echo "Usage: lp <namespace> <command> [args...]"
    echo ""
    for ns in $_LP_NAMESPACES; do
        local ns_desc
        ns_desc=$(_lp_ns_desc "$ns")
        echo "$ns  —  $ns_desc"
        local cmds
        cmds=$(_lp_ns_cmds "$ns")
        for cmd in $cmds; do
            local desc
            desc=$(_lp_cmd_desc "$ns" "$cmd")
            printf "  %-10s  %s\n" "$cmd" "$desc"
        done
        echo ""
    done
    echo "Run 'lp <namespace> help' for details on a namespace."
    echo "Run 'lp <namespace> <command> --help' for details on a command."
}

# lp_namespace_help <ns> — print all commands in a namespace with synopsis and example
lp_namespace_help() {
    local ns="$1"
    local ns_desc
    ns_desc=$(_lp_ns_desc "$ns")
    echo "lp $ns  —  $ns_desc"
    echo ""
    local cmds
    cmds=$(_lp_ns_cmds "$ns")
    for cmd in $cmds; do
        local desc usage example
        desc=$(_lp_cmd_desc "$ns" "$cmd")
        usage=$(_lp_cmd_usage "$ns" "$cmd")
        example=$(_lp_cmd_examples "$ns" "$cmd" | head -1)
        printf "  %-10s  %s\n" "$cmd" "$desc"
        printf "  %-10s  Usage:   %s\n" "" "$usage"
        printf "  %-10s  Example: %s\n" "" "$example"
        echo ""
    done
    echo "Run 'lp $ns <command> --help' for full options on a command."
}
