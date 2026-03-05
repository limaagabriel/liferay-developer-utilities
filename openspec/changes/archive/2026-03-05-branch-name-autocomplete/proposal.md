## Why

Many `lp` commands accept a branch name as a positional argument (e.g., `worktree cd`, `worktree remove`, `bundle cd`), but users must type branch names from memory. Tab completion sourced from existing git worktrees would reduce friction and prevent typos.

## What Changes

- Add a shell completion script that can be sourced alongside `lp.sh`
- Completion resolves branch names from existing git worktrees at completion time
- All branch-name-accepting commands get completions: `worktree cd`, `worktree code`, `worktree start`, `worktree remove`, `worktree rebuild`, `worktree clean`, `bundle cd`, `bundle remove`, `mysql reset`, `mysql start`
- `worktree add` is **excluded** — it creates new worktrees, so completing existing names would be misleading

## Capabilities

### New Capabilities
- `branch-name-completion`: Shell tab completion for the branch name positional argument, populated from existing git worktrees, wired to all relevant `lp` subcommands (excluding `worktree add`)

### Modified Capabilities
*(none)*

## Impact

- New file (e.g., `completions.sh`) to be sourced alongside `lp.sh`
- `lp.sh` or user setup docs may need a note about sourcing the completions file
- No breaking changes
