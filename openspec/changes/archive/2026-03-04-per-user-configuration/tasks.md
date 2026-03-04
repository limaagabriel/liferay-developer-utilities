## 1. Update `lp.sh`

- [x] 1.1 Replace the hard-coded `_LP_SCRIPTS_DIR` assignment with `_LP_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- [x] 1.2 Register the `config` namespace in the namespace list (same pattern as `worktree`, `bundle`, `mysql`)

## 2. Update `config.sh`

- [x] 2.1 Add `_LP_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"` near the top of the file
- [x] 2.2 Source the user config file when it exists: `[[ -f "$_LP_USER_CONFIG" ]] && source "$_LP_USER_CONFIG"`
- [x] 2.3 Exit with a clear error message when no user config file is found, instructing the user to run `lp config init`
- [x] 2.4 Add `MAIN_REPO_NAME` as a configurable variable (default: `liferay-portal`)
- [x] 2.5 Replace hardcoded path assignments with configurable defaults using `${VAR:=default}` for `BASE_PROJECT_DIR`, `MAIN_REPO_NAME`, `MAIN_REPO_DIR`, and `BUNDLES_DIR`
- [x] 2.6 After sourcing the user config, warn for any expected variable that is still unset

## 3. Create `commands/config/show.sh`

- [x] 3.1 Create `commands/config/show.sh` that prints the path to the active user config file (or a "not found" notice)
- [x] 3.2 Print the resolved values of `BASE_PROJECT_DIR`, `MAIN_REPO_NAME`, `MAIN_REPO_DIR`, and `BUNDLES_DIR`

## 4. Create `commands/config/init.sh`

- [x] 4.1 Create `commands/config/init.sh` with interactive prompts for each configurable variable, showing the default as a hint
- [x] 4.2 If no value is entered at a prompt, use the displayed default
- [x] 4.3 Check if the config file already exists; if so, warn the user and prompt for confirmation before overwriting; abort if declined
- [x] 4.4 Create `~/.config/lp/` directory if it does not exist
- [x] 4.5 Write the `~/.config/lp/config` file with a comment header warning against adding executable statements
- [x] 4.6 Print a success message with the path to the written file

## 5. Update help pages

- [x] 5.1 Add `config` to the namespace list in the top-level help output in `lib/help.sh` with a one-line description
- [x] 5.2 Add per-command help metadata to `commands/config/show.sh` and `commands/config/init.sh` following the existing convention
