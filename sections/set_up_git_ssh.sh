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

prompt_git_identity() {
  echo ">>>>>>>> Please enter your Git user name: <<<<<<<<<"
  read -r git_name

  echo ">>>>>>>> Please enter your Git user email: <<<<<<<<<"
  read -r git_email

  # Validate input is not empty
  if [[ -z "$git_name" || -z "$git_email" ]]; then
    echo "Name and email cannot be empty. Please run the script again."
    exit 1
  fi

  sudo -u "$ORIGINAL_USER" git config --global user.name "$git_name"
  sudo -u "$ORIGINAL_USER" git config --global user.email "$git_email"

  echo "Git user.name and user.email configured for $ORIGINAL_USER."
}

main() {
  prompt_git_identity
  sudo -u "$ORIGINAL_USER" git config --global credential.helper store || error_exit "Failed to configure Git credential helper for user $ORIGINAL_USER."
  set_up_git_ssh

  echo "✅ Git ssh is set up."
}

main "$@"
