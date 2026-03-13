#!/bin/bash
# install.sh — Installer for the lp (Liferay Portal) CLI tools.

set -e

# --- Configuration ---
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/lp"
REPO_URL="https://github.com/limaagabriel/liferay-developer-utilities.git"

# --- Helpers ---
lp_info() { echo -e "\033[1;34m[lp]\033[0m $1"; }
lp_success() { echo -e "\033[1;32m[lp]\033[0m $1"; }
lp_error() { echo -e "\033[1;31m[lp]\033[0m $1" >&2; }

# --- Step 1: Clone or Copy ---
if [[ -d "$INSTALL_DIR" ]]; then
    lp_info "Installation directory '$INSTALL_DIR' already exists."
else
    lp_info "Creating installation directory at '$INSTALL_DIR'..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    
    # If we are running from within the correct git repo, we can clone locally
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && \
       git remote get-url origin 2>/dev/null | grep -q "liferay-developer-utilities"; then
        _REPO_ROOT=$(git rev-parse --show-toplevel)
        lp_info "Cloning from local repository at '$_REPO_ROOT'..."
        git clone "$_REPO_ROOT" "$INSTALL_DIR"
    else
        lp_info "Cloning from remote repository..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
fi

# --- Step 2: Configure Shell ---
SHELL_TYPE=$(basename "$SHELL")
PROFILE_FILE=""

case "$SHELL_TYPE" in
    zsh)  PROFILE_FILE="$HOME/.zshrc" ;;
    bash) PROFILE_FILE="$HOME/.bashrc" ;;
    *)    PROFILE_FILE="$HOME/.profile" ;;
esac

SOURCE_LINE="source \"$INSTALL_DIR/lp.sh\""

if grep -qs "$INSTALL_DIR/lp.sh" "$PROFILE_FILE"; then
    lp_info "Sourcing line already exists in $PROFILE_FILE."
else
    lp_info "Adding sourcing line to $PROFILE_FILE..."
    echo "" >> "$PROFILE_FILE"
    echo "# Liferay Portal (lp) CLI tools" >> "$PROFILE_FILE"
    echo "$SOURCE_LINE" >> "$PROFILE_FILE"
fi

# --- Step 3: Next Steps ---
echo ""
lp_success "Installation complete!"
echo "--------------------------------------------------------"
echo "1. Refresh your shell:"
echo "   source $PROFILE_FILE"
echo ""
echo "2. Initialize your configuration:"
echo "   lp config init"
echo "--------------------------------------------------------"
echo ""
