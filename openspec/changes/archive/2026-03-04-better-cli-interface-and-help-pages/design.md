## Context

The `lp` CLI is a collection of bash scripts organized under namespace directories (`worktree/`, `bundle/`, `mysql/`), loaded via a sourced `lp` entrypoint function. Scripts are invoked as subprocesses (except `cd` variants, which are sourced). There are currently no shared libraries — each script is standalone. The shell environment is bash/zsh on Linux/macOS with no external dependencies.

## Goals / Non-Goals

**Goals:**
- Introduce a shared `lib/` layer for output formatting and help metadata with no new external dependencies
- Make help discoverable at every level: `lp`, `lp <namespace>`, `lp <cmd> --help`
- Standardize step-progress output across all scripts and suppress raw subprocess noise by default
- Keep catalina/server log visible at all times regardless of verbosity setting

**Non-Goals:**
- Auto-generating man pages or markdown docs from scripts
- Changing the command routing structure of `lp` beyond the help dispatch additions
- Adding a `--verbose` mode to `lp bundle cd` / `lp worktree cd` (sourced scripts — flag already passes through unchanged)

## Decisions

### 1. Shared `lib/` directory for helpers

**Decision:** Introduce `lib/output.sh` and `lib/help.sh`, sourced by all scripts via `source "$(dirname "${BASH_SOURCE[0]}")/../lib/output.sh"`.

**Rationale:** Copy-pasting helper functions into every script would make them drift immediately. A tiny shared library keeps formatting consistent and is a single place to update. No new tools or interpreters needed — pure bash.

**Alternative considered:** Inline helpers per script — rejected because 10+ scripts would each need identical copies.

---

### 2. Central command registry for help metadata

**Decision:** `lib/help.sh` contains a single associative array (or structured function) mapping `namespace/command` → `[description, usage, options, examples]`. The `lp` entrypoint and namespace-help paths both read from this registry.

**Rationale:** The alternative is grepping `# Description:` comments from each script file at runtime. That works but couples help display to filesystem layout and comment formatting. A central registry is explicit, easy to test, and guaranteed in sync because it lives in one file.

**Alternative considered:** Per-script `--help` only (no top-level aggregation) — rejected because `lp help` and `lp <namespace>` discoverability are explicit goals.

---

### 3. Output helpers: `lp_step`, `lp_info`, `lp_success`, `lp_error`

**Decision:** `lib/output.sh` provides:
- `lp_step N TOTAL "message"` → prints `[N/TOTAL] message...`
- `lp_info "message"` → prints informational line
- `lp_success "message"` → prints success confirmation
- `lp_error "message"` → prints to stderr

Scripts replace ad-hoc `echo` calls with these functions.

**Rationale:** Uniform prefix format makes multi-step commands easy to follow. Centralising in a lib means changing the format only requires editing one file.

---

### 4. Verbose flag: `--verbose` / `-v` per script, output redirected to `/dev/null` by default

**Decision:** Each script that invokes noisy subprocesses (git, ant, docker) checks for a `VERBOSE` variable. When not set, stdout of those subprocesses is redirected to `/dev/null`. When `--verbose` / `-v` is passed, `VERBOSE=1` and full output is shown. `lp` passes `"${@:3}"` as before, so the flag reaches subcommands naturally.

**Rationale:** A logfile approach would require cleanup logic. `/dev/null` is simpler and sufficient — users who need output just add `--verbose`. Errors (stderr) are always shown regardless.

**Alternative considered:** A shared log file (`/tmp/lp.log`) — rejected as unnecessary complexity given the use case.

---

### 5. Catalina output always visible

**Decision:** In `worktree/start`, the `catalina` / server startup tail is always streamed to stdout regardless of `VERBOSE`, by explicitly not redirecting that specific `tail -f` / `catalina run` invocation.

**Rationale:** The server log is the primary output users watch during `lp worktree start`. Suppressing it behind `--verbose` would make the command useless.

---

### 6. Help routing in `lp` entrypoint

**Decision:** Extend the `lp` function dispatch with these cases (evaluated before the existing script lookup):

```
lp              → lp_top_level_help
lp help         → lp_top_level_help
lp <ns>         → lp_namespace_help <ns>
lp <ns> help    → lp_namespace_help <ns>
lp <ns> <cmd> --help | -h  → handled inside each script (early exit)
```

Namespace-only invocations currently fall through to the "unknown command" error. This replaces that path with a help display.

## Risks / Trade-offs

- **Sourced scripts (`worktree/cd`, `bundle/cd`)** can't use `exit` on `--help` — they must use `return`. These scripts already guard against direct execution; the `--help` path will use `return 0`.
- **Registry drift** — if a new script is added without updating `lib/help.sh`, it won't appear in help. → Mitigated by documenting the convention in a comment at the top of `lib/help.sh`.
- **Bash associative arrays require bash 4+** — macOS ships bash 3 by default. → Use a plain function-based dispatch (case statement) in `lib/help.sh` instead of `declare -A`, keeping compatibility with both bash 3 and zsh.

## Open Questions

- Should `lp_step` output go to stderr so it doesn't pollute command substitution? (Low priority — `lp` commands aren't typically used in `$(...)` pipelines, stdout is fine for now.)
    - Not sure, use the safest option.
- Should `--verbose` be documented as a universal flag in top-level help, or only on commands that support it?
    - Only on commands that support it.
