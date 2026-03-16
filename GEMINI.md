# GEMINI.md

## Project Context
This project, `lp`, is a collection of Bash-based CLI tools designed to streamline Liferay Portal development workflows. It manages Git worktrees, server bundles, local environment components like MySQL, and **full-blown development sessions using tmux**.

### Core Architecture
- **Entrypoint:** `lp.sh` is the main entry point. It should be sourced in the user's shell (e.g., `.zshrc` or `.bashrc`).
- **Command Structure:** Commands are organized by namespace in the `commands/` directory (e.g., `commands/worktree/start.sh`).
- **Development Sessions:** The `session` namespace provides the "bread and butter" workflow, orchestrating tmux to manage a portal bundle, git (e.g., via `lazygit`), and a workstation shell in a unified environment.
- **Configuration:** Shared configuration is handled in `config.sh`, which loads a per-user configuration file from `~/.config/lp/config`.
- **Libraries:** Common functions are located in the `lib/` directory:
  - `lib/output.sh`: Standardized logging and execution helpers.
  - `lib/help.sh`: Centralized help registry and display logic.
- **Completions:** `completions.sh` provides tab-completion for branch names.

## Engineering Standards

### Aliases & Shortcuts
- **Simplified Commands:** Users can source `aliases.sh` to get shorter commands for common portal tasks:
  - `source ~/dev/scripts/aliases.sh`
  - This provides `cdm` (for `lp portal cdm`) and `gw` (for `lp portal gw`).

### Bash Style & Conventions
- **Compatibility:** Scripts should be compatible with both Bash 3+ and Zsh.
- **Sourcing Libraries:** Always use the `$_LP_SCRIPTS_DIR` variable (defined in `lp.sh`) when sourcing libraries. This is more robust than using `$(dirname "${BASH_SOURCE[0]}")`, which can fail when sourced in Zsh.
  - **Preferred:** `source "$_LP_SCRIPTS_DIR/lib/output.sh"`
  - **Avoid:** `source "$(dirname "${BASH_SOURCE[0]}")/../../lib/output.sh"`
- **Error Handling:** Use `lp_error` for error messages and exit with a non-zero status code on failure.
- **Verbosity:** Support a `-v` or `--verbose` flag using the `VERBOSE` variable and the `lp_run` helper from `lib/output.sh`.
- **Help:** Every script should handle `--help` and `-h` flags internally, and also be registered in `lib/help.sh`.

### Logging & Output
- Use the following helpers from `lib/output.sh`:
  - `lp_step N TOTAL "message"`: To indicate progress in multi-step operations.
  - `lp_info "message"`: For general information.
  - `lp_success "message"`: To confirm successful completion.
  - `lp_error "message"`: To report errors to stderr.
  - `lp_run <command>`: To execute commands while respecting the `VERBOSE` setting.

### Adding New Commands
1. Create the script in `commands/<namespace>/<command>.sh`.
2. Ensure it handles `--help` internally.
3. Update `lib/help.sh` to include the new command in `_lp_ns_cmds`, `_lp_cmd_desc`, `_lp_cmd_usage`, `_lp_cmd_opts`, and `_lp_cmd_examples`.
4. If the command accepts a branch name, update `_lp_has_branch_arg` in `completions.sh`.

## Mandates for Gemini
- **Strict Adherence:** Always follow the standardized output patterns defined in `lib/output.sh`.
- **Help Synchronization:** When modifying or adding commands, ensure both the script's internal help and the centralized `lib/help.sh` are updated in sync.
- **Config Synchronization:** When adding or modifying configuration variables in `config.sh` or `commands/config/init.sh`, always update `commands/config/show.sh` to ensure the new variables are visible to the user via `lp config`.
- **Relative Paths:** Use relative path resolution (e.g., `$(dirname "${BASH_SOURCE[0]}")`) when sourcing files within scripts to ensure portability.
- **Master Branch Safety:** Never perform destructive operations (like `remove` or `build`) on the `master` branch or its bundle without explicit user confirmation.
