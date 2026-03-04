## Why

The `lp` scripts currently hardcode all directory paths in `config.sh` and `lp.sh`, making them unusable out of the box for any developer whose folder structure differs from the original author's. There is no way to configure paths without editing tracked files, which would cause conflicts on every pull.

## What Changes

- Introduce a per-user config file at `~/.config/lp/config` (following XDG conventions, similar to AWS CLI's `~/.aws/config`) that stores user-specific directory paths
- `config.sh` reads from the user config file and falls back to sensible defaults; it no longer contains hardcoded paths checked into the repo
- `lp.sh` auto-detects `_LP_SCRIPTS_DIR` from its own location instead of being hardcoded to `/home/me/dev/scripts`
- Provide an `lp config` command to interactively generate or edit the user config file
- Document required setup in a README or inline help

## Capabilities

### New Capabilities

- `user-config-file`: A `~/.config/lp/config` file (shell-sourceable key=value format) that holds per-user directory settings. `config.sh` sources it on load and applies defaults for any missing keys.
- `config-command`: `lp config` command that prints current resolved configuration, and `lp config init` that interactively scaffolds `~/.config/lp/config` with prompted values.

### Modified Capabilities

_(none — no existing specs affected at the requirements level)_

## Impact

- `config.sh`: Remove hardcoded path assignments; replace with config-file sourcing + defaults
- `lp.sh`: Replace hardcoded `_LP_SCRIPTS_DIR` with `$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)`
- All scripts that source `config.sh` get per-user paths automatically — no per-script changes needed
- New file: `~/.config/lp/config` (created by user or via `lp config init`; not tracked in the repo)
- No breaking changes to any existing command invocations
