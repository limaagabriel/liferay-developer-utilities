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
_LP_NAMESPACES="worktree bundle portal playwright mysql config git"

# _lp_ns_desc <ns> — one-line description for a namespace
_lp_ns_desc() {
    case "$1" in
        worktree) echo "Manage git worktrees for portal branches" ;;
        bundle)   echo "Manage Liferay bundle directories" ;;
        portal)   echo "Liferay Portal development utilities" ;;
        playwright) echo "Playwright test utilities" ;;
        mysql)    echo "Manage the MySQL Docker container" ;;
        config)   echo "Manage per-user lp configuration" ;;
        git)      echo "Git utilities" ;;
        *)        echo "" ;;
    esac
}

# _lp_ns_cmds <ns> — space-separated command list for a namespace (defines display order)
_lp_ns_cmds() {
    case "$1" in
        worktree) echo "add build cd list remove start get set unset root" ;;
        bundle)   echo "cd remove" ;;
        portal)   echo "cdm gw" ;;
        playwright) echo "test" ;;
        mysql)    echo "reset start" ;;
        config)   echo "show init" ;;
        git)      echo "patch" ;;
        *)        echo "" ;;
    esac
}

# _lp_cmd_desc <ns> <cmd> — one-line description
_lp_cmd_desc() {
    case "$1/$2" in
        worktree/add)     echo "Add a new git worktree for a branch" ;;
        worktree/cd)      echo "Change the current directory to a worktree" ;;
        worktree/list)    echo "List all active worktrees and their bundles" ;;
        worktree/build)   echo "Build the portal bundle from the worktree" ;;
        worktree/remove)  echo "Remove a worktree and its bundle directory" ;;
        worktree/start)   echo "Start the Liferay server for a worktree" ;;
        worktree/get)     echo "Get the current session's reference branch" ;;
        worktree/set)     echo "Set the reference branch for the session" ;;
        worktree/unset)   echo "Reset the reference branch to master" ;;
        worktree/root)    echo "Change the current directory to the root of the active worktree" ;;
        portal/cdm)       echo "Fuzzy module search and cd in the current git repository" ;;
        portal/gw)        echo "Run gradle tasks in the current directory" ;;
        playwright/test)  echo "Run Playwright tests in the current worktree" ;;
        bundle/cd)        echo "Change the current directory to a bundle" ;;
        bundle/remove)    echo "Remove a bundle directory" ;;
        mysql/reset)      echo "Reset the lportal database (drop and recreate)" ;;
        mysql/start)      echo "Start MySQL via Docker Compose and reset the database" ;;
        config/show)      echo "Show the currently resolved lp configuration" ;;
        config/init)      echo "Interactively create the per-user config file" ;;
        git/patch)        echo "Download a git patch from a URL and apply it" ;;
        *)                echo "" ;;
    esac
}

# _lp_cmd_usage <ns> <cmd> — usage synopsis
_lp_cmd_usage() {
    case "$1/$2" in
        worktree/add)     echo "lp worktree add [-r <remote>] [-v] <branch>" ;;
        worktree/cd)      echo "lp worktree cd <branch>" ;;
        worktree/list)    echo "lp worktree list" ;;
        worktree/build) echo "lp worktree build [-v] <branch>" ;;
        worktree/remove)  echo "lp worktree remove [-v] <branch>" ;;
        worktree/start)   echo "lp worktree start [-v] [branch]" ;;
        worktree/get)     echo "lp worktree get" ;;
        worktree/set)     echo "lp worktree set [branch-name]" ;;
        worktree/unset)   echo "lp worktree unset" ;;
        worktree/root)    echo "lp worktree root" ;;
        portal/cdm)       echo "lp portal cdm" ;;
        portal/gw)        echo "lp portal gw [tasks...]" ;;
        playwright/test)  echo "lp playwright test [options] <test-name>" ;;
        bundle/cd)        echo "lp bundle cd <branch>" ;;
        bundle/remove)    echo "lp bundle remove [-v] <branch>" ;;
        mysql/reset)      echo "lp mysql reset [-v]" ;;
        mysql/start)      echo "lp mysql start [-v]" ;;
        config/show)      echo "lp config" ;;
        config/init)      echo "lp config init" ;;
        git/patch)        echo "lp git patch [-c] [-v] <url>" ;;
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
        worktree/list)
            echo "  -h, --help   Show this help"
            ;;
        worktree/build)
            echo "  -v, --verbose   Show full ant/git output"
            echo "  -h, --help      Show this help"
            ;;
        worktree/remove)
            echo "  -v, --verbose   Show full git output"
            echo "  -h, --help      Show this help"
            ;;
        worktree/start)
            echo "  -v, --verbose   Show full ant output (catalina log always shown)"
            echo "  -h, --help      Show this help"
            ;;
        worktree/get)
            echo "  -h, --help      Show this help"
            ;;
        worktree/set)
            echo "  -h, --help      Show this help"
            ;;
        worktree/unset)
            echo "  -h, --help      Show this help"
            ;;
        worktree/root)
            echo "  -h, --help      Show this help"
            ;;
        portal/cdm)
            echo "  -h, --help      Show this help"
            echo "  Note: Requires 'fzf' to be installed"
            ;;
        portal/gw)
            echo "  -h, --help      Show this help"
            ;;
        playwright/test)
            echo "  -n <number>     Number of times to run the test (default: 1)"
            echo "  -g <string>     Filter to only run tests with a title matching the given string"
            echo "  --ui            Open Playwright UI"
            echo "  -v, --verbose   Show full playwright output"
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
        config/show)
            echo "  -h, --help   Show this help"
            ;;
        config/init)
            echo "  -h, --help   Show this help"
            ;;
        git/patch)
            echo "  -c, --commit    Apply the patch as a commit (default: leave changes uncommitted)"
            echo "  -v, --verbose   Show full git output"
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
        worktree/list)
            echo "  lp worktree list"
            ;;
        worktree/build)
            echo "  lp worktree build main"
            echo "  lp worktree build --verbose main"
            ;;
        worktree/remove)
            echo "  lp worktree remove main"
            ;;
        worktree/start)
            echo "  lp worktree start main"
            echo "  lp worktree start           # uses current directory"
            ;;
        worktree/get)
            echo "  lp worktree get"
            ;;
        worktree/set)
            echo "  lp worktree set main"
            echo "  lp worktree set             # uses current directory if in worktree"
            ;;
        worktree/unset)
            echo "  lp worktree unset"
            ;;
        worktree/root)
            echo "  lp worktree root"
            ;;
        portal/cdm)
            echo "  lp portal cdm"
            ;;
        portal/gw)
            echo "  lp portal gw clean deploy"
            ;;
        playwright/test)
            echo "  lp playwright test tests/my-test.spec.ts"
            echo "  lp playwright test -n 5 tests/flaky-test.spec.ts"
            echo "  lp playwright test -g 'my test title' tests/my-test.spec.ts"
            echo "  lp playwright test --ui tests/my-test.spec.ts"
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
        config/show)
            echo "  lp config"
            ;;
        config/init)
            echo "  lp config init"
            ;;
        git/patch)
            echo "  lp git patch https://example.com/fix.patch"
            echo "  lp git patch --commit https://example.com/fix.patch"
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
    echo "   or: lp gw [branch] [tasks...]"
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
    echo ""
    echo "Tip: source completions.sh to enable tab completion for branch names."
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
