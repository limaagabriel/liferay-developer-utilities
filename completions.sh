#!/bin/bash
# completions.sh — Shell tab completion for the lp command.
#
# Source this file in your ~/.bashrc or ~/.zshrc to enable tab completion:
#   source ~/dev/scripts/completions.sh

# Guard: exit silently when sourced in an unsupported shell (not bash or zsh)
[ -n "${BASH_VERSION:-}" ] || [ -n "${ZSH_VERSION:-}" ] || return 0

# Resolve scripts directory relative to this file so config.sh can be sourced
if [[ -n "${ZSH_VERSION:-}" ]]; then
    _LP_COMPLETIONS_SCRIPTS_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    _LP_COMPLETIONS_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# _lp_get_branches — output branch names derived from git worktrees
# Branches are extracted by stripping the BASE_PROJECT_DIR/MAIN_REPO_NAME- prefix
# from each registered worktree path, consistent with lp_branch_vars in config.sh.
_lp_get_branches() {
    local _config="$_LP_COMPLETIONS_SCRIPTS_DIR/config.sh"
    [[ -f "$_config" ]] || return 0

    # Source config silently. Don't bail on non-zero exit: config.sh may return
    # a non-zero code on some shells (e.g. zsh's ${!var} indirect expansion).
    # We check MAIN_REPO_DIR below to decide whether to proceed.
    source "$_config" 2>/dev/null

    # Require MAIN_REPO_DIR to be set and to exist
    [[ -n "${MAIN_REPO_DIR:-}" && -d "$MAIN_REPO_DIR" ]] || return 0

    local prefix="${BASE_PROJECT_DIR}/${MAIN_REPO_NAME}-"

    git -C "$MAIN_REPO_DIR" worktree list --porcelain 2>/dev/null \
        | awk '/^worktree /{print $2}' \
        | while IFS= read -r wt_path; do
            [[ "$wt_path" == "$prefix"* ]] && echo "${wt_path#$prefix}"
        done
}

# _lp_has_branch_arg <ns> <cmd>
# Returns 0 if the subcommand accepts a branch name as a positional argument.
# worktree/add is intentionally excluded — it creates new worktrees.
_lp_has_branch_arg() {
    case "$1/$2" in
        worktree/cd|worktree/start|worktree/remove|\
        worktree/rebuild|worktree/clean|worktree/set|bundle/cd|bundle/remove|\
        mysql/reset|mysql/start)
            return 0 ;;
        *)
            return 1 ;;
    esac
}

# Main completion function for the lp command.
_lp_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local ns="${COMP_WORDS[1]:-}"
    local cmd="${COMP_WORDS[2]:-}"

    COMPREPLY=()

    # Offer branch completions when past `lp <ns> <cmd>` and the current word is
    # not a flag, for subcommands that accept a branch name argument.
    if [[ $COMP_CWORD -ge 3 && "$cur" != -* ]] && _lp_has_branch_arg "$ns" "$cmd"; then
        local branches
        branches=$(_lp_get_branches)
        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "$branches" -- "$cur") )
    fi
}

# Register completion.
# bash: use the bash completion API directly.
# zsh:  use a native compdef function to avoid bashcompinit's broken arithmetic
#       (_bash_complete:8 bad math expression with QIPREFIX).
#       compdef is only available after compinit runs. If lp.sh is sourced
#       before compinit (the common case), defer via a precmd hook so the
#       registration happens at the first prompt, after compinit has run.
if [[ -n "${ZSH_VERSION:-}" ]]; then
    _lp_complete_zsh() {
        local ns="${words[2]:-}"
        local cmd="${words[3]:-}"

        # Offer branch completions at position 4 (lp <ns> <cmd> <branch>)
        if (( CURRENT == 4 )) && _lp_has_branch_arg "$ns" "$cmd"; then
            local -a branches
            branches=( $(_lp_get_branches) )
            compadd -- "${branches[@]}"
        fi
    }

    _lp_register_compdef() {
        compdef _lp_complete_zsh lp
        add-zsh-hook -d precmd _lp_register_compdef
        unset -f _lp_register_compdef
    }

    if (( $+functions[compdef] )); then
        # compinit already ran — register immediately
        compdef _lp_complete_zsh lp
    else
        # compinit hasn't run yet — defer to first prompt
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _lp_register_compdef
    fi
else
    complete -F _lp_complete lp
fi
