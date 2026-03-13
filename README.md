# lp — Liferay Portal CLI Tools

`lp` is a collection of Bash-based CLI tools designed to streamline Liferay Portal development workflows. It simplifies managing Git worktrees, server bundles, and local environment components like MySQL.

## Key Features

-   **Development Sessions**: The "bread and butter" of `lp`. It uses `tmux` to orchestrate a unified development environment (bundle logs, `lazygit`, and shell workstation) in a single terminal.
-   **Git Worktree Management**: Quickly add, switch, and remove branch-specific worktrees.
-   **Server Bundles**: Automated bundle management tied to your active worktree.
-   **MySQL Support**: Easily start and reset the `lportal` database via Docker Compose.
-   **Playwright Utilities**: Streamlined execution of portal tests.
-   **Fuzzy Search**: Rapidly find and navigate to modules using `lp portal cdm` (requires `fzf`).
-   **Tab Completion**: Seamless branch name auto-completion for all relevant commands.

## Quick Start (Automated Installation)

The easiest way to get started is to use the provided `install.sh` script:

```bash
# Clone and install
git clone https://github.com/your-username/lp.git ~/.local/share/lp
bash ~/.local/share/lp/install.sh

# Refresh your shell
source ~/.zshrc  # or ~/.bashrc

# Initialize configuration
lp config init
```

## Manual Installation

1.  Clone this repository to a directory of your choice (e.g., `~/.local/share/lp`).
2.  Source `lp.sh` in your shell profile (`~/.zshrc` or `~/.bashrc`):
    ```bash
    source ~/.local/share/lp/lp.sh
    ```
3.  Restart your terminal or source your profile.
4.  Run `lp config init` to set up your environment (paths, repository names, etc.).

## Core Commands

### Development Sessions
Orchestrate your workflow with `tmux`. These commands are the primary way to develop on Liferay Portal.
```bash
lp session start my-feature  # Start tmux with bundle, lazygit, and shell
lp session enter my-feature  # Re-attach to an existing session
lp session exit              # Detach from the session
lp session stop my-feature   # Kill the session and stop the portal
```

### Git Worktrees
Manage your portal development branches without constant `git checkout` switching.
```bash
lp worktree add my-feature    # Adds a new worktree and bundle
lp worktree cd my-feature     # Jump to the worktree directory
lp worktree build my-feature  # Build the portal bundle
lp worktree start my-feature  # Start the Liferay server
```

### Server Bundles
Manage Liferay server bundles independently.
```bash
lp bundle cd my-feature       # Jump to the tomcat/bin directory
lp bundle remove my-feature   # Delete a specific bundle
```

### Local Environment
Quickly manage your local development database and cleaning tasks.
```bash
lp mysql start             # Start MySQL container and initialize database
lp mysql reset             # Reset (drop/recreate) the lportal database
lp hypersonic clean master  # Clean the Hypersonic database in a bundle
```

### Git Utilities
```bash
lp git patch https://.../fix.patch  # Apply a remote patch to the current repo
```

### Navigation & Shortcuts
```bash
lp portal cdm     # Fuzzy search modules and jump to them (cd + fzf)
lp portal gw ...  # Run gradle tasks from any directory within a worktree
```

## Configuration

Your configuration is stored in `~/.config/lp/config`. You can view your current resolved configuration by running:

```bash
lp config
```

To re-run the interactive setup:
```bash
lp config init
```

## Shortcuts (Aliases)

If enabled during configuration (default: `yes`), `lp` provides several convenient aliases:
-   `cdm`: Short for `lp portal cdm`.
-   `gw`: Short for `lp portal gw`.
-   `lp_branch_vars`: Sets `WORKTREE_DIR` and `BUNDLE_DIR` for the current shell session.

## Compatibility

-   **Bash**: 3.2+
-   **Zsh**: Supported
-   **OS**: Linux, macOS (untested but should work)

---
*Developed for Liferay Portal Engineers.*
