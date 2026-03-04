## Context

`config.sh` currently hard-codes three directory paths (`BASE_PROJECT_DIR`, `MAIN_REPO_DIR`, `BUNDLES_DIR`) inside the tracked file. `lp.sh` hard-codes `_LP_SCRIPTS_DIR="/home/me/dev/scripts"`. Any developer with a different folder layout must edit these tracked files, causing persistent diff noise and merge conflicts.

The fix is a two-part change: (1) move user-specific values into an untracked per-user config file, and (2) make `lp.sh` self-locate using `BASH_SOURCE`.

## Goals / Non-Goals

**Goals:**
- Allow each developer to store their own directory paths outside the repo
- Keep zero new runtime dependencies (pure bash, no external tools)
- Provide a first-run helper (`lp config init`) so setup is easy
- `lp config` shows the currently resolved configuration for debugging

**Non-Goals:**
- Supporting Windows or non-bash shells (fish, zsh config syntax) in the config file format
- Encrypting or securing config values
- Syncing config across machines
- Replacing any existing command behaviour beyond path resolution

## Decisions

### 1. Config file location: `~/.config/lp/config`

XDG Base Directory (`~/.config/<app>/config`) is chosen over a simple dotfile (`~/.lprc`) because it is the modern Linux/macOS convention, keeps the home directory clean, and is consistent with tools like `gh`, `aws`, and `helix`.

**Alternative considered:** `~/.lprc` — simpler path but pollutes `$HOME` and is non-standard.

### 2. Config file format: shell-sourceable `KEY=value`

The file is plain `KEY=value` pairs (no `export`, no quoting required for simple paths) sourced directly via `source "$_LP_USER_CONFIG"`. This requires no parser, fits naturally into the existing bash-only codebase, and is instantly editable by hand.

**Alternative considered:** INI/TOML — requires an external parser or a non-trivial bash parse loop, adding complexity with no real benefit for a small set of path variables.

### 3. `config.sh` sourcing order: user config → defaults

`config.sh` sources the user config file first (if it exists), then assigns default values only for variables that are still unset using `${VAR:=default}`. This means the user file can override any or all keys, and any missing key silently falls back to a sensible default.

```bash
_LP_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/lp/config"
[[ -f "$_LP_USER_CONFIG" ]] && source "$_LP_USER_CONFIG"

BASE_PROJECT_DIR="${BASE_PROJECT_DIR:=$HOME/dev/projects}"
MAIN_REPO_DIR="${MAIN_REPO_DIR:=$BASE_PROJECT_DIR/liferay-portal}"
BUNDLES_DIR="${BUNDLES_DIR:=$HOME/dev/bundles}"
```

**Alternative considered:** Require the user config file to always exist (error if missing) — too hostile for first-time setup; defaults are better UX.

### 4. `_LP_SCRIPTS_DIR` self-detection in `lp.sh`

Replace the hard-coded string with:

```bash
_LP_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

This resolves the directory of `lp.sh` itself at source time, regardless of where the repo is cloned.

**Alternative considered:** Require the user to set `_LP_SCRIPTS_DIR` in their shell rc — adds manual setup burden; the auto-detection is strictly better.

### 5. `lp config` command: new `config` namespace with `show` and `init` subcommands

`lp config` (no subcommand) prints the currently resolved values. `lp config init` interactively prompts for each key and writes `~/.config/lp/config`. The command lives in `commands/config/` alongside other namespaces, following the existing structure.

**Alternative considered:** A dedicated top-level flag (`lp --config`) — inconsistent with the existing namespace/command convention.

## Risks / Trade-offs

- **Sourcing arbitrary user file** → The user config is `source`d, so a malicious or broken file can execute code or break the shell session. Mitigation: document that this is a personal config file (not shared), keep it out of the repo, and add a comment header to the generated file warning against executable statements.
- **Silent fallback to defaults** → If a user's config file has a typo in a key name, the default is used silently. Mitigation: `lp config` (show subcommand) makes it easy to inspect resolved values and catch mismatches.
- **XDG_CONFIG_HOME not set on macOS** → `XDG_CONFIG_HOME` is often unset; the `${XDG_CONFIG_HOME:-$HOME/.config}` fallback handles this correctly on both Linux and macOS.

## Migration Plan

1. Update `lp.sh`: replace hard-coded `_LP_SCRIPTS_DIR` with `BASH_SOURCE` detection.
2. Update `config.sh`: add user-config sourcing + default assignments; remove hard-coded path lines.
3. Add `commands/config/show.sh` and `commands/config/init.sh`.
4. Register `config` namespace in `lp.sh` (same pattern as `worktree`, `bundle`, `mysql`).
5. Existing users: no action required — defaults match the current hard-coded values, so behaviour is unchanged unless they create a user config file.

Rollback: revert `lp.sh` and `config.sh` to the previous hard-coded values; no data is lost since `~/.config/lp/config` is additive.

## Open Questions

- Should `lp config init` overwrite an existing config file or refuse? (Proposed: prompt the user; default to no-overwrite.)
    - Yes, follow the proposed option.
- Should `MAIN_REPO_DIR` remain a derived default (`$BASE_PROJECT_DIR/liferay-portal`) or be independently configurable? (Proposed: keep derived; add to user config only if the user needs a different name.)
    - We could define the repository name as another configurable vairable. It should default to liferay-portal, but the user could replace it if wanted.
