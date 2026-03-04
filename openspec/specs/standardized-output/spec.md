## ADDED Requirements

### Requirement: Scripts print structured step progress
Every multi-step script SHALL print progress using the format `[N/TOTAL] <description>...` before each major step, using helpers from `lib/output.sh`.

#### Scenario: Step progress during execution
- **WHEN** user runs `lp worktree add <branch>`
- **THEN** each major step is announced as e.g. `[1/2] Creating worktree...`, `[2/2] Done.`
- **THEN** no raw git/subprocess output appears unless `--verbose` is active

### Requirement: Subprocess output suppressed by default
Scripts that invoke noisy subprocesses (git, ant, docker) SHALL redirect their stdout to `/dev/null` by default, while always preserving stderr output.

#### Scenario: Default quiet mode
- **WHEN** user runs `lp worktree rebuild <branch>` without `--verbose`
- **THEN** ant and git stdout is not shown in the terminal
- **THEN** any errors from those subprocesses are still printed to the terminal

#### Scenario: Errors always visible
- **WHEN** a subprocess fails with an error message on stderr
- **THEN** the error is always shown regardless of `--verbose` setting

### Requirement: --verbose flag reveals full subprocess output
Scripts that suppress subprocess output SHALL accept a `--verbose` / `-v` flag that disables suppression and shows all output.

#### Scenario: Verbose mode
- **WHEN** user runs `lp worktree rebuild <branch> --verbose`
- **THEN** full stdout from ant, git, and other subprocesses is shown in the terminal
- **THEN** step-progress lines are still printed alongside the raw output

### Requirement: Catalina output always visible
The server startup output from `lp worktree start` (catalina / server log) SHALL always be streamed to stdout regardless of the `--verbose` flag.

#### Scenario: Server log always shown
- **WHEN** user runs `lp worktree start <branch>` without `--verbose`
- **THEN** catalina / server log output streams to the terminal
- **THEN** other build or setup subprocess output (ant, git) remains suppressed

#### Scenario: Server log shown in verbose mode too
- **WHEN** user runs `lp worktree start <branch> --verbose`
- **THEN** catalina / server log output continues to stream to the terminal

### Requirement: Output helpers provided by lib/output.sh
A shared `lib/output.sh` SHALL provide at minimum: `lp_step N TOTAL message`, `lp_info message`, `lp_success message`, and `lp_error message`. All scripts SHALL use these helpers instead of raw `echo` for user-facing messages.

#### Scenario: Consistent formatting
- **WHEN** any `lp` script produces output
- **THEN** progress, info, success, and error messages follow a consistent format defined in `lib/output.sh`
- **THEN** no bare `echo script: ...` debug lines appear
