#!/usr/bin/env bash
# must be run as the original user (not sudo)

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"

SHORTCUT_NAME="flameshot"
SHORTCUT_PATH="${CUSTOM_PATH}${SHORTCUT_NAME}/"
COMMAND="/usr/bin/flameshot gui"
BINDING="<Control><Super>p"

echo "--- Setting custom keyboard shortcuts ---"
echo "List of existing shortcuts:"
existing=$(gsettings get "$SCHEMA" custom-keybindings)
echo "$existing"

# Safely remove brackets using shell expansion
cleaned="${existing#[}"
cleaned="${cleaned%]}"

# Check if shortcut already exists
if [[ "$existing" == "[]" ]]; then
  new_list="['$SHORTCUT_PATH']"
elif [[ "$existing" != *"$SHORTCUT_PATH"* ]]; then
  if [[ -z "$cleaned" ]]; then
    new_list="['$SHORTCUT_PATH']"
  else
    new_list="[$cleaned, '$SHORTCUT_PATH']"
  fi
else
  new_list="$existing"
fi

echo "Setting $SHORTCUT_NAME shortcut"
gsettings set "$SCHEMA" custom-keybindings "$new_list"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" name "$SHORTCUT_NAME" || echo "❌ Failed to set shortcut name"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" command "$COMMAND" || echo "❌ Failed to set shortcut command"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" binding "$BINDING" || echo "❌ Failed to set shortcut binding"

# Show result
gsettings get "$SCHEMA" custom-keybindings
echo "✅ Custom shortcuts set up."
