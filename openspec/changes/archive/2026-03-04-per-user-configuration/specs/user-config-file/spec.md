## ADDED Requirements

### Requirement: User config file location
The tool SHALL look for a per-user configuration file at `${XDG_CONFIG_HOME:-$HOME/.config}/lp/config` and source it on startup if it exists. If the file does not exist, the tool SHALL continue with default values without error.

#### Scenario: Config file present
- **WHEN** `~/.config/lp/config` exists and contains valid key=value assignments
- **THEN** `config.sh` sources the file and the defined variables override the defaults

#### Scenario: Config file absent
- **WHEN** no file exists at the XDG config path
- **THEN** `config.sh` loads successfully using built-in default values with no error or warning

#### Scenario: XDG_CONFIG_HOME overridden
- **WHEN** the user has set `XDG_CONFIG_HOME=/custom/path` in their environment
- **THEN** the tool looks for the config file at `/custom/path/lp/config`

### Requirement: Shell-sourceable key=value format
The user config file SHALL use plain `KEY=value` pairs that are valid bash assignments. The file SHALL be sourced directly; no external parser is required.

#### Scenario: All keys present
- **WHEN** the config file defines `BASE_PROJECT_DIR`, `MAIN_REPO_DIR`, and `BUNDLES_DIR`
- **THEN** all three variables are set to the user-supplied values after `config.sh` is sourced

#### Scenario: Partial keys present
- **WHEN** the config file defines only a subset of variables
- **THEN** the script should inform the user which variables are missing.

### Requirement: Config shall be defined before running the commands
`config.sh` SHALL exit and block further commands if no configuration is found.

#### Scenario: No user config, exit
- **WHEN** no user config file is present
- **THEN** the commands shall exit and inform the user that the config init must be executed.

### Requirement: `lp.sh` self-locates its scripts directory
`lp.sh` SHALL determine `_LP_SCRIPTS_DIR` at source time from `BASH_SOURCE[0]` rather than a hard-coded path, so it works regardless of where the repository is cloned.

#### Scenario: Repo cloned to a non-default path
- **WHEN** `lp.sh` is sourced from `/opt/scripts/lp.sh`
- **THEN** `_LP_SCRIPTS_DIR` is set to `/opt/scripts` and all subsequent `source` calls resolve correctly
