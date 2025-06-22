#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Exit if any command in a pipeline fails.
set -o pipefail

LOG_FILE="$HOME/ubuntu_setup_$(date +%Y%m%d_%H%M%S).log"
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

UBUNTU_VERSION=$(lsb_release -rs)
log "Detected Ubuntu Version: $UBUNTU_VERSION"

main() {
  log "Starting Altadaim's installer script."
  log "This script will install various development tools and configure your system."

  log "--- Get necessary scripts ---"
  REPO_URL="https://github.com/khaldoun-xyz/altadaim/tree/add-documentation"
  TARGET_DIR="/home/$ORIGINAL_USER/altadaim"
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
  echo 'grub-pc grub-pc/install_devices_empty boolean true' | sudo debconf-set-selections
  sudo apt update -y || error_exit "APT update failed."
  sudo apt upgrade -y || error_exit "APT upgrade failed."
  sudo apt dist-upgrade || error_exit "APT dist-upgrade failed."
  log "✅ System packages updated and upgraded."

  log "--- Installing apt/snap packages ---"
  bash ./sections/install_apt_snap_packages.sh || error_exit "install_apt_snap_packages.sh failed"

  log "--- Installing Aider ---"
  sudo -u "$ORIGINAL_USER" bash ./sections/install_aider.sh || error_exit "install_aider.sh failed"

  log "--- Installing & configuring Neovim & LazyVim (includes Node.js) ---"
  sudo -u "$ORIGINAL_USER" bash ./sections/install_neovim_lazyvim.sh || error_exit "install_neovim_lazyvim.sh failed"

  log "--- Installing Lazygit and Lazydocker ---"
  bash ./sections/install_lazygit_lazydocker.sh || error_exit "install_lazygit_lazydocker.sh failed"

  log "--- Installing FiraCode Nerd Font ---"
  sudo -u "$ORIGINAL_USER" bash ./sections/install_fonts_alacritty.sh || error_exit "Font and terminal setup failed."

  log "--- Installing Brave Browser ---"
  bash ./sections/install_brave.sh || error_exit "install_brave.sh failed"

  log "--- Updating .bashrc with Aliases and Git Prompt ---"
  sudo -u "$ORIGINAL_USER" bash ./sections/update_bashrc.sh || error_exit "update_bashrc.sh failed."

  log "--- Setting Up Git via SSH ---"
  bash ./sections/set_up_git_ssh.sh || error_exit "set_up_git_ssh.sh failed"

  log "--- Setting custom keyboard shortcuts ---"
  ORIGINAL_UID=$(id -u "$ORIGINAL_USER")
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$ORIGINAL_UID/bus"
  echo "Running keyboard shortcut setup as $ORIGINAL_USER with uid $ORIGINAL_UID and dbus session bus address $DBUS_SESSION_BUS_ADDRESS"
  sudo -u "$ORIGINAL_USER" DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS bash ./sections/set_custom_keyboard_shortcuts.sh || error_exit "set_custom_keyboard_shortcuts.sh failed"

  log "--- Setup Complete! ---"
  log "Altadaim finished (with warnings if any)."
  log "IMPORTANT NEXT STEPS: Reboot to make sure everything is set up correctly."
}

main "$@"
