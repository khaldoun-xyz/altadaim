#!/usr/bin/env bash
echo "Adding Brave Browser repository and installing Brave."
# Ensure keyring directory exists
sudo mkdir -p /usr/share/keyrings/ || log "WARNING: Failed to create /usr/share/keyrings/ directory."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg || error_exit "Failed to download Brave keyring."
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list || error_exit "Failed to add Brave repository."
sudo apt update -y || error_exit "APT update after Brave repo addition failed."
sudo apt install -y brave-browser || error_exit "Failed to install Brave Browser."
echo "✅ Brave Browser installed."
