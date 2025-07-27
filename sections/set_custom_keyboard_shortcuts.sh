#!/usr/bin/env bash

# Exit on errors, unset vars, or failed pipes
set -euo pipefail

# Define error_exit function if not already defined
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

# Must be run as the original user (not sudo)
echo "--- Setting custom keyboard shortcuts ---"

# Check if GNOME is running
if [ -z "${XDG_CURRENT_DESKTOP:-}" ] || [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
  echo "WARNING: This script is designed for GNOME desktop environment."
  echo "Current desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
fi

# Check if required tools are available
if ! command -v gsettings &>/dev/null; then
  echo "gsettings not found. Installing via DNF..."
  sudo dnf install -y glib2 || error_exit "Failed to install glib2"
fi

if ! command -v flameshot &>/dev/null; then
  echo "flameshot not found. Installing via DNF..."
  sudo dnf install -y flameshot || error_exit "Failed to install flameshot"
fi

# GNOME settings configuration
SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"
SHORTCUT_NAME="flameshot"
SHORTCUT_PATH="${CUSTOM_PATH}${SHORTCUT_NAME}/"

# Use simple direct command (works better than complex wrappers)
# Create a wrapper script since direct commands don't work reliably
WRAPPER_SCRIPT="/usr/local/bin/flameshot-shortcut"
COMMAND="$WRAPPER_SCRIPT"
BINDING="<Control><Super>p"

echo "Configuring Flameshot screenshot shortcut: $BINDING"
echo "Creating wrapper script at: $WRAPPER_SCRIPT"

# Create the wrapper script that actually works
sudo tee "$WRAPPER_SCRIPT" > /dev/null << 'EOF'
#!/bin/bash
flameshot gui
EOF

sudo chmod +x "$WRAPPER_SCRIPT"
echo "Wrapper script created and made executable."

# Verify flameshot is installed
if ! command -v flameshot &>/dev/null; then
  error_exit "flameshot binary not found. Please install flameshot first."
fi

# Always clear and recreate the shortcut
echo "Clearing existing shortcuts and creating fresh..."
gsettings set "$SCHEMA" custom-keybindings "[]"
new_list="['$SHORTCUT_PATH']"

echo "Setting $SHORTCUT_NAME shortcut"
echo "New list will be: $new_list"

# Set the custom keybindings list
gsettings set "$SCHEMA" custom-keybindings "$new_list" || error_exit "Failed to set custom keybindings list"

# Set individual shortcut properties
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" name "$SHORTCUT_NAME" || error_exit "Failed to set shortcut name"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" command "$COMMAND" || error_exit "Failed to set shortcut command"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" binding "$BINDING" || error_exit "Failed to set shortcut binding"

# Ensure F11 fullscreen toggle is properly set for terminals
echo "Setting F11 as fullscreen toggle..."
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['F11']" || echo "WARNING: Failed to set F11 fullscreen binding"

# Force GNOME to refresh the shortcuts
echo "Refreshing GNOME settings..."
gsettings get "$SCHEMA" custom-keybindings > /dev/null

# Test flameshot to initialize it properly
echo "Initializing flameshot..."
timeout 2s flameshot gui &>/dev/null || true

# Verify the configuration
echo "Verifying shortcut configuration..."
echo "Name: $(gsettings get "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" name 2>/dev/null || echo 'Failed to read')"
echo "Command: $(gsettings get "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" command 2>/dev/null || echo 'Failed to read')"
echo "Binding: $(gsettings get "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" binding 2>/dev/null || echo 'Failed to read')"

# Show final result
echo "Final custom keybindings list:"
gsettings get "$SCHEMA" custom-keybindings

echo "✅ Custom shortcuts set up successfully."
echo "You can now use Ctrl+Super+P to take screenshots with Flameshot."
echo "✅ F11 is now set to toggle fullscreen in terminals and applications."

# Test if flameshot is working (optional)
echo "Testing Flameshot installation..."
if timeout 2s flameshot --version &>/dev/null; then
  echo "✅ Flameshot is working correctly."
else
  echo "⚠️  Warning: Flameshot test failed or timed out. The shortcut may still work."
fi
