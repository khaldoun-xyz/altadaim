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
COMMAND="/usr/bin/flameshot gui"
BINDING="<Control><Super>p"

echo "Configuring Flameshot screenshot shortcut: $BINDING"

# Verify flameshot is installed in the expected location
if [ ! -f "/usr/bin/flameshot" ]; then
  # Try to find flameshot in other common locations
  if command -v flameshot &>/dev/null; then
    COMMAND=$(which flameshot)
    COMMAND="$COMMAND gui"
    echo "Found flameshot at: $COMMAND"
  else
    error_exit "flameshot binary not found. Please install flameshot first."
  fi
fi

echo "List of existing shortcuts:"
existing=$(gsettings get "$SCHEMA" custom-keybindings 2>/dev/null || echo "[]")
echo "$existing"

# Safely remove brackets using shell expansion
cleaned="${existing#[}"
cleaned="${cleaned%]}"

# Check if shortcut already exists
if [[ "$existing" == "[]" ]] || [[ "$existing" == "@as []" ]]; then
  new_list="['$SHORTCUT_PATH']"
elif [[ "$existing" != *"$SHORTCUT_PATH"* ]]; then
  # Remove the @as prefix and brackets, then rebuild
  cleaned="${existing#*[}"
  cleaned="${cleaned%]}"
  if [[ -z "$cleaned" ]] || [[ "$cleaned" == " " ]]; then
    new_list="['$SHORTCUT_PATH']"
  else
    new_list="[$cleaned, '$SHORTCUT_PATH']"
  fi
else
  new_list="$existing"
  echo "Shortcut already exists, updating configuration..."
fi

echo "Setting $SHORTCUT_NAME shortcut"
echo "New list will be: $new_list"

# Set the custom keybindings list with proper array syntax
gsettings set "$SCHEMA" custom-keybindings "$new_list" || {
  echo "Failed with quoted syntax, trying alternative..."
  # Try alternative syntax without outer quotes
  gsettings set "$SCHEMA" custom-keybindings "['$SHORTCUT_PATH']" || {
    echo "Trying with explicit array type..."
    # Force the array type explicitly
    gsettings set "$SCHEMA" custom-keybindings "['$SHORTCUT_PATH']" || error_exit "Failed to set custom keybindings list"
  }
}

# Set individual shortcut properties
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" name "$SHORTCUT_NAME" || error_exit "Failed to set shortcut name"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" command "$COMMAND" || error_exit "Failed to set shortcut command"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" binding "$BINDING" || error_exit "Failed to set shortcut binding"

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

# Test if flameshot is working (optional)
echo "Testing Flameshot installation..."
if timeout 2s flameshot --version &>/dev/null; then
  echo "✅ Flameshot is working correctly."
else
  echo "⚠️  Warning: Flameshot test failed or timed out. The shortcut may still work."
fi
