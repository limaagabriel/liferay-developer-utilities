## 1. Shared Library Setup

- [x] 1.1 Create `lib/output.sh` with `lp_step N TOTAL message`, `lp_info`, `lp_success`, and `lp_error` helpers
- [x] 1.2 Create `lib/help.sh` with a function-based command registry (bash 3 / zsh compatible — no `declare -A`)
- [x] 1.3 Populate `lib/help.sh` registry with description, usage, options, and examples for every command across all namespaces (worktree, bundle, mysql)

## 2. Help Display Functions

- [x] 2.1 Implement `lp_top_level_help` in `lib/help.sh`: usage line, namespace section headers, commands aligned in columns
- [x] 2.2 Implement `lp_namespace_help <ns>` in `lib/help.sh`: namespace header, each command with synopsis, description, and at least one example

## 3. Entrypoint Help Routing

- [x] 3.1 Source `lib/help.sh` in the `lp` entrypoint
- [x] 3.2 Handle `lp` with no args: call `lp_top_level_help`, exit 1
- [x] 3.3 Handle `lp help`: call `lp_top_level_help`, exit 0
- [x] 3.4 Handle `lp <ns>` with no command: call `lp_namespace_help <ns>`, exit 1
- [x] 3.5 Handle `lp <ns> help`: call `lp_namespace_help <ns>`, exit 0
- [x] 3.6 Handle unknown namespace: print `lp: unknown namespace '<ns>'` to stderr, exit 1

## 4. Per-Command Help

- [x] 4.1 Add `--help`/`-h` to `worktree/add`, `worktree/list`, `worktree/code` (exit 0)
- [x] 4.2 Add `--help`/`-h` to `worktree/cd` using `return 0` (sourced script — must not exit the shell)
- [x] 4.3 Add `--help`/`-h` to `worktree/clean` and `worktree/remove` (exit 0)
- [x] 4.4 Add `--help`/`-h` to `worktree/rebuild` and `worktree/start` (exit 0)
- [x] 4.5 Add `--help`/`-h` to `bundle/cd` using `return 0` (sourced script) and to `bundle/remove` (exit 0)
- [x] 4.6 Add `--help`/`-h` to `mysql/reset` and `mysql/start` (exit 0)

## 5. Standardized Output

- [x] 5.1 Source `lib/output.sh` in all scripts; replace bare `echo` user-facing messages with `lp_info`, `lp_success`, and `lp_error`
- [x] 5.2 Add step-progress calls (`lp_step`) to `worktree/add` and `worktree/clean`
- [x] 5.3 Add step-progress calls to `worktree/rebuild` and `worktree/remove`
- [x] 5.4 Add step-progress calls to `worktree/start`
- [x] 5.5 Add step-progress calls to `bundle/remove`, `mysql/reset`, and `mysql/start`

## 6. Verbose Mode and Subprocess Suppression

- [x] 6.1 Add `--verbose`/`-v` flag parsing and redirect subprocess stdout to `/dev/null` by default in `worktree/add`
- [x] 6.2 Add `--verbose`/`-v` and subprocess suppression to `worktree/clean` and `worktree/remove`
- [x] 6.3 Add `--verbose`/`-v` and subprocess suppression to `worktree/rebuild`
- [x] 6.4 Add `--verbose`/`-v` to `worktree/start`; ensure catalina/server log is always streamed regardless of flag
- [x] 6.5 Add `--verbose`/`-v` and subprocess suppression to `bundle/remove`, `mysql/reset`, and `mysql/start`
