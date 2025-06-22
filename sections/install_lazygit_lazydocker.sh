#!/usr/bin/env bash
ORIGINAL_USER="$SUDO_USER"
if [ -z "$ORIGINAL_USER" ]; then
  error_exit "Could not determine the original user who invoked sudo. Please ensure SUDO_USER is set."
fi
echo "Script invoked by user: $ORIGINAL_USER"

install_latest_github_release() {
  local repo="$1"                     # e.g., "jesseduffield/lazygit"
  local binary_name="$2"              # e.g., "lazygit"
  local install_path="/usr/local/bin" # Standard path for local binaries

  echo "Installing latest $binary_name from $repo"
  local latest_version
  # Fetch the latest release tag name
  latest_version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  if [ -z "$latest_version" ]; then
    error_exit "Could not determine latest version for $binary_name from $repo."
  fi

  local download_url="https://github.com/$repo/releases/latest/download/${binary_name}_${latest_version}_Linux_x86_64.tar.gz"
  local temp_tar_file="${binary_name}.tar.gz"
  local temp_dir="${binary_name}-temp"

  echo "Downloading $binary_name from $download_url"
  # Use sudo -u "$ORIGINAL_USER" to download to the user's home or a temp dir they own
  sudo -u "$ORIGINAL_USER" curl -fsSLo "/home/$ORIGINAL_USER/$temp_tar_file" "$download_url" || error_exit "Failed to download $binary_name."

  # Create temp dir as ORIGINAL_USER
  sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/$temp_dir" || error_exit "Failed to create temporary directory $temp_dir for user $ORIGINAL_USER."
  # Extract as ORIGINAL_USER
  sudo -u "$ORIGINAL_USER" tar xf "/home/$ORIGINAL_USER/$temp_tar_file" -C "/home/$ORIGINAL_USER/$temp_dir" || error_exit "Failed to extract $temp_tar_file for user $ORIGINAL_USER."

  # Move the extracted binary to the install path (this still needs sudo as it's /usr/local/bin)
  if [ -f "/home/$ORIGINAL_USER/$temp_dir/$binary_name" ]; then
    sudo mv "/home/$ORIGINAL_USER/$temp_dir/$binary_name" "$install_path/" || error_exit "Failed to move $binary_name to $install_path."
    sudo chmod +x "$install_path/$binary_name" # Make the binary executable
    echo "$binary_name installed successfully to $install_path."
  else
    error_exit "Expected binary '$binary_name' not found in extracted directory '/home/$ORIGINAL_USER/$temp_dir'."
  fi

  # Clean up temporary files, as ORIGINAL_USER
  sudo -u "$ORIGINAL_USER" rm -rf "/home/$ORIGINAL_USER/$temp_tar_file" "/home/$ORIGINAL_USER/$temp_dir" || echo "WARNING: Failed to clean up temporary files for $binary_name for user $ORIGINAL_USER."
}

main() {
  # These are installed to /usr/local/bin, which is system-wide, but the download process
  # needs to be done as the original user to access their home directory for temp files.
  install_latest_github_release "jesseduffield/lazygit" "lazygit"
  install_latest_github_release "jesseduffield/lazydocker" "lazydocker"
  echo "Creating empty config.yml for Lazygit under /home/$ORIGINAL_USER/.config/lazygit"
  sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/.config/lazygit" || echo "WARNING: Failed to create .config/lazygit directory."
  sudo -u "$ORIGINAL_USER" touch "/home/$ORIGINAL_USER/.config/lazygit/config.yml" || echo "WARNING: Failed to create empty config.yml for Lazygit."
  echo "✅ Lazygit & Lazydocker installed."
}

main "$@"
