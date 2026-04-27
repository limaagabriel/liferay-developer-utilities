# AGENTS.md

Guidance for AI agents working in this repo. Applies to all agents (Claude, Gemini, Copilot, Codex, etc.).

## Project: `lp`

Bash CLI tools for Liferay Portal dev workflows. Manages Git worktrees, server bundles, MySQL, and tmux-based dev sessions.

## Architecture

- **Entrypoint:** `lp.sh` — sourced from user shell (`.zshrc` / `.bashrc`). Defines `$_LP_SCRIPTS_DIR`.
- **Commands:** `commands/<namespace>/<command>.sh` (e.g. `commands/worktree/start.sh`).
- **Sessions:** `session` namespace orchestrates tmux around a portal bundle, git UI (`lazygit`), and workspace shell. Core workflow.
- **Config:** `config.sh` loads `~/.config/lp/config` (per-user).
- **Libs:** `lib/output.sh` (logging + exec helpers), `lib/help.sh` (help registry).
- **Completions:** `completions.sh` — branch-name tab-completion.
- **Aliases:** `aliases.sh` exposes `cdm` → `lp portal cdm`, `gw` → `lp portal gw`.

## Conventions

### Shell

- Compatible with Bash 3+ and Zsh.
- Source libs via `$_LP_SCRIPTS_DIR` (NOT `$(dirname "${BASH_SOURCE[0]}")` — breaks in Zsh):
  - Preferred: `source "$_LP_SCRIPTS_DIR/lib/output.sh"`
- Errors: call `lp_error` and exit non-zero.
- Verbosity: support `-v` / `--verbose` via `VERBOSE` var + `lp_run`.
- Help: every script handles `-h` / `--help` AND registers in `lib/help.sh`.

### Output helpers (`lib/output.sh`)

| Helper | Use |
|---|---|
| `lp_step N TOTAL "msg"` | progress in multi-step ops |
| `lp_info "msg"` | general info |
| `lp_success "msg"` | success confirmation |
| `lp_error "msg"` | errors → stderr |
| `lp_run <cmd>` | exec respecting `VERBOSE` |

## Adding a Command

1. Create `commands/<namespace>/<command>.sh`.
2. Handle `--help` internally.
3. Register in `lib/help.sh`: `_lp_ns_cmds`, `_lp_cmd_desc`, `_lp_cmd_usage`, `_lp_cmd_opts`, `_lp_cmd_examples`.
4. If command takes a branch arg, update `_lp_has_branch_arg` in `completions.sh`.

## Sync Rules

- **Help:** script's internal help and `lib/help.sh` must stay in sync.
- **Config:** new vars in `config.sh` or `commands/config/init.sh` → also update `commands/config/show.sh` (so `lp config` shows them).

## Safety

- Never run destructive ops (`remove`, `build`, etc.) on `master` branch or its bundle without explicit user confirmation.
