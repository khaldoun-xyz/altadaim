#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Exit if any command in a pipeline fails.
set -o pipefail

# Define error handling
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "Setting up GNOME Extensions and YKS Timer..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
  error_exit "This script should not be run as root. Please run without sudo."
fi

# Install GNOME Extensions Manager and required tools
log "Installing GNOME Extensions Manager and required tools..."
if ! command -v gnome-extensions &>/dev/null; then
  sudo dnf install gnome-extensions-app gnome-shell-extension-common chrome-gnome-shell -y || \
    error_exit "Failed to install GNOME Extensions Manager and tools"
else
  log "GNOME Extensions Manager already installed."
fi

# Ensure the extensions directory exists
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXTENSIONS_DIR"

# Install gnome-shell-extension-installer if not present
INSTALLER_PATH="/usr/bin/gnome-shell-extension-installer"
if [ ! -f "$INSTALLER_PATH" ]; then
  log "Installing gnome-shell-extension-installer..."
  sudo wget -O "$INSTALLER_PATH" \
    https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer || \
    error_exit "Failed to download gnome-shell-extension-installer"
  sudo chmod +x "$INSTALLER_PATH" || error_exit "Failed to make installer executable"
fi

# Install YKS Timer extension
YKS_TIMER_UUID="yks-timer@yks.com"
YKS_TIMER_ID="5910"

log "Installing YKS Timer extension..."
if ! gnome-extensions list | grep -q "$YKS_TIMER_UUID"; then
  "$INSTALLER_PATH" "$YKS_TIMER_ID" --yes || error_exit "Failed to install YKS Timer extension"
  log "YKS Timer extension installed successfully."
else
  log "YKS Timer extension already installed."
fi

# Enable the extension
log "Enabling YKS Timer extension..."
gnome-extensions enable "$YKS_TIMER_UUID" || log "Note: Extension will be enabled after next login"

log "✅ YKS Timer extension setup completed."
log "Please follow these steps to complete the setup:"
log "1. Log out and log back in for the changes to take effect"
log "2. Press Super key (Windows key) and type 'Extensions'"
log "3. Verify that 'YKS Timer' is enabled in the list"
log "4. Click the settings gear icon to configure the timer"
log "5. The timer will appear in your top panel"
log ""
log "If you encounter any issues, you can manually install the extension from:"
log "https://extensions.gnome.org/extension/5910/yks-timer/"
