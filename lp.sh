#!/bin/bash
# lp - Liferay Portal script entrypoint
#
# This file must be sourced so that commands like `lp worktree cd` and
# `lp bundle cd` can change the current shell's directory.
#
# Add to ~/.zshrc or ~/.bashrc:
#   source ~/dev/scripts/lp.sh

if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval '_LP_SCRIPTS_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"'
else
    _LP_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

source "$_LP_SCRIPTS_DIR/lib/help.sh"
source "$_LP_SCRIPTS_DIR/lib/output.sh"

# Enable tab completion if configured (or if no user config exists yet, default yes)
_LP_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"
if [[ -f "$_LP_USER_CONFIG" ]]; then
    _LP_AUTOCOMPLETE=$(bash -c "source \"$_LP_USER_CONFIG\" 2>/dev/null; echo \${ENABLE_AUTOCOMPLETE:-yes}")
    _LP_ENABLE_ALIASES=$(bash -c "source \"$_LP_USER_CONFIG\" 2>/dev/null; echo \${ENABLE_ALIASES:-yes}")
else
    _LP_AUTOCOMPLETE=yes
    _LP_ENABLE_ALIASES=yes
fi

if [[ "$_LP_AUTOCOMPLETE" == yes ]] && [[ -f "$_LP_SCRIPTS_DIR/completions.sh" ]]; then
    source "$_LP_SCRIPTS_DIR/completions.sh"
fi

if [[ "$_LP_ENABLE_ALIASES" == yes ]] && [[ -f "$_LP_SCRIPTS_DIR/aliases.sh" ]]; then
    source "$_LP_SCRIPTS_DIR/aliases.sh"
fi

unset _LP_USER_CONFIG _LP_AUTOCOMPLETE _LP_ENABLE_ALIASES

lp() {
    # No arguments — show top-level help
    if [[ $# -eq 0 ]]; then
        lp_top_level_help
        return 1
    fi

    local namespace="$1"
    local command="$2"

    # lp help — top-level help
    if [[ "$namespace" == "help" ]]; then
        lp_top_level_help
        return 0
    fi

    # Validate namespace
    local ns_cmds
    ns_cmds=$(_lp_ns_cmds "$namespace")
    if [[ -z "$ns_cmds" ]]; then
        echo "lp: unknown namespace '$namespace'" >&2
        return 1
    fi

    # lp <ns> — namespace-level help (config defaults to show)
    if [[ $# -eq 1 ]]; then
        if [[ "$namespace" == "config" ]]; then
            "$_LP_SCRIPTS_DIR/commands/config/show.sh"
            return $?
        fi
        lp_namespace_help "$namespace"
        return 1
    fi

    local command="$2"

    # lp <ns> help — namespace-level help
    if [[ "$command" == "help" ]]; then
        lp_namespace_help "$namespace"
        return 0
    fi

    # Print preamble banner
    echo ""
    echo "Liferay Portal Developer CLI"
    echo "Running lp $namespace $command..."
    echo ""

    local script="$_LP_SCRIPTS_DIR/commands/$namespace/$command.sh"

    if [[ ! -f "$script" ]]; then
        echo "lp: unknown command '$namespace $command'" >&2
        return 1
    fi

    # Commands that must be sourced to affect the current shell's working directory
    # or environment (e.g. session-scoped variables)
    local _lp_start_time=$(date +%s)
    case "$namespace/$command" in
        worktree/cd|bundle/cd|worktree/set|worktree/unset|worktree/get|worktree/root|portal/cdm|portal/gw|worktree/add|modules/changed|modules/deploy)
            local _cd_args=("${@:3}")
            set -- "${_cd_args[@]}"
            source "$script"
            ;;
        *)
            _LP_SCRIPTS_DIR="$_LP_SCRIPTS_DIR" "$script" "${@:3}"
            ;;
    esac
    local _lp_exit_code=$?
    local _lp_end_time=$(date +%s)

    local _lp_duration=$((_lp_end_time - _lp_start_time))
    echo ""
    echo -n "Time spent: "
    lp_format_duration $_lp_duration
    echo ""
    echo ""

    return $_lp_exit_code
}
