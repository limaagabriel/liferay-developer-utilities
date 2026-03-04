## ADDED Requirements

### Requirement: lp with no arguments displays top-level help
When `lp` is invoked with no arguments, it SHALL print a formatted help page listing all available namespaces and their commands with one-line descriptions, then exit with code 1.

#### Scenario: No arguments
- **WHEN** user runs `lp` with no arguments
- **THEN** the output lists every namespace (worktree, bundle, mysql) and each of its commands with a one-line description
- **THEN** exit code is 1

### Requirement: lp help displays top-level help
`lp help` SHALL display the same top-level help page as `lp` with no arguments, but exit with code 0.

#### Scenario: lp help
- **WHEN** user runs `lp help`
- **THEN** the output is identical to `lp` with no arguments
- **THEN** exit code is 0

### Requirement: Top-level help output format
The top-level help output SHALL use a consistent, readable format with namespace headers, command names, and one-line descriptions aligned in columns.

#### Scenario: Output structure
- **WHEN** top-level help is displayed
- **THEN** output includes a usage line: `Usage: lp <namespace> <command> [args...]`
- **THEN** each namespace is shown as a section header
- **THEN** each command under the namespace is indented and shows its name and description
- **THEN** no raw debug output (e.g. `script: ...`) is printed

### Requirement: Top-level help stays in sync automatically
The top-level help SHALL derive its command list from `lib/help.sh` so it never drifts out of sync with available commands.

#### Scenario: Command added to registry
- **WHEN** a new command entry is added to `lib/help.sh`
- **THEN** it appears in `lp help` output without any other changes
