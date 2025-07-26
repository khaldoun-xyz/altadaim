#!/usr/bin/env bash

# Define error_exit function if not already defined
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

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
  
  echo "Opening GitHub SSH key settings page in browser..."
  
  # Try different browsers in order of preference for Fedora
  if command -v brave-browser &>/dev/null; then
    sudo -u "$ORIGINAL_USER" brave-browser "https://github.com/settings/ssh/new" &
    echo "Opened in Brave Browser."
  elif command -v firefox &>/dev/null; then
    sudo -u "$ORIGINAL_USER" firefox "https://github.com/settings/ssh/new" &
    echo "Opened in Firefox."
  elif command -v chromium &>/dev/null; then
    sudo -u "$ORIGINAL_USER" chromium "https://github.com/settings/ssh/new" &
    echo "Opened in Chromium."
  elif command -v google-chrome &>/dev/null; then
    sudo -u "$ORIGINAL_USER" google-chrome "https://github.com/settings/ssh/new" &
    echo "Opened in Google Chrome."
  else
    echo ">>>>> WARNING <<<<<: No supported browser found. Please open manually: https://github.com/settings/ssh/new"
  fi
  
  echo "Testing SSH connection to GitHub (you may see a one-time prompt to confirm the host fingerprint)..."
  sudo -u "$ORIGINAL_USER" ssh -T git@github.com || echo "SSH test to GitHub failed. This may be expected if the key hasn't been added yet."
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
  # Ensure git and openssh are installed
  if ! command -v git &>/dev/null; then
    echo "Git not found. Installing via DNF..."
    sudo dnf install -y git || error_exit "Failed to install git"
  fi
  
  if ! command -v ssh-keygen &>/dev/null; then
    echo "OpenSSH not found. Installing via DNF..."
    sudo dnf install -y openssh-clients || error_exit "Failed to install openssh-clients"
  fi
  
  prompt_git_identity
  sudo -u "$ORIGINAL_USER" git config --global credential.helper store || error_exit "Failed to configure Git credential helper for user $ORIGINAL_USER."
  set_up_git_ssh
  echo "✅ Git ssh is set up."
}

main "$@"
