## ADDED Requirements

### Requirement: `lp config` shows resolved configuration
Running `lp config` with no subcommand SHALL print the currently resolved values of all configurable path variables to stdout, so the user can verify which paths are in effect.

#### Scenario: All variables resolved
- **WHEN** the user runs `lp config`
- **THEN** the command prints the resolved values of `BASE_PROJECT_DIR`, `MAIN_REPO_DIR`, and `BUNDLES_DIR`, one per line

#### Scenario: Source of each value visible
- **WHEN** the user runs `lp config`
- **THEN** the output indicates the path to the active user config file, or states that no user config file was found and defaults are in use

### Requirement: `lp config init` scaffolds the user config file
Running `lp config init` SHALL interactively prompt the user for each configurable path and write the results to `~/.config/lp/config`, creating parent directories as needed.

#### Scenario: No existing config file
- **WHEN** the user runs `lp config init` and no config file exists
- **THEN** the command prompts for each path (showing the current default as a hint), creates the directory `~/.config/lp/` if absent, and writes the config file with the supplied values

#### Scenario: Config file already exists
- **WHEN** the user runs `lp config init` and a config file already exists
- **THEN** the command warns the user that a config file already exists and asks for confirmation before overwriting; if the user declines, the file is left unchanged

#### Scenario: User accepts default during prompt
- **WHEN** the user presses Enter without typing a value during `lp config init`
- **THEN** the default value shown in the prompt is written to the config file for that key

### Requirement: `lp config` namespace appears in help
The `config` namespace SHALL be listed in `lp help` output and `lp config help` SHALL describe the available subcommands.

#### Scenario: Top-level help includes config
- **WHEN** the user runs `lp help`
- **THEN** `config` appears as an available namespace with a one-line description

#### Scenario: Namespace help lists subcommands
- **WHEN** the user runs `lp config help`
- **THEN** the output lists `init` and the default (show) behaviour with brief descriptions
