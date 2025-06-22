#!/usr/bin/env bash
ORIGINAL_USER="$SUDO_USER"
if [ -z "$ORIGINAL_USER" ]; then
  error_exit "Could not determine the original user who invoked sudo. Please ensure SUDO_USER is set."
fi
echo "Script invoked by user: $ORIGINAL_USER"

# Determine Ubuntu version for conditional installations
UBUNTU_VERSION=$(lsb_release -rs)
echo "Detected Ubuntu Version: $UBUNTU_VERSION"

# Function to install multiple APT packages
install_apt_packages() {
  local packages=("$@")
  echo "Installing APT packages: ${packages[*]}"
  apt install -y "${packages[@]}" || error_exit "Failed to install APT packages."
}

install_snap_package() {
  local package_name="$1"
  local classic_flag="$2" # Can be "--classic" or empty
  echo "Installing Snap package: $package_name $classic_flag"
  if ! snap list | grep -q "^$package_name "; then
    sudo snap install "$package_name" "$classic_flag" || error_exit "Failed to install Snap package $package_name."
  else
    echo "$package_name is already installed. Skipping installation."
  fi
}

main_install_apt_packages() {
  CORE_APT_PACKAGES=(
    "snapd"
    "gthumb"
    "python3-pip"
    "postgresql"
    "sqlite3"
    "tmux"
    "docker-compose"
    "docker.io"
    "alacritty"
    "htop"
    "pre-commit"
    "ripgrep"
    "flameshot"
    "chromium-chromedriver"
    "npm"                 # Required for markdownlint-cli2
    "virtualenv"          # For global virtualenv command, though python3 -m venv is preferred
    "curl"                # Ensure curl is installed for various downloads
    "wget"                # Ensure wget is installed for various downloads
    "unzip"               # Ensure unzip is installed for font extraction
    "apt-transport-https" # For Brave browser repository
    "pipx"                # For installing global Python applications like aider and mypy-django
    "libffi-dev"          # Required for building cffi and other Python packages with C extensions
    "libpq-dev"           # Required for building psycopg2-binary (PostgreSQL adapter)
    "dbus-x11"            # Required for setting keyboard shortcuts as sudo
  )

  # Conditionally add python3.10-venv for Ubuntu 22.04 if available/needed,
  # or ensure a generic python3-venv is present for 24.04+
  if [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    echo "Adding python3.10-venv for Ubuntu 22.04."
    CORE_APT_PACKAGES+=("python3.10-venv")
  else
    echo "Adding python3-venv for Ubuntu $UBUNTU_VERSION."
    CORE_APT_PACKAGES+=("python3-venv")
  fi

  install_apt_packages "${CORE_APT_PACKAGES[@]}"
}

main_install_snap_packages() {
  install_snap_package "zellij" "--classic"
  install_snap_package "code" "--classic"
  sudo -u "$ORIGINAL_USER" code --install-extension eamodio.gitlens
  sudo -u "$ORIGINAL_USER" code --install-extension ms-python.python
  sudo -u "$ORIGINAL_USER" code --install-extension charliermarsh.ruff
}

main_install_apt_packages "$@"
main_install_snap_packages "$@"
# Reinstalling Bluetooth packages to preempt common headphone issues.
sudo apt reinstall --purge bluez gnome-bluetooth -y || log "WARNING: Bluetooth package reinstallation failed. Check apt logs for details."
# Adding current user to the 'docker' group to run docker commands without sudo.
# "NOTE: A logout/login is required for this change to take effect."
sudo usermod -aG docker "$ORIGINAL_USER" || log "WARNING: Failed to add user $ORIGINAL_USER to docker group. You might need to do this manually or check permissions."

echo "✅Apt/snap packages installed"
