#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Exit if any command in a pipeline fails.
set -o pipefail

LOG_FILE="$HOME/fedora_setup_$(date +%Y%m%d_%H%M%S).log"
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
  log "ERROR: $1"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  error_exit "This script must be run with sudo or as root. Please run 'sudo bash ./install_altadaim.sh'"
fi

ORIGINAL_USER="$SUDO_USER"
if [ -z "$ORIGINAL_USER" ]; then
  error_exit "Could not determine the original user who invoked sudo. Please ensure SUDO_USER is set."
fi
log "Script invoked by user: $ORIGINAL_USER"

TARGET_DIR="/home/$ORIGINAL_USER/altadaim"
cleanup() {
  log "Cleaning up: removing $TARGET_DIR"
  rm -rf "$TARGET_DIR" || log "WARNING: Failed to remove $TARGET_DIR"
}
trap cleanup EXIT

# Detect Fedora version instead of Ubuntu
if [ -f /etc/fedora-release ]; then
  FEDORA_VERSION=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
  log "Detected Fedora Version: $FEDORA_VERSION"
else
  error_exit "This script is designed for Fedora, but /etc/fedora-release was not found."
fi

main() {
  log "Starting Altadaim's installer script (Fedora version)."
  log "This script will install various development tools and configure your system."

  log "--- Get necessary scripts ---"
  REPO_URL="https://github.com/khaldoun-xyz/altadaim"
  if [ ! -d "$TARGET_DIR" ]; then
    log "Cloning Altadaim setup scripts from GitHub..."
    sudo -u "$ORIGINAL_USER" git clone "$REPO_URL" "$TARGET_DIR" || error_exit "Failed to clone Altadaim setup repository."
  else
    log "Setup directory already exists. Pulling latest changes..."
    sudo -u "$ORIGINAL_USER" git -C "$TARGET_DIR" pull || log "WARNING: Could not update existing setup repo."
  fi
  cd "$TARGET_DIR"

  log "--- System Update and Upgrade ---"
  log "Updating and upgrading system packages. This may take some time."
  # Use DNF instead of APT for Fedora
  sudo dnf check-update -y || true  # check-update returns 100 if updates are available, which is normal
  sudo dnf upgrade -y || error_exit "DNF upgrade failed."
  log "✅ System packages updated and upgraded."

  log "--- Installing packages ---"
  # You'll need to create Fedora-specific package installation scripts
  # or modify the existing ones to use dnf instead of apt
  if [ -f ./sections/install_fedora_packages.sh ]; then
    bash ./sections/install_fedora_packages.sh || error_exit "install_fedora_packages.sh failed"
  else
    log "WARNING: Fedora-specific package installation script not found. Skipping package installation."
    log "You may need to manually install required packages or create a Fedora-compatible script."
  fi

  log "--- Installing & configuring Neovim & LazyVim (includes Node.js) ---"
  sudo -u "$ORIGINAL_USER" bash ./sections/install_neovim_lazyvim.sh || error_exit "install_neovim_lazyvim.sh failed"

  log "--- Installing Lazygit and Lazydocker ---"
  bash ./sections/install_lazygit_lazydocker.sh || error_exit "install_lazygit_lazydocker.sh failed"

  log "--- Installing FiraCode Nerd Font ---"
  sudo -u "$ORIGINAL_USER" bash ./sections/install_fonts_alacritty.sh || error_exit "Font and terminal setup failed."

  log "--- Updating .bashrc with Aliases and Git Prompt ---"
  sudo -u "$ORIGINAL_USER" bash ./sections/update_bashrc.sh || error_exit "update_bashrc.sh failed."

  log "--- Setting custom keyboard shortcuts ---"
  ORIGINAL_UID=$(id -u "$ORIGINAL_USER")
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$ORIGINAL_UID/bus"
  echo "Running keyboard shortcut setup as $ORIGINAL_USER with uid $ORIGINAL_UID and dbus session bus address $DBUS_SESSION_BUS_ADDRESS"
  sudo -u "$ORIGINAL_USER" DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS bash ./sections/set_custom_keyboard_shortcuts.sh || error_exit "set_custom_keyboard_shortcuts.sh failed"

  log "--- Installing Brave Browser ---"
  # Brave installation on Fedora is different from Ubuntu
  if [ -f ./sections/install_brave.sh ]; then
    bash ./sections/install_brave.sh || error_exit "install_brave.sh failed"
  else
    log "WARNING: Fedora-specific Brave installation script not found. Skipping Brave installation."
  fi

  log "--- Setting Up Git via SSH ---"
  bash ./sections/set_up_git_ssh.sh || error_exit "set_up_git_ssh.sh failed"

  log "--- Setup Complete! ---"
  log "Altadaim finished (with warnings if any)."
  log "IMPORTANT NEXT STEPS: Reboot to make sure everything is set up correctly."

  SCRIPT_PATH="$(realpath "$0")"
  log "Removing installer script: $SCRIPT_PATH"
  rm -f "$SCRIPT_PATH" || log "WARNING: Failed to remove installer script"
}

main "$@"
