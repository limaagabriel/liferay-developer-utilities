#!/bin/bash
# Lints commands/**/*.sh: every plain command/function call inside main()
# must be guarded with `||`/`&&`, unless it is exempt (see below).
#
# Usage: lint_main_guards.sh <scripts-root>
# Prints "file:line: <statement>" for each offender and exits non-zero if
# any were found.
#
# Exclusions (never checked):
#   - local declarations, plain assignments (`x=...`, `x=$(cmd)`, including
#     `x="${x:-$(cmd)}"`). This codebase relies on unguarded fallback
#     assignments throughout, so requiring `||` there would flag the whole
#     tree rather than real risk; guarded calls that matter are chained as
#     standalone statements instead.
#   - output helpers: lp_step, lp_info, lp_success, lp_error, echo, printf.
#   - return, exit, shift, trap, unset, export, set --, ((...)), [[ ]], [ ].
#   - lp_init_command: it exits by itself when the script is executed
#     directly, and every sourced-command caller already guards it with
#     `|| { ... }` at the one call site that matters for that path.
#   - calls to a function defined in the same file whose body's last
#     statement is a bare `exit <n>` (e.g. abort_bisect) — it never returns
#     control to the caller, so there is nothing to guard.
#   - a pipeline immediately followed by a `[[ "${PIPESTATUS[...]}" ... ]] ||`
#     line — that next line is the guard, just not on the same line.
#   - a line carrying a trailing `# lint: report-after-failure` comment —
#     the deliberate "run everything, report failures at the end" pattern.
#   - case/esac bodies are skipped entirely (never parsed into statements),
#     so "the last statement of a case arm" is vacuously exempt too.
#
# Tail position: a statement is exempt from the `||`/`&&` requirement when
# it is main's last statement, OR the last statement of an if/elif/else
# branch whose enclosing if-chain is itself in tail position of main,
# recursively. `for`/`while`/`until` bodies never inherit tail position:
# every statement inside a loop must be guarded regardless of where it sits.
#
# "Last statement" is computed in source order, not just over the nodes
# that survive into the tree: a candidate statement stops being tail the
# moment any other line follows it in the same sequence, UNLESS that
# trailing line is a bare `return` / `return $?` / `exit $?` (which just
# forwards the candidate's own exit status). Anything else that follows —
# `lp_success "Done!"`, `echo ...`, `return 0`, a plain assignment, a
# `[[ ]]` test — breaks the chain, because main's actual exit status would
# come from that trailing line instead of the candidate.

_lp_lint_extract_main_lines() {
    local file="$1"
    awk '
        /^main\(\)[[:space:]]*\{[[:space:]]*$/ { capture=1; next }
        capture {
            if ($0 == "}") { capture=0; next }
            print NR "\t" $0
        }
    ' "$file"
}

_lp_lint_scan_always_exit_functions() {
    local file="$1"
    awk '
        /^[A-Za-z_][A-Za-z0-9_]*\(\)[[:space:]]*\{[[:space:]]*$/ {
            name = $0
            sub(/\(\).*/, "", name)
            in_func = 1
            last = ""
            next
        }
        in_func && $0 == "}" {
            if (last ~ /^exit([[:space:]]|$)/) print name
            in_func = 0
            next
        }
        in_func {
            line = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line != "" && line !~ /^#/) last = line
            next
        }
    ' "$file"
}

_lp_lint_trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Reads tab-separated "lineno<TAB>text" from stdin, joins backslash
# continuations, and populates the global LINE_NO[] / LINE_TXT[] arrays
# (trimmed) in order.
_lp_lint_load_lines() {
    LINE_NO=()
    LINE_TXT=()
    local start_line="" joined=""
    while IFS=$'\t' read -r lineno text; do
        if [[ -n "$joined" ]]; then
            joined="$joined $text"
        else
            start_line="$lineno"
            joined="$text"
        fi

        if [[ "$joined" == *\\ ]]; then
            joined="${joined%\\}"
            continue
        fi

        LINE_NO+=("$start_line")
        LINE_TXT+=("$(_lp_lint_trim "$joined")")
        joined=""
    done
}

_lp_lint_is_plain_assignment() {
    local line="$1"
    [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*\+?=[^=] ]] || [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*\+?=$ ]]
}

_lp_lint_first_word() {
    local line="$1"
    line="${line%%[ $'\t']*}"
    printf '%s' "$line"
}

_lp_lint_is_always_exit_call() {
    local line="$1"
    local word
    word="$(_lp_lint_first_word "$line")"
    [[ -n "$word" ]] || return 1
    local fn
    for fn in "${ALWAYS_EXIT_FNS[@]}"; do
        [[ "$word" == "$fn" ]] && return 0
    done
    return 1
}

_lp_lint_has_marker() {
    [[ "$1" == *"# lint: report-after-failure"* ]]
}

# Whether an excluded line still lets the candidate statement before it
# stay "tail": NEUTRAL (blank/comment/brace) never touches the candidate,
# PROPAGATE (`return`, `return $?`, `exit $?`) forwards it unchanged, and
# everything else (BLOCKING) clears it — that line's own exit status is
# what main would actually return, not the candidate's.
_lp_lint_excluded_kind() {
    local line="$1"

    if [[ -z "$line" || "$line" == \#* || "$line" == "{" || "$line" == "}" ]]; then
        printf 'NEUTRAL'
        return
    fi

    if [[ "$line" =~ ^return[[:space:]]*$ ]] \
        || [[ "$line" =~ ^return[[:space:]]+\"?\$\?\"?[[:space:]]*$ ]] \
        || [[ "$line" =~ ^exit[[:space:]]+\"?\$\?\"?[[:space:]]*$ ]]; then
        printf 'PROPAGATE'
        return
    fi

    printf 'BLOCKING'
}

_lp_lint_is_leaf_excluded() {
    local line="$1"

    [[ -z "$line" ]] && return 0
    [[ "$line" == \#* ]] && return 0
    [[ "$line" == "{" || "$line" == "}" ]] && return 0
    [[ "$line" == "local" || "$line" == local\ * ]] && return 0
    _lp_lint_is_plain_assignment "$line" && return 0
    [[ "$line" =~ ^(return|exit|shift)([[:space:]]|$) ]] && return 0
    [[ "$line" =~ ^(trap|unset|export)[[:space:]] ]] && return 0
    [[ "$line" =~ ^set[[:space:]]+-- ]] && return 0
    [[ "$line" =~ ^(lp_step|lp_info|lp_success|lp_error|echo|printf)([[:space:]]|$) ]] && return 0
    [[ "$line" =~ ^lp_init_command([[:space:]]|$) ]] && return 0
    [[ "$line" =~ ^\(\(.*\)\)$ ]] && return 0
    [[ "$line" =~ ^\[\[.*\]\] ]] && return 0
    [[ "$line" =~ ^\[[[:space:]].*\]$ ]] && return 0
    _lp_lint_is_always_exit_call "$line" && return 0
    _lp_lint_has_marker "$line" && return 0

    return 1
}

_lp_lint_has_pipe() {
    local without_or="${1//||/}"
    [[ "$without_or" == *"|"* ]]
}

_lp_lint_is_guarded() {
    local line="$1"
    [[ "$line" == *"||"* || "$line" == *"&&"* ]]
}

# Node kinds: SEQ (ordered list of child node ids), STMT (a checkable
# statement), IFCHAIN (children are branch SEQ node ids), LOOP (single SEQ
# child, never tail-propagated), CASE (opaque, no children).

_lp_lint_new_node() {
    NODE_COUNT=$((NODE_COUNT + 1))
    NODE_TYPE[$NODE_COUNT]="$1"
    NODE_CHILDREN[$NODE_COUNT]=""
    NEW_NODE_ID=$NODE_COUNT
}

_lp_lint_peek() {
    if [[ "$CURSOR" -lt "$N" ]]; then
        PEEK_TXT="${LINE_TXT[$CURSOR]}"
    else
        PEEK_TXT=""
    fi
}

_lp_lint_is_terminator() {
    [[ "$1" =~ ^(elif|else|fi|done|esac)([[:space:]]|\;|$) ]] && return 0
    [[ "$1" == ")" || "$1" == ")"* ]] && return 0
    return 1
}

_lp_lint_skip_to_keyword() {
    local keyword="$1"
    while [[ "$CURSOR" -lt "$N" ]]; do
        _lp_lint_peek
        [[ "$PEEK_TXT" == "$keyword" || "$PEEK_TXT" == "$keyword "* ]] && { CURSOR=$((CURSOR + 1)); return; }
        CURSOR=$((CURSOR + 1))
    done
}

_lp_lint_parse_if_chain() {
    _lp_lint_new_node IFCHAIN
    local ifchain_id=$NEW_NODE_ID

    _lp_lint_peek
    local if_header="$PEEK_TXT"
    CURSOR=$((CURSOR + 1))
    if [[ "$if_header" != *then ]]; then
        _lp_lint_skip_to_keyword "then"
    fi

    _lp_lint_parse_sequence
    NODE_CHILDREN[$ifchain_id]+=" $NEW_NODE_ID"

    while true; do
        _lp_lint_peek
        if [[ "$PEEK_TXT" == elif* ]]; then
            local header="$PEEK_TXT"
            CURSOR=$((CURSOR + 1))
            if [[ "$header" != *then ]]; then
                _lp_lint_skip_to_keyword "then"
            fi
            _lp_lint_parse_sequence
            NODE_CHILDREN[$ifchain_id]+=" $NEW_NODE_ID"
        elif [[ "$PEEK_TXT" == "else" || "$PEEK_TXT" == "else;" ]]; then
            CURSOR=$((CURSOR + 1))
            _lp_lint_parse_sequence
            NODE_CHILDREN[$ifchain_id]+=" $NEW_NODE_ID"
        else
            break
        fi
    done

    _lp_lint_peek
    [[ "$PEEK_TXT" == fi* ]] && CURSOR=$((CURSOR + 1))
    NEW_NODE_ID=$ifchain_id
}

_lp_lint_parse_loop() {
    _lp_lint_new_node LOOP
    local loop_id=$NEW_NODE_ID

    _lp_lint_peek
    local header="$PEEK_TXT"
    CURSOR=$((CURSOR + 1))
    if [[ "$header" != *do ]]; then
        _lp_lint_skip_to_keyword "do"
    fi

    _lp_lint_parse_sequence
    NODE_CHILDREN[$loop_id]=" $NEW_NODE_ID"

    _lp_lint_peek
    [[ "$PEEK_TXT" == done* ]] && CURSOR=$((CURSOR + 1))
    NEW_NODE_ID=$loop_id
}

_lp_lint_parse_case() {
    _lp_lint_new_node CASE
    local case_id=$NEW_NODE_ID
    local depth=1
    CURSOR=$((CURSOR + 1))
    while [[ "$CURSOR" -lt "$N" && "$depth" -gt 0 ]]; do
        _lp_lint_peek
        if [[ "$PEEK_TXT" =~ ^case([[:space:]]|$) ]]; then
            depth=$((depth + 1))
        elif [[ "$PEEK_TXT" == "esac" || "$PEEK_TXT" == esac\;* ]]; then
            depth=$((depth - 1))
        fi
        CURSOR=$((CURSOR + 1))
    done
    NEW_NODE_ID=$case_id
}

_lp_lint_parse_paren() {
    _lp_lint_new_node PAREN
    local paren_id=$NEW_NODE_ID
    CURSOR=$((CURSOR + 1))

    _lp_lint_parse_sequence
    NODE_CHILDREN[$paren_id]=" $NEW_NODE_ID"

    _lp_lint_peek
    [[ "$PEEK_TXT" == ")" || "$PEEK_TXT" == ")"* ]] && CURSOR=$((CURSOR + 1))
    NEW_NODE_ID=$paren_id
}

_lp_lint_parse_sequence() {
    _lp_lint_new_node SEQ
    local seq_id=$NEW_NODE_ID
    local tail_candidate=""

    while [[ "$CURSOR" -lt "$N" ]]; do
        _lp_lint_peek
        _lp_lint_is_terminator "$PEEK_TXT" && break

        if [[ "$PEEK_TXT" =~ ^if([[:space:]]|$) ]]; then
            _lp_lint_parse_if_chain
            NODE_CHILDREN[$seq_id]+=" $NEW_NODE_ID"
            tail_candidate="$NEW_NODE_ID"
        elif [[ "$PEEK_TXT" =~ ^(for|while|until)([[:space:]]|$) ]]; then
            _lp_lint_parse_loop
            NODE_CHILDREN[$seq_id]+=" $NEW_NODE_ID"
            tail_candidate="$NEW_NODE_ID"
        elif [[ "$PEEK_TXT" =~ ^case([[:space:]]|$) ]]; then
            _lp_lint_parse_case
            NODE_CHILDREN[$seq_id]+=" $NEW_NODE_ID"
            tail_candidate="$NEW_NODE_ID"
        elif [[ "$PEEK_TXT" == "(" ]]; then
            _lp_lint_parse_paren
            NODE_CHILDREN[$seq_id]+=" $NEW_NODE_ID"
            tail_candidate="$NEW_NODE_ID"
        elif _lp_lint_is_leaf_excluded "$PEEK_TXT"; then
            local kind
            kind="$(_lp_lint_excluded_kind "$PEEK_TXT")"
            [[ "$kind" == "BLOCKING" ]] && tail_candidate=""
            CURSOR=$((CURSOR + 1))
        else
            local lineno="${LINE_NO[$CURSOR]}"
            local text="$PEEK_TXT"
            local nexttxt=""
            [[ "$((CURSOR + 1))" -lt "$N" ]] && nexttxt="${LINE_TXT[$((CURSOR + 1))]}"
            CURSOR=$((CURSOR + 1))

            if _lp_lint_has_pipe "$text" && [[ "$nexttxt" == *PIPESTATUS*"||"* ]]; then
                continue
            fi

            _lp_lint_new_node STMT
            NODE_LINE[$NEW_NODE_ID]="$lineno"
            NODE_TEXT[$NEW_NODE_ID]="$text"
            NODE_CHILDREN[$seq_id]+=" $NEW_NODE_ID"
            tail_candidate="$NEW_NODE_ID"
        fi
    done

    SEQ_TAIL[$seq_id]="$tail_candidate"
    NEW_NODE_ID=$seq_id
}

# Tail-position exemption: walks the tree from the root, marking the one
# chain of nodes whose exit status flows through to main's own exit status
# (see the "Tail position" note at the top of this file).
_lp_lint_mark_tail() {
    local node_id="$1"
    local type="${NODE_TYPE[$node_id]}"

    case "$type" in
        SEQ)
            local candidate="${SEQ_TAIL[$node_id]:-}"
            [[ -z "$candidate" ]] && return
            _lp_lint_mark_tail "$candidate"
            ;;
        STMT)
            EXEMPT_LINES["${NODE_LINE[$node_id]}"]=1
            ;;
        IFCHAIN)
            local branch
            for branch in ${NODE_CHILDREN[$node_id]}; do
                _lp_lint_mark_tail "$branch"
            done
            ;;
        PAREN)
            _lp_lint_mark_tail "${NODE_CHILDREN[$node_id]# }"
            ;;
        LOOP|CASE)
            return
            ;;
    esac
}

_lp_lint_collect_offenders() {
    local node_id="$1"
    local type="${NODE_TYPE[$node_id]}"

    case "$type" in
        SEQ)
            local child
            for child in ${NODE_CHILDREN[$node_id]}; do
                _lp_lint_collect_offenders "$child"
            done
            ;;
        STMT)
            local lineno="${NODE_LINE[$node_id]}"
            [[ -n "${EXEMPT_LINES[$lineno]:-}" ]] && return
            _lp_lint_is_guarded "${NODE_TEXT[$node_id]}" && return
            OFFENDERS+=("$lineno"$'\t'"${NODE_TEXT[$node_id]}")
            ;;
        IFCHAIN)
            local branch
            for branch in ${NODE_CHILDREN[$node_id]}; do
                _lp_lint_collect_offenders "$branch"
            done
            ;;
        LOOP|PAREN)
            _lp_lint_collect_offenders "${NODE_CHILDREN[$node_id]# }"
            ;;
        CASE) ;;
    esac
}

_lp_lint_file_offenders() {
    local file="$1"

    ALWAYS_EXIT_FNS=()
    while IFS= read -r fn; do
        [[ -n "$fn" ]] && ALWAYS_EXIT_FNS+=("$fn")
    done < <(_lp_lint_scan_always_exit_functions "$file")

    _lp_lint_load_lines < <(_lp_lint_extract_main_lines "$file")
    N="${#LINE_TXT[@]}"
    [[ "$N" -eq 0 ]] && return 0

    CURSOR=0
    NODE_COUNT=0
    declare -gA NODE_TYPE=()
    declare -gA NODE_CHILDREN=()
    declare -gA NODE_LINE=()
    declare -gA NODE_TEXT=()
    declare -gA SEQ_TAIL=()

    _lp_lint_parse_sequence
    local root_id=$NEW_NODE_ID

    declare -gA EXEMPT_LINES=()
    _lp_lint_mark_tail "$root_id"

    OFFENDERS=()
    _lp_lint_collect_offenders "$root_id"

    [[ "${#OFFENDERS[@]}" -eq 0 ]] && return 0

    local entry lineno text
    for entry in "${OFFENDERS[@]}"; do
        lineno="${entry%%$'\t'*}"
        text="${entry#*$'\t'}"
        printf '%s:%s: %s\n' "$file" "$lineno" "$text"
    done
    return 1
}

lint_main_guards() {
    local root="$1"
    local file
    local offenders=0

    while IFS= read -r file; do
        local out
        out="$(_lp_lint_file_offenders "$file")"
        if [[ -n "$out" ]]; then
            printf '%s\n' "$out"
            offenders=1
        fi
    done < <(find "$root/commands" -name '*.sh' | sort)

    return "$offenders"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    lint_main_guards "${1:-.}"
    exit $?
fi
