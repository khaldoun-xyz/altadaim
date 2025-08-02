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

# Determine Fedora version for conditional installations
if [ -f /etc/fedora-release ]; then
  FEDORA_VERSION=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
  echo "Detected Fedora Version: $FEDORA_VERSION"
else
  error_exit "This script is designed for Fedora, but /etc/fedora-release was not found."
fi

# Remove unused function since we're installing packages individually now
# install_dnf_packages() function removed

# Function to install Flatpak packages (Fedora's equivalent to Snap)
install_flatpak_package() {
  local package_name="$1"
  echo "Installing Flatpak package: $package_name"
  if ! flatpak list | grep -q "$package_name"; then
    sudo -u "$ORIGINAL_USER" flatpak install -y flathub "$package_name" || error_exit "Failed to install Flatpak package $package_name."
  else
    echo "$package_name is already installed. Skipping installation."
  fi
}

main_install_dnf_packages() {
  # Enable RPM Fusion repositories first (needed for some packages)
  echo "Enabling RPM Fusion repositories..."
  dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
    2>/dev/null || echo "RPM Fusion repositories might already be enabled"

  # Add Docker's official repository
  echo "Adding Docker repository..."
  dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || echo "Docker repository might already be added"

  CORE_DNF_PACKAGES=(
    "flatpak"            # Fedora's app distribution system (similar to Snap)
    "gthumb"             # Image viewer
    "python3-pip"        # Python package manager
    "postgresql"         # Database
    "postgresql-server"  # PostgreSQL server
    "sqlite"             # SQLite database
    "tmux"               # Terminal multiplexer
    "docker-compose"     # Docker compose
    "docker-ce"          # Docker Community Edition
    "alacritty"          # Terminal emulator
    "htop"               # Process viewer
    "ripgrep"            # Fast text search
    "flameshot"          # Screenshot tool
    "chromium"           # Chromium browser
    "npm"                # Node package manager
    "python3-virtualenv" # Virtual environments
    "curl"               # Download tool
    "wget"               # Download tool
    "unzip"              # Archive extraction
    "pipx"               # Python app installer
    "libffi-devel"       # Development headers for libffi
    "postgresql-devel"   # PostgreSQL development headers
    "dbus-x11"           # D-Bus X11 support
    "git"                # Version control
    "gcc"                # Compiler (often needed for Python packages)
    "python3-devel"      # Python development headers
    "rust"               # Rust compiler (for zellij)
    "cargo"              # Rust package manager
    "dnf-plugins-core"   # Required for adding Docker repository
  )

  # Try to install packages, but don't fail if some don't exist
  for package in "${CORE_DNF_PACKAGES[@]}"; do
    echo "Installing $package..."
    dnf install -y "$package" || echo "WARNING: Failed to install $package, continuing..."
  done
}

setup_flatpak() {
  echo "Setting up Flatpak and Flathub repository..."
  # Add Flathub repository
  sudo -u "$ORIGINAL_USER" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || echo "Flathub repository might already be added"
}

main_install_flatpak_packages() {
  # Install zellij via cargo (now that rust/cargo should be installed)
  echo "Installing zellij..."
  if command -v cargo >/dev/null 2>&1; then
    sudo -u "$ORIGINAL_USER" cargo install zellij || echo "Failed to install zellij via cargo"
  else
    echo "Cargo not found, trying alternative installation for zellij..."
    # Download pre-built binary as fallback - get latest version dynamically
    echo "Getting latest zellij version..."
    ZELLIJ_VERSION=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

    if [ -z "$ZELLIJ_VERSION" ]; then
      echo "Failed to get latest zellij version, using fallback v0.39.2"
      ZELLIJ_VERSION="v0.39.2"
    fi

    echo "Installing zellij $ZELLIJ_VERSION ..."
    ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
    cd /tmp
    wget "$ZELLIJ_URL" -O zellij.tar.gz || echo "Failed to download zellij"
    tar -xzf zellij.tar.gz || echo "Failed to extract zellij"
    sudo mv zellij /usr/local/bin/ || echo "Failed to install zellij binary"
    sudo chmod +x /usr/local/bin/zellij || echo "Failed to make zellij executable"
    rm -f zellij.tar.gz
  fi
}

setup_docker() {
  echo "Setting up Docker..."

  # Stop and disable Podman if it's running (to avoid conflicts)
  systemctl stop podman || echo "Podman was not running"
  systemctl disable podman || echo "Podman was not enabled"
  sudo -u "$ORIGINAL_USER" systemctl --user stop podman.socket || echo "User podman socket was not running"
  sudo -u "$ORIGINAL_USER" systemctl --user disable podman.socket || echo "User podman socket was not enabled"

  # Start and enable Docker service
  systemctl start docker || echo "Failed to start Docker"
  systemctl enable docker || echo "Failed to enable Docker"

  # Add user to docker group
  usermod -aG docker "$ORIGINAL_USER" || echo "WARNING: Failed to add user $ORIGINAL_USER to docker group"

  echo "Docker setup complete. Note: You may need to log out and back in for group changes to take effect."
}

setup_postgresql() {
  echo "Setting up PostgreSQL..."
  # Initialize PostgreSQL database (Fedora-specific command)
  sudo -u postgres initdb -D /var/lib/pgsql/data || echo "PostgreSQL might already be initialized"
  systemctl start postgresql || echo "Failed to start PostgreSQL"
  systemctl enable postgresql || echo "Failed to enable PostgreSQL"
}

# Install pre-commit via pipx (more reliable)
install_precommit() {
  echo "Installing pre-commit via pipx..."
  sudo -u "$ORIGINAL_USER" pipx install pre-commit || echo "Failed to install pre-commit via pipx"
}

# Install chromedriver separately (might not be in main repos)
install_chromedriver() {
  echo "Installing ChromeDriver..."
  # Try package manager first
  dnf install -y chromedriver 2>/dev/null || {
    echo "ChromeDriver not available via DNF, downloading manually..."
    # Use the new Chrome for Testing API
    echo "Getting latest ChromeDriver version from Chrome for Testing API..."
    CHROMEDRIVER_VERSION=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE")

    if [ -z "$CHROMEDRIVER_VERSION" ]; then
      echo "Failed to get latest ChromeDriver version, skipping installation"
      return 1
    fi

    echo "Downloading ChromeDriver version $CHROMEDRIVER_VERSION..."
    CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/${CHROMEDRIVER_VERSION}/linux64/chromedriver-linux64.zip"

    wget -O /tmp/chromedriver.zip "$CHROMEDRIVER_URL" || {
      echo "Failed to download ChromeDriver from new API, trying fallback..."
      # Fallback to a known working version if the new API fails
      wget -O /tmp/chromedriver.zip "https://storage.googleapis.com/chrome-for-testing-public/120.0.6099.109/linux64/chromedriver-linux64.zip" || {
        echo "Failed to download ChromeDriver"
        return 1
      }
    }

    unzip -q /tmp/chromedriver.zip -d /tmp/ || echo "Failed to extract ChromeDriver"
    sudo mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/ || echo "Failed to install ChromeDriver"
    sudo chmod +x /usr/local/bin/chromedriver || echo "Failed to make ChromeDriver executable"
    rm -f /tmp/chromedriver.zip
    rm -rf /tmp/chromedriver-linux64
  }
}

# Main execution
main_install_dnf_packages "$@"
setup_flatpak
main_install_flatpak_packages "$@"
setup_docker
setup_postgresql
install_precommit
install_chromedriver

# Reinstalling Bluetooth packages (Fedora equivalent)
echo "Reinstalling Bluetooth packages..."
dnf reinstall -y bluez gnome-bluetooth || echo "WARNING: Bluetooth package reinstallation failed."

echo "✅ DNF/Flatpak packages installed"
