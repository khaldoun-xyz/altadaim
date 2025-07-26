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

# Add Brave repository by creating the repo file manually
echo "Adding Brave Browser repository..."
sudo tee /etc/yum.repos.d/brave-browser.repo > /dev/null <<EOF
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF

if [ $? -eq 0 ]; then
  echo "Brave repository file created successfully."
else
  error_exit "Failed to create Brave repository file."
fi

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
