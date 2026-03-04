## Why

The `lp` CLI currently has no discoverable help system: the top-level usage block is hardcoded and must be manually kept in sync, there is no way to list commands for a single namespace, individual scripts don't support `--help`, and there is a stray debug `echo script: "$script"` line leaking implementation details. Additionally, command output is inconsistent and noisy — underlying tools (git, ant, docker) flood the terminal with raw logs, making it hard to follow what the script is actually doing. As the tool grows, this makes it brittle and unfriendly for new users.


## What Changes

- Add `lp help` command and improve `lp` (no args) output to show all namespaces with their commands and short descriptions
- Add `lp <namespace>` (namespace only, no command) to show that namespace's commands and descriptions instead of the generic error
- Add `--help` / `-h` flag support to every individual script, printing usage + description and exiting cleanly
- Remove the stray `echo script: "$script"` debug line from the `lp` entrypoint
- Fix incorrect usage comment in `bundle/remove` (says `lp worktree remove`)
- Standardize help output format across all scripts (consistent header, options, examples)
- Standardize runtime output: all scripts print structured step progress (`[1/3] Doing X...`) and suppress verbose logs from underlying commands (git, ant, docker, etc.), with raw output redirected to a log file or hidden unless `--verbose` is passed. Only the catalina output should be available even when verbose is not active.

## Capabilities

### New Capabilities

- `top-level-help`: `lp` with no args and `lp help` display all available namespaces, their commands, and one-line descriptions in a consistent, readable format
- `namespace-help`: `lp <namespace>` with no command (or `lp <namespace> help`) shows a help page scoped to that namespace listing its commands with descriptions and usage examples
- `per-command-help`: Every individual script (`worktree/add`, `worktree/start`, `bundle/cd`, etc.) accepts `--help` / `-h` and prints a self-contained usage page (description, synopsis, options, examples) then exits 0
- `standardized-output`: All scripts emit structured step progress lines (`[1/3] Doing X...`, `Done.`) and suppress raw output from underlying tools; a `--verbose` flag reveals the full output when needed

### Modified Capabilities

_(none — no existing specs)_

## Impact

- `lp` entrypoint must be updated to route namespace-only invocations and the `help` pseudo-command
- All scripts under `worktree/`, `bundle/`, `mysql/` need a `--help`/`-h` handler added
- No external dependencies added; pure bash changes
- No breaking changes to existing invocations
- Scripts that currently print raw git/ant/docker output will suppress it by default; `--verbose` flag added to affected commands
