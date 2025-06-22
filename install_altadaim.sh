#!/usr/bin/env bash

# --- Error Handling ---

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Exit if any command in a pipeline fails.
set -o pipefail

# Define log file
LOG_FILE="$HOME/ubuntu_setup_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages to console and log file
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
  log "ERROR: $1"
  exit 1
}

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
  error_exit "This script must be run with sudo or as root. Please run 'sudo bash ./install_altadaim.sh'"
fi

# Store the original user who invoked sudo
# This is crucial for operations that need to run as the regular user (e.g., Git cloning with SSH keys)
ORIGINAL_USER="$SUDO_USER"
if [ -z "$ORIGINAL_USER" ]; then
  error_exit "Could not determine the original user who invoked sudo. Please ensure SUDO_USER is set."
fi
log "Script invoked by user: $ORIGINAL_USER"

# Determine Ubuntu version for conditional installations
UBUNTU_VERSION=$(lsb_release -rs)
log "Detected Ubuntu Version: $UBUNTU_VERSION"

# --- Helper Functions ---

# Function to install multiple APT packages
install_apt_packages() {
  local packages=("$@")
  log "Installing APT packages: ${packages[*]}"
  sudo apt install -y "${packages[@]}" || error_exit "Failed to install APT packages."
}

# Function to install a Snap package, checking if it's already installed
install_snap_package() {
  local package_name="$1"
  local classic_flag="$2" # Can be "--classic" or empty
  log "Installing Snap package: $package_name $classic_flag"
  if ! snap list | grep -q "^$package_name "; then
    sudo snap install "$package_name" "$classic_flag" || error_exit "Failed to install Snap package $package_name."
  else
    log "$package_name is already installed. Skipping installation."
  fi
}

# Function to configure Git's global credential helper for the original user
configure_git() {
  log "Configuring Git global credential helper for user $ORIGINAL_USER."
  sudo -u "$ORIGINAL_USER" git config --global credential.helper store || error_exit "Failed to configure Git credential helper for user $ORIGINAL_USER."
}

setup_git_ssh() {
  local ssh_dir="/home/$ORIGINAL_USER/.ssh"
  local ssh_key="$ssh_dir/id_ed25519"
  log "Setting up Git SSH for user $ORIGINAL_USER."
  if [ -f "$ssh_key" ]; then
    log "SSH key already exists for $ORIGINAL_USER at $ssh_key. Skipping key generation."
  else
    log "Generating a new SSH key for $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" mkdir -p "$ssh_dir"
    sudo -u "$ORIGINAL_USER" ssh-keygen -t ed25519 -C "$ORIGINAL_USER@$(hostname)" -f "$ssh_key" -N "" || error_exit "Failed to generate SSH key for $ORIGINAL_USER."
    log "SSH key generated successfully for $ORIGINAL_USER."
  fi
  # Ensure proper permissions
  sudo chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$ssh_dir"
  sudo chmod 700 "$ssh_dir"
  sudo chmod 600 "$ssh_key"
  sudo chmod 644 "$ssh_key.pub"
  log "Here is the public SSH key for $ORIGINAL_USER:"
  sudo -u "$ORIGINAL_USER" cat "$ssh_key.pub"
  log "You should now add this key to your Git hosting service (e.g., GitHub/GitLab)."
  log "Opening GitHub SSH key settings page in Brave Browser..."
  sudo -u "$ORIGINAL_USER" brave-browser "https://github.com/settings/ssh/new" || log ">>>>> WARNING <<<<<: Could not open GitHub SSH key page. Please open it manually: https://github.com/settings/ssh/new"
  log "Testing SSH connection to GitHub (you may see a one-time prompt to confirm the host fingerprint)..."
  sudo -u "$ORIGINAL_USER" ssh -T git@github.com || log "SSH test to GitHub failed. This may be expected if the key hasn’t been added yet."
}

# Function to install the latest release of a GitHub binary (e.g., lazygit, lazydocker)
install_latest_github_release() {
  local repo="$1"                     # e.g., "jesseduffield/lazygit"
  local binary_name="$2"              # e.g., "lazygit"
  local install_path="/usr/local/bin" # Standard path for local binaries

  log "Installing latest $binary_name from $repo"
  local latest_version
  # Fetch the latest release tag name
  latest_version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  if [ -z "$latest_version" ]; then
    error_exit "Could not determine latest version for $binary_name from $repo."
  fi

  local download_url="https://github.com/$repo/releases/latest/download/${binary_name}_${latest_version}_Linux_x86_64.tar.gz"
  local temp_tar_file="${binary_name}.tar.gz"
  local temp_dir="${binary_name}-temp"

  log "Downloading $binary_name from $download_url"
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
    log "$binary_name installed successfully to $install_path."
  else
    error_exit "Expected binary '$binary_name' not found in extracted directory '/home/$ORIGINAL_USER/$temp_dir'."
  fi

  # Clean up temporary files, as ORIGINAL_USER
  sudo -u "$ORIGINAL_USER" rm -rf "/home/$ORIGINAL_USER/$temp_tar_file" "/home/$ORIGINAL_USER/$temp_dir" || log "WARNING: Failed to clean up temporary files for $binary_name for user $ORIGINAL_USER."
}

# --- Main Installation Logic ---

main() {
  log "Starting Altadaim's installer script."
  log "This script will install various development tools and configure your system."

  log "--- Section 1: System Update and Upgrade ---"
  log "Updating and upgrading system packages. This may take some time."
  echo 'grub-pc grub-pc/install_devices_empty boolean true' | sudo debconf-set-selections
  sudo apt update -y || error_exit "APT update failed."
  sudo apt upgrade -y || error_exit "APT upgrade failed."
  sudo apt dist-upgrade || error_exit "APT dist-upgrade failed."
  log "System packages updated and upgraded."

  log "--- Section 2: Installing Core APT Packages ---"
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
    log "Adding python3.10-venv for Ubuntu 22.04."
    CORE_APT_PACKAGES+=("python3.10-venv")
  else
    log "Adding python3-venv for Ubuntu $UBUNTU_VERSION."
    CORE_APT_PACKAGES+=("python3-venv")
  fi

  install_apt_packages "${CORE_APT_PACKAGES[@]}"
  log "Core APT packages installed."

  log "--- Section 3: Installing Snap Packages ---"
  install_snap_package "zellij" "--classic"
  log "Snap packages installed."

  # 4. Docker Post-installation Steps
  log "--- Section 4: Docker Configuration ---"
  log "Adding current user to the 'docker' group to run docker commands without sudo."
  log "NOTE: A logout/login is required for this change to take effect."
  sudo usermod -aG docker "$ORIGINAL_USER" || log "WARNING: Failed to add user $ORIGINAL_USER to docker group. You might need to do this manually or check permissions."
  log "Docker group configuration complete."

  log "--- Section 5: Global Python Applications (via pipx) ---"
  # PEP 668: Avoids direct pip install into system Python.
  # pipx is installed via apt in CORE_APT_PACKAGES.

  log "Installing Aider (AI code assistant) using pipx for user $ORIGINAL_USER."
  sudo -u "$ORIGINAL_USER" pipx install aider-install || log "WARNING: Failed to install aider-install with pipx for user $ORIGINAL_USER. Check internet connection or pipx issues."
  sudo -u "$ORIGINAL_USER" aider-install || log "WARNING: Failed to run aider-install for user $ORIGINAL_USER."

  log "Global Python applications installed."

  log "--- Section 6: Bluetooth Configuration ---"
  log "Reinstalling Bluetooth packages to preempt common headphone issues."
  sudo apt reinstall --purge bluez gnome-bluetooth -y || log "WARNING: Bluetooth package reinstallation failed. Check apt logs for details."
  log "Bluetooth packages reinstalled (if needed)."

  log "--- Section 7: Setting up Development Directories ---"
  log "Creating '/home/$ORIGINAL_USER/virtualenvs' and '/home/$ORIGINAL_USER/programming' directories for user $ORIGINAL_USER."
  sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/virtualenvs" || log "WARNING: Directory /home/$ORIGINAL_USER/virtualenvs already exists or could not be created."
  sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/programming" || log "WARNING: Directory /home/$ORIGINAL_USER/programming already exists or could not be created."
  # Change directory as ORIGINAL_USER to ensure subsequent git clones are in the correct place

  log "Attempting to change current directory to /home/$ORIGINAL_USER/programming/ (for informational purposes)."
  # The actual cloning commands use absolute paths, so the current directory of the root user is less important.

  log "--- Section 8: Neovim Installation and Configuration ---"
  log "Installing Neovim AppImage for user $ORIGINAL_USER."
  local nvim_appimage="/home/$ORIGINAL_USER/nvim-linux-x86_64.appimage"
  if [ ! -f "$nvim_appimage" ]; then
    sudo -u "$ORIGINAL_USER" curl -fsSLo "$nvim_appimage" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage || error_exit "Failed to download Neovim AppImage for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" chmod u+x "$nvim_appimage" || error_exit "Failed to make Neovim AppImage executable for user $ORIGINAL_USER."
    log "Neovim AppImage downloaded and made executable for user $ORIGINAL_USER."
  else
    log "Neovim AppImage already exists for user $ORIGINAL_USER. Skipping download."
  fi

  log "Setting up LazyVim configuration for user $ORIGINAL_USER."
  local nvim_config_dir="/home/$ORIGINAL_USER/.config/nvim"
  if [ ! -d "$nvim_config_dir" ]; then
    sudo -u "$ORIGINAL_USER" git clone https://github.com/LazyVim/starter "$nvim_config_dir" || error_exit "Failed to clone LazyVim starter config for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" rm -rf "$nvim_config_dir/.git" || log "WARNING: Failed to remove .git from LazyVim config for user $ORIGINAL_USER. Manual cleanup might be needed."
  else
    log "LazyVim configuration already exists for user $ORIGINAL_USER. Skipping clone."
  fi

  log "Add LazyExtras plugin, update options.lua and update init.lua."
  EXTRAS_FILE="/home/$ORIGINAL_USER/.config/nvim/lua/plugins/extras.lua"
  sudo -u "$ORIGINAL_USER" mkdir -p "$(dirname "$EXTRAS_FILE")"
  sudo -u "$ORIGINAL_USER" tee "$EXTRAS_FILE" >/dev/null <<EOF
return {
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.sql" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.terraform" },
}
EOF
  log "LazyExtras plugin imports written to $EXTRAS_FILE"

  # Set LSP option in config/init.lua
  CONFIG_DIR="/home/$ORIGINAL_USER/.config/nvim/lua/config"
  sudo -u "$ORIGINAL_USER" mkdir -p "$CONFIG_DIR"
  sudo -u "$ORIGINAL_USER" tee "$CONFIG_DIR/init.lua" >/dev/null <<EOF
vim.g.lazyvim_python_lsp = "basedpyright"
EOF
  log "Set lazyvim_python_lsp = 'basedpyright' in lua/config/init.lua"

  OPTIONS_FILE="/home/$ORIGINAL_USER/.config/nvim/lua/config/options.lua"
  sudo -u "$ORIGINAL_USER" tee -a "$OPTIONS_FILE" >/dev/null <<EOF
-- Add any custom options here if needed
EOF
  log "Verified options.lua exists"

  INIT_FILE="/home/$ORIGINAL_USER/.config/nvim/init.lua"
  sudo -u "$ORIGINAL_USER" mkdir -p "$(dirname "$INIT_FILE")"
  # Create init.lua if it doesn't exist
  if ! sudo -u "$ORIGINAL_USER" test -f "$INIT_FILE"; then
    sudo -u "$ORIGINAL_USER" tee "$INIT_FILE" >/dev/null <<EOF
-- Load config globals
require("config")

-- Load custom options
require("config.options")

-- Then bootstrap LazyVim
require("config.lazy")

EOF
    log "Created new init.lua with config.init and config.options"
  else
    # Make sure it sources config and options
    if ! sudo -u "$ORIGINAL_USER" grep -q 'require("config.options")' "$INIT_FILE"; then
      sudo -u "$ORIGINAL_USER" sed -i '/require("config.lazy")/i require("config.options")' "$INIT_FILE"
      log "Inserted require(\"config.options\") before require(\"config.lazy\") in $INIT_FILE"
    fi
    if ! sudo -u "$ORIGINAL_USER" grep -q 'require("config")' "$INIT_FILE"; then
      sudo -u "$ORIGINAL_USER" sed -i '1irequire("config")' "$INIT_FILE"
      log "Inserted require(\"config\") at top of $INIT_FILE"
    fi
  fi
  log "Neovim and LazyVim setup complete."

  log "--- Section 9: Installing Lazygit and Lazydocker ---"
  # These are installed to /usr/local/bin, which is system-wide, but the download process
  # needs to be done as the original user to access their home directory for temp files.
  install_latest_github_release "jesseduffield/lazygit" "lazygit"
  install_latest_github_release "jesseduffield/lazydocker" "lazydocker"
  log "Lazygit and Lazydocker installed."
  log "Creating empty config.yml for Lazygit under /home/$ORIGINAL_USER/.config/lazygit"
  sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/.config/lazygit" || log "WARNING: Failed to create .config/lazygit directory."
  sudo -u "$ORIGINAL_USER" touch "/home/$ORIGINAL_USER/.config/lazygit/config.yml" || log "WARNING: Failed to create empty config.yml for Lazygit."
  log "Empty Lazygit config.yml created."

  log "--- Section 10: Installing FiraCode Nerd Font ---"
  local font_zip="FiraCode.zip"
  local font_dir="/home/$ORIGINAL_USER/.local/share/fonts"
  # Ensure font directory exists and is owned by the original user
  sudo -u "$ORIGINAL_USER" mkdir -p "$font_dir" || error_exit "Failed to create font directory '$font_dir' for user $ORIGINAL_USER."

  # Check for one of the font files to determine if fonts are already installed
  if [ ! -f "$font_dir/FiraCodeNerdFont-Regular.ttf" ]; then
    sudo -u "$ORIGINAL_USER" wget -P "/home/$ORIGINAL_USER/" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip || error_exit "Failed to download FiraCode Nerd Font for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" unzip "/home/$ORIGINAL_USER/$font_zip" -d "$font_dir" || error_exit "Failed to unzip FiraCode Nerd Font for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" rm "/home/$ORIGINAL_USER/$font_zip" || log "WARNING: Failed to remove font zip file '/home/$ORIGINAL_USER/$font_zip'."
    # fc-cache needs to be run by the user for their font cache
    sudo -u "$ORIGINAL_USER" fc-cache -fv || log "WARNING: Failed to refresh font cache for user $ORIGINAL_USER. Font changes might not apply immediately."
    log "FiraCode Nerd Font installed and font cache refreshed for user $ORIGINAL_USER."
  else
    log "FiraCode Nerd Font appears to be already installed for user $ORIGINAL_USER. Skipping font installation."
  fi
  log "Nerd Fonts setup complete."

  log "--- Section 11: Configuring Alacritty Terminal ---"
  local alacritty_config_dir="/home/$ORIGINAL_USER/.config/alacritty/"
  # Ensure config directory exists and is owned by the original user
  sudo -u "$ORIGINAL_USER" mkdir -p "$alacritty_config_dir" || log "WARNING: Alacritty config directory already exists or could not be created for user $ORIGINAL_USER."
  # Use tee to write the alacritty.yml content, overwriting if it exists, as ORIGINAL_USER
  sudo -u "$ORIGINAL_USER" bash -c "cat <<EOF | tee \"$alacritty_config_dir/alacritty.yml\" > /dev/null
font:
  normal:
    family: \"FiraCode Nerd Font\"
    size: 12.0
  bold:
    family: \"FiraCode Nerd Font\"
  italic:
    family: \"FiraCode Nerd Font\"
env:
  LANG: en_US.UTF-8
EOF"
  log "Alacritty configuration updated with FiraCode Nerd Font for user $ORIGINAL_USER."

  log "--- Section 12: Node.js and npm Tools ---"
  log "Installing NVM (Node Version Manager) and Node.js for user $ORIGINAL_USER."
  local nvm_dir="/home/$ORIGINAL_USER/.nvm"
  local nvm_install_script="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
  # Install NVM if it doesn't exist
  if [ ! -d "$nvm_dir" ]; then
    log "NVM not found. Installing..."
    sudo -u "$ORIGINAL_USER" bash -c "curl -o- \"$nvm_install_script\" | bash" || log "WARNING: Failed to install NVM."
  else
    log "NVM already installed for $ORIGINAL_USER. Skipping installation."
  fi
  log "Installing LTS version of Node.js and markdownlint-cli2..."
  sudo -u "$ORIGINAL_USER" bash -c "
    export NVM_DIR=\"$nvm_dir\"
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    npm install -g markdownlint-cli2
  " || log "WARNING: Failed to install Node.js or markdownlint-cli2 for user $ORIGINAL_USER."
  log "Node.js and markdownlint-cli2 installed successfully for user $ORIGINAL_USER."

  log "--- Section 14: Installing Brave Browser ---"
  log "Adding Brave Browser repository and installing Brave."
  # Ensure keyring directory exists
  sudo mkdir -p /usr/share/keyrings/ || log "WARNING: Failed to create /usr/share/keyrings/ directory."
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg || error_exit "Failed to download Brave keyring."
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list || error_exit "Failed to add Brave repository."
  sudo apt update -y || error_exit "APT update after Brave repo addition failed."
  sudo apt install -y brave-browser || error_exit "Failed to install Brave Browser."
  log "Brave Browser installed."

  log "--- Section 15: Updating .bashrc with Aliases and Git Prompt ---"

  BASHRC_PATH="/home/$ORIGINAL_USER/.bashrc"
  BASHRC_MARKER="# --------------------------- ADDED BY ALTADAIM --------------------------------"

  # Check if the block already exists
  if ! sudo -u "$ORIGINAL_USER" grep -q "$BASHRC_MARKER" "$BASHRC_PATH"; then
    sudo -u "$ORIGINAL_USER" bash -c "cat <<'EOF' >> \"$BASHRC_PATH\"
$BASHRC_MARKER
# show git branch in Terminal
function parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
RED=\"\\[\033[01;31m\\]\"
YELLOW=\"\\[\033[01;33m\\]\"
GREEN=\"\\[\033[01;32m\\]\"
BLUE=\"\\[\033[01;34m\\]\"
NO_COLOR=\"\\[\033[00m\\]\"
PS1=\"\$GREEN\\u\$NO_COLOR:\$BLUE\\w\$YELLOW\\\$(parse_git_branch)\$NO_COLOR\$ \"

# add neovim alias
alias n='~/nvim-linux-x86_64.appimage'
EOF"
    log ".bashrc updated with ALTADAIM customization for user $ORIGINAL_USER."

  else
    log ".bashrc already contains ALTADAIM customization. Skipping append."
  fi

  log "--- Section 16: Setting Up Git via SSH ---"
  setup_git_ssh

  log "--- Setting custom keyboard shortcuts ---"
  ORIGINAL_UID=$(id -u "$ORIGINAL_USER")
  echo "Running keyboard shortcut setup as $ORIGINAL_USER with uid $ORIGINAL_UID"
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$ORIGINAL_UID/bus"
  sudo -u "$ORIGINAL_USER" DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS bash ./sections/set_custom_keyboard_shortcuts.sh

  log "--- Setup Complete! ---"
  log "Altadaim finished (with warnings if any)."
  log "IMPORTANT NEXT STEPS: Reboot for Docker group & NVM (Node Version Manager) changes to take full effect."
  log "Review the log file at $LOG_FILE for any warnings or errors that occurred during execution."
}

# Execute the main function
main "$@"
