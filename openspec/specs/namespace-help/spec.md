## ADDED Requirements

### Requirement: lp with namespace only displays namespace help
When `lp` is invoked with a valid namespace and no command, it SHALL print a help page scoped to that namespace listing its commands with descriptions and usage examples, then exit with code 1.

#### Scenario: Namespace only
- **WHEN** user runs `lp worktree` (or any valid namespace) with no command
- **THEN** the output lists all commands under that namespace with descriptions and usage examples
- **THEN** exit code is 1

### Requirement: lp namespace help displays namespace help
`lp <namespace> help` SHALL display the same namespace-scoped help page as `lp <namespace>` alone, but exit with code 0.

#### Scenario: Namespace help subcommand
- **WHEN** user runs `lp worktree help`
- **THEN** the output is identical to `lp worktree` with no command
- **THEN** exit code is 0

### Requirement: Namespace help output format
The namespace help output SHALL include a header identifying the namespace, a list of its commands with one-line descriptions, and a usage example for each command.

#### Scenario: Output structure
- **WHEN** namespace help is displayed for `worktree`
- **THEN** output includes a header such as `lp worktree — <description>`
- **THEN** each command is listed with its synopsis and a one-line description
- **THEN** at least one usage example per command is shown

### Requirement: Unknown namespace shows error
When `lp` is invoked with a namespace that does not exist, it SHALL print an error message and exit with code 1.

#### Scenario: Invalid namespace
- **WHEN** user runs `lp unknownns`
- **THEN** stderr receives a message: `lp: unknown namespace 'unknownns'`
- **THEN** exit code is 1
