#!/usr/bin/env bash

# Define error_exit function if not already defined
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

echo "Adding Brave Browser repository and installing Brave on Fedora."

# Import Brave's signing key
echo "Importing Brave Browser signing key..."
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc || error_exit "Failed to import Brave signing key."

# Add Brave repository
echo "Adding Brave Browser repository..."
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo || error_exit "Failed to add Brave repository."

# Update package list and install Brave
echo "Updating package list..."
sudo dnf check-update -y || true  # check-update returns 100 if updates are available, which is normal

echo "Installing Brave Browser..."
sudo dnf install -y brave-browser || error_exit "Failed to install Brave Browser."

# Verify installation
if command -v brave-browser &>/dev/null; then
  echo "✅ Brave Browser installed successfully."
  echo "You can launch it from the application menu or by running 'brave-browser' in the terminal."
else
  error_exit "Brave Browser installation verification failed."
fi
