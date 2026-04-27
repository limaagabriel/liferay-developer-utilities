# AGENTS.md

Guidance for AI agents working in this repo. Applies to all agents (Claude, Gemini, Copilot, Codex, etc.).

## Project: `lp`

Bash CLI tools for Liferay Portal dev workflows. Manages Git worktrees, server bundles, MySQL, and tmux-based dev sessions.

## Architecture

- **Entrypoint:** `lp.sh` — sourced from user shell (`.zshrc` / `.bashrc`). Defines `$_LP_SCRIPTS_DIR`.
- **Commands:** `commands/<namespace>/<command>.sh` (e.g. `commands/worktree/start.sh`).
- **Sessions:** `session` namespace orchestrates tmux around a portal bundle, git UI (`lazygit`), and workspace shell. Core workflow.
- **Config:** `config.sh` loads `~/.config/lp/config` (per-user).
- **Libs:** `lib/init.sh` (`lp_init_command` setup helper), `lib/output.sh` (logging + exec helpers), `lib/help.sh` (help registry), `lib/worktree.sh`, `lib/session.sh`.
- **Completions:** `completions.sh` — branch-name tab-completion.
- **Aliases:** `aliases.sh` exposes `cdm` → `lp portal cdm`, `gw` → `lp portal gw`.

## Code Style — Clean Code

Inline comments are a readability code smell. Code should be self-explanatory through naming and structure.

### Comments

- **No inline WHAT-comments.** Don't restate code. `# Parse arguments` above a `while` loop is noise.
- **WHY-comments only, when non-obvious.** Workarounds, hidden constraints, surprising behavior. Rare.
- **No section banners** (`# 1. Tomcat`, `# --- Setup ---`). Extract a function instead.
- **No file headers describing the file.** The path and function names tell the story.

### Functions

- **Small + named.** Each command script defines `main()` plus a few helpers. Target ≤ ~20 lines per function.
- **SRP.** One job per function. If you write `# 1.`, `# 2.`, `# 3.` in a function, it's three functions.
- **Guard clauses.** Early-return on bad input. No nested `if/else` chains.
  ```bash
  [[ -f "$file" ]] || return 0
  [[ -n "$value" ]] || { lp_error "missing value"; return 1; }
  ```
- **Extract repeated logic.** Same 3+ lines twice → helper function.
- **`local` everywhere** inside functions. No leaked globals (except documented `_LP_*` and shared vars like `BRANCH`, `BUNDLE_DIR`).

### Command Script Skeleton

```bash
#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "<namespace>" "<command>" "$@"

parse_arguments() {
    BRANCH=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) shift ;;
            -*)
                lp_error "Unknown option: $1"
                return 1 2>/dev/null || exit 1
                ;;
            *) BRANCH="$1"; shift ;;
        esac
    done
}

main() {
    parse_arguments "$@" || return $?
    # ... helpers, lp_step, lp_run, lp_success
}

main "$@"
```

### Argument Parsing

- `case "$1" in ... esac` + `shift`. No `getopts` (Bash 3 / Zsh compat).
- Validate option args (`[[ -z "$2" ]]` → `lp_error` + return 1).
- Unknown flags → `lp_error` + `return 1 2>/dev/null || exit 1`.

### Error Handling

- No `set -e`. Explicit `|| return $?` or `|| exit 1`.
- Exit pattern: `return 1 2>/dev/null || exit 1` (works whether sourced or executed).
- All errors via `lp_error` (writes to stderr).

### Output Helpers (`lib/output.sh`)

Use these, not raw `echo`:

| Helper | Use |
|---|---|
| `lp_step N TOTAL "msg"` | progress in multi-step ops |
| `lp_info "msg"` | general info |
| `lp_success "msg"` | success confirmation |
| `lp_error "msg"` | errors → stderr |
| `lp_run <cmd>` | exec respecting `VERBOSE` |

### Sourcing & Compat

- Compatible with Bash 3+ and Zsh.
- Source libs via `$_LP_SCRIPTS_DIR` (NOT `$(dirname "${BASH_SOURCE[0]}")` — breaks in Zsh):
  - Preferred: `source "$_LP_SCRIPTS_DIR/lib/output.sh"`

### Variable Naming

- Globals: `_LP_*` prefix (shell isolation).
- Locals: `snake_case`. Shared cross-function state (when unavoidable): `UPPER_CASE` without prefix (e.g. `BRANCH`, `BUNDLE_DIR`, `OFFSET`).

## Adding a Command

1. Create `commands/<namespace>/<command>.sh` using the skeleton above.
2. Register in `lib/help.sh`: `_lp_ns_cmds`, `_lp_cmd_desc`, `_lp_cmd_usage`, `_lp_cmd_opts`, `_lp_cmd_examples`.
3. If command takes a branch arg, update `_lp_has_branch_arg` in `completions.sh`.
4. If command must affect the calling shell's CWD or env, add it to the source-list in `lp.sh` (`lp()` dispatcher).

## Sync Rules

- **Help:** `lp_init_command` handles `--help` automatically via the registry. New/changed commands → update `lib/help.sh`.
- **Aliases:** Script-level aliases (e.g. `session detach` → `session exit`) are registered in `lib/help.sh` via `_lp_cmd_alias`. Add them to `_lp_ns_cmds` if they should be visible in help.
- **Config:** new vars in `config.sh` or `commands/config/init.sh` → also update `commands/config/show.sh` (so `lp config` shows them).

## Safety

- Never run destructive ops (`remove`, `build`, etc.) on `master` branch or its bundle without explicit user confirmation.
