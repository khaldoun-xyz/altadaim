#!/usr/bin/env bash
# must be run as the original user (not sudo)
# because the keybindings are connected to the original user

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"

echo "List of existing shortcuts:"
gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings

SHORTCUT_NAME="flameshot"
echo "Setting $SHORTCUT_NAME shortcut"
SHORTCUT_PATH="${CUSTOM_PATH}${SHORTCUT_NAME}/"
COMMAND="/usr/bin/flameshot gui"
BINDING="<Control><Super>p"

existing=$(gsettings get "$SCHEMA" custom-keybindings)

if [[ "$existing" == "@as []" ]]; then
  new_list="['$SHORTCUT_PATH']"
elif [[ "$existing" != *"$SHORTCUT_PATH"* ]]; then
  new_list=$(echo "$existing" | sed "s/]$/, '$SHORTCUT_PATH']/")
else
  new_list="$existing"
fi

gsettings set "$SCHEMA" custom-keybindings "$new_list"
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" name "$SHORTCUT_NAME" || echo "Failed to set shortcut name $SHORTCUT_NAME."
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" command "$COMMAND" || echo "Failed to set shortcut command $COMMAND."
gsettings set "${SCHEMA}.custom-keybinding:$SHORTCUT_PATH" binding "$BINDING" || echo "Failed to set shortcut binding $BINDING."
gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
