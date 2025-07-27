#!/usr/bin/env bash

# Define error_exit function if not already defined
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

echo "Installing Brave Browser on Fedora."

# Use Brave's official installation script
curl -fsS https://dl.brave.com/install.sh | sh || error_exit "Failed to install Brave Browser."

# Verify installation
if command -v brave-browser &>/dev/null; then
  echo "✅ Brave Browser installed successfully."
  echo "You can launch it from the application menu or by running 'brave-browser' in the terminal."
else
  error_exit "Brave Browser installation verification failed."
fi
