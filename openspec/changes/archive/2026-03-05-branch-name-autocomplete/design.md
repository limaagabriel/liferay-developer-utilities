## Context

The `lp` CLI tool is sourced into the user's shell via `lp.sh`. Commands that accept a branch name receive it as a positional argument (e.g., `lp worktree cd <branch>`). Currently there is no shell completion support, so users must type branch names manually.

Branch names correspond to git worktrees created under `$BASE_PROJECT_DIR`. The `git worktree list` command can enumerate these at runtime to produce the candidate list for completion.

## Goals / Non-Goals

**Goals:**
- Provide tab completion for the branch name positional argument across all relevant `lp` subcommands
- Source branch names dynamically from existing git worktrees at completion time
- Exclude `worktree add` from branch completion (it creates new worktrees)
- Work in bash and zsh without extra dependencies
- Keep the completion script standalone and opt-in (sourced separately from `lp.sh`)

**Non-Goals:**
- Completing flags/options (already documented via help system, out of scope)
- Fish shell support
- Caching or performance optimization for very large worktree lists
- Auto-sourcing the completions script (user must opt-in)

## Decisions

### 1. Separate `completions.sh` file, not embedded in `lp.sh`

Completion logic is shell-specific and only meaningful in interactive sessions. Keeping it in a dedicated `completions.sh` avoids polluting `lp.sh`, which is also used in non-interactive contexts (e.g., scripts). Users source it explicitly in their `.bashrc`/`.zshrc`.

**Alternative considered**: Embed completion in `lp.sh` with a guard (`[[ $- == *i* ]]`). Rejected — mixing interactive-only code into the main script increases complexity and makes the file harder to reason about.

### 2. Single completion function dispatching on namespace + command

A single `_lp_complete` function handles all subcommands. It inspects `COMP_WORDS` (bash) / the word array (zsh) to determine the current namespace and command, then decides whether to offer branch completions.

**Alternative considered**: Register separate completion functions per subcommand. Rejected — too much duplication; the dispatch table is simple enough to maintain in one place.

### 3. Branch names sourced from `git worktree list` at completion time

Running `git worktree list --porcelain` and extracting branch names is reliable and always up-to-date. The branch portion is derived by stripping the `$BASE_PROJECT_DIR/$MAIN_REPO_NAME-` prefix from the worktree path, consistent with how `lp_branch_vars` works.

**Alternative considered**: Read directory names from `$BASE_PROJECT_DIR` directly. Rejected — less authoritative than git's own worktree list; could pick up non-worktree directories.

### 4. Bash-first with a zsh compatibility shim

The rest of the codebase targets bash syntax. The completion script will use bash completion (`complete -F`) as its primary mechanism. For zsh, a small `bashcompinit` shim enables bash-style completions without requiring a full zsh-native completion.

## Risks / Trade-offs

- **`$MAIN_REPO_DIR` not set at completion time** → Mitigation: source `config.sh` inside the completion function (already the pattern used by command scripts), or fall back gracefully with an empty list.
- **Performance**: `git worktree list` is fast for typical worktree counts, but adds a subprocess per tab-press. Acceptable for the expected scale (< 20 worktrees). → Mitigation: document that caching can be added later if needed.
- **zsh compatibility**: `bashcompinit` is widely available but not universal. → Mitigation: wrap the zsh shim in a version check and fail silently if unavailable.

## Open Questions

- Should `completions.sh` be auto-sourced when `lp.sh` is sourced (with an opt-out flag), or always manual? Currently leaning manual/opt-in to avoid breaking non-interactive use.
    - Can it be configured using lp config init? If so, it would be great.
