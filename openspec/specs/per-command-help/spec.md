## ADDED Requirements

### Requirement: Every script accepts --help and -h
Every script under `worktree/`, `bundle/`, and `mysql/` SHALL accept `--help` and `-h` as the first argument and print a self-contained usage page, then exit 0 (or return 0 for sourced scripts).

#### Scenario: --help flag
- **WHEN** user runs `lp worktree add --help`
- **THEN** a usage page is printed covering description, synopsis, options, and at least one example
- **THEN** exit code is 0 and no side effects occur

#### Scenario: -h flag
- **WHEN** user runs `lp worktree add -h`
- **THEN** output is identical to `--help`
- **THEN** exit code is 0

### Requirement: Per-command help output format
Each command's help page SHALL include a description, a synopsis line, an options section (even if empty), and at least one usage example.

#### Scenario: Help page structure
- **WHEN** `--help` is shown for any command
- **THEN** output includes: a one-line description of what the command does, a `Usage:` synopsis, an `Options:` section listing all accepted flags, and an `Examples:` section with at least one invocation example

### Requirement: Sourced scripts handle --help without exiting the shell
Commands that must be sourced (`worktree/cd`, `bundle/cd`) SHALL detect `--help` / `-h` and use `return 0` instead of `exit 0` so the user's shell session is not terminated.

#### Scenario: --help on sourced script
- **WHEN** user runs `lp worktree cd --help`
- **THEN** help text is printed
- **THEN** the current shell session continues unaffected
- **THEN** working directory does not change

### Requirement: --help does not execute any side effects
When `--help` or `-h` is passed to any script, the script SHALL perform no filesystem changes, network calls, or subprocess invocations beyond printing the help text.

#### Scenario: No side effects
- **WHEN** user runs `lp worktree build --help`
- **THEN** no worktree is rebuilt, no confirmation prompt appears, and no files are modified
