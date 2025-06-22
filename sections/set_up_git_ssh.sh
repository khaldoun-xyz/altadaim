#!/usr/bin/env bash
ORIGINAL_USER="$SUDO_USER"
if [ -z "$ORIGINAL_USER" ]; then
  error_exit "Could not determine the original user who invoked sudo. Please ensure SUDO_USER is set."
fi
echo "Script invoked by user: $ORIGINAL_USER"

set_up_git_ssh() {
  local ssh_dir="/home/$ORIGINAL_USER/.ssh"
  local ssh_key="$ssh_dir/id_ed25519"
  echo "Setting up Git SSH for user $ORIGINAL_USER."
  if [ -f "$ssh_key" ]; then
    echo "SSH key already exists for $ORIGINAL_USER at $ssh_key. Skipping key generation."
  else
    echo "Generating a new SSH key for $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" mkdir -p "$ssh_dir"
    sudo -u "$ORIGINAL_USER" ssh-keygen -t ed25519 -C "$ORIGINAL_USER@$(hostname)" -f "$ssh_key" -N "" || error_exit "Failed to generate SSH key for $ORIGINAL_USER."
    echo "SSH key generated successfully for $ORIGINAL_USER."
  fi
  # Ensure proper permissions
  sudo chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$ssh_dir"
  sudo chmod 700 "$ssh_dir"
  sudo chmod 600 "$ssh_key"
  sudo chmod 644 "$ssh_key.pub"
  echo ">>>>>>>> Here is the public SSH key for $ORIGINAL_USER: <<<<<<<<"
  sudo -u "$ORIGINAL_USER" cat "$ssh_key.pub"
  echo ">>>>>>>> You should now add this key to your Git hosting service (e.g., GitHub/GitLab). <<<<<<<<"
  echo "Opening GitHub SSH key settings page in Brave Browser..."
  sudo -u "$ORIGINAL_USER" brave-browser "https://github.com/settings/ssh/new" || echo ">>>>> WARNING <<<<<: Could not open GitHub SSH key page. Please open it manually: https://github.com/settings/ssh/new"
  echo "Testing SSH connection to GitHub (you may see a one-time prompt to confirm the host fingerprint)..."
  sudo -u "$ORIGINAL_USER" ssh -T git@github.com || echo "SSH test to GitHub failed. This may be expected if the key hasn’t been added yet."
}

main() {
  set_up_git_ssh
  echo "✅ Git ssh is set up."
}

main "$@"
