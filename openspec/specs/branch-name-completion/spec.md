### Requirement: Completion script is a standalone file
A `completions.sh` file SHALL be provided at the root of the project. It MUST be sourced explicitly by the user (e.g., in `.bashrc` or `.zshrc`) and SHALL NOT be auto-sourced by `lp.sh`.

#### Scenario: User sources completions script
- **WHEN** the user adds `source /path/to/completions.sh` to their shell config
- **THEN** tab completion for the `lp` command becomes active in their shell session

#### Scenario: completions.sh is not sourced
- **WHEN** the user has not sourced `completions.sh`
- **THEN** the `lp` command works normally without any completion behavior

---

### Requirement: Branch names are completed from existing git worktrees
The completion script SHALL resolve branch name candidates by reading the list of git worktrees from `$MAIN_REPO_DIR` at completion time.

#### Scenario: Worktrees exist
- **WHEN** the user presses Tab on a branch name argument
- **THEN** the completion offers branch names derived from the worktrees currently registered in `$MAIN_REPO_DIR`

#### Scenario: No worktrees exist
- **WHEN** no git worktrees exist beyond the main repo
- **THEN** no completions are offered and the shell behaves as if no completion is registered

#### Scenario: Config is not loaded
- **WHEN** `$MAIN_REPO_DIR` is not set at completion time
- **THEN** the completion function SHALL fall back gracefully (empty list, no error output)

---

### Requirement: Completion is wired to branch-accepting subcommands
The completion script SHALL provide branch name completions for the following subcommands and SHALL NOT offer them for any other subcommands:
- `lp worktree cd <branch>`
- `lp worktree code <branch>`
- `lp worktree start <branch>`
- `lp worktree remove <branch>`
- `lp worktree build <branch>`
- `lp worktree clean <branch>`
- `lp bundle cd <branch>`
- `lp bundle remove <branch>`
- `lp mysql reset <branch>`
- `lp mysql start <branch>`

#### Scenario: Completing a supported subcommand
- **WHEN** the user types `lp worktree cd <Tab>` (or any other supported subcommand)
- **THEN** the shell presents matching branch names from existing worktrees

#### Scenario: Completing an excluded subcommand
- **WHEN** the user types `lp worktree add <Tab>`
- **THEN** no branch name completions are offered

#### Scenario: Completing unknown subcommand
- **WHEN** the user types `lp config show <Tab>`
- **THEN** no branch name completions are offered

---

### Requirement: worktree add is excluded from branch completion
The `lp worktree add` subcommand SHALL NOT offer branch name completions, because it creates a new worktree and completing an existing branch name would be misleading.

#### Scenario: worktree add tab completion
- **WHEN** the user types `lp worktree add <Tab>`
- **THEN** no completions are offered for the branch name argument

---

### Requirement: Completion works in bash and zsh
The completion script SHALL work in bash (via `complete -F`) and in zsh (via `bashcompinit` shim). No additional dependencies beyond a standard bash/zsh installation SHALL be required.

#### Scenario: Bash completion
- **WHEN** the script is sourced in a bash shell
- **THEN** `complete -F` registers the completion function and tab completion works

#### Scenario: Zsh completion
- **WHEN** the script is sourced in a zsh shell
- **THEN** `bashcompinit` is invoked and bash-style completion works for the `lp` command

#### Scenario: Unsupported shell
- **WHEN** the script is sourced in a shell that is neither bash nor zsh
- **THEN** the script exits silently without error and no completion is registered
