## 1. Create completions.sh

- [x] 1.1 Create `completions.sh` at the project root
- [x] 1.2 Implement `_lp_get_branches` helper that runs `git worktree list --porcelain` in `$MAIN_REPO_DIR` and extracts branch names by stripping the `$BASE_PROJECT_DIR/$MAIN_REPO_NAME-` prefix
- [x] 1.3 Handle missing/unset `$MAIN_REPO_DIR` gracefully (return empty list, no error output)
- [x] 1.4 Implement `_lp_complete` dispatch function that reads `COMP_WORDS` to determine the current namespace and command
- [x] 1.5 Wire branch completions for all supported subcommands: `worktree cd`, `worktree code`, `worktree start`, `worktree remove`, `worktree rebuild`, `worktree clean`, `bundle cd`, `bundle remove`, `mysql reset`, `mysql start`
- [x] 1.6 Ensure `worktree add` and all other non-branch subcommands produce no completions
- [x] 1.7 Register completion via `complete -F _lp_complete lp` for bash
- [x] 1.8 Add zsh compatibility shim: detect zsh, call `autoload bashcompinit && bashcompinit` before registering, fail silently if unavailable
- [x] 1.9 Add a shell guard so the script exits silently (no error) when sourced in an unsupported shell

## 2. Source config in completion function

- [x] 2.1 Source `config.sh` (or load `$_LP_SCRIPTS_DIR/config.sh`) inside the completion function so `$MAIN_REPO_DIR` and `$BASE_PROJECT_DIR`/`$MAIN_REPO_NAME` are available at completion time
- [x] 2.2 Verify that sourcing `config.sh` during completion does not produce visible output or side effects

## 3. Validate behavior

- [x] 3.1 Test `lp worktree cd <Tab>` in bash — confirm branch names from existing worktrees appear
- [x] 3.2 Test `lp worktree add <Tab>` — confirm no completions are offered
- [x] 3.3 Test `lp config show <Tab>` — confirm no completions are offered
- [x] 3.4 Test in zsh — confirm completions work via `bashcompinit` shim
- [x] 3.5 Test with no worktrees — confirm empty completion and no errors
- [x] 3.6 Test with `$MAIN_REPO_DIR` unset — confirm graceful fallback

## 4. Update help pages

- [x] 4.1 Review `lib/help.sh` to determine if any help text should reference `completions.sh`
- [x] 4.2 Add a usage note to the top-level help or README instructing users to source `completions.sh` for tab completion (e.g., `source /path/to/completions.sh` in `.bashrc`/`.zshrc`)
