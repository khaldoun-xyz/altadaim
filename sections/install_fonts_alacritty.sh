#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Define error_exit function if not already defined
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

log "Installing FiraCode Nerd Font"

font_zip="FiraCode.zip"
font_dir="$HOME/.local/share/fonts"
mkdir -p "$font_dir"

if [ ! -f "$font_dir/FiraCodeNerdFont-Regular.ttf" ]; then
  # Check if wget is available, install if not
  if ! command -v wget &>/dev/null; then
    log "wget not found. Installing via DNF..."
    sudo dnf install -y wget || error_exit "Failed to install wget"
  fi
  
  # Check if unzip is available, install if not  
  if ! command -v unzip &>/dev/null; then
    log "unzip not found. Installing via DNF..."
    sudo dnf install -y unzip || error_exit "Failed to install unzip"
  fi
  
  log "Downloading FiraCode Nerd Font..."
  wget -P "$HOME" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip || error_exit "Failed to download FiraCode font"
  
  log "Extracting font files..."
  unzip -o "$HOME/$font_zip" -d "$font_dir" || error_exit "Failed to extract font files"
  rm "$HOME/$font_zip"
  
  log "Refreshing font cache..."
  fc-cache -fv || error_exit "Failed to refresh font cache"
  log "FiraCode Nerd Font installed and font cache refreshed."
else
  log "FiraCode Nerd Font already installed. Skipping."
fi

log "Configuring Alacritty Terminal"

# Check if Alacritty is installed, install if not
if ! command -v alacritty &>/dev/null; then
  log "Alacritty not found. Installing via DNF..."
  sudo dnf install -y alacritty || error_exit "Failed to install Alacritty"
  log "Alacritty installed successfully."
fi

alacritty_config_dir="$HOME/.config/alacritty"
mkdir -p "$alacritty_config_dir"

# Create modern TOML configuration (Alacritty v0.13+)
cat <<EOF >"$alacritty_config_dir/alacritty.toml"
[font]
size = 12.0

[font.normal]
family = "FiraCode Nerd Font"
style = "Regular"

[font.bold]
family = "FiraCode Nerd Font"
style = "Bold"

[font.italic]
family = "FiraCode Nerd Font"
style = "Italic"

[env]
LANG = "en_US.UTF-8"

[window]
opacity = 0.95
padding = { x = 10, y = 10 }

[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"
EOF

# Also create legacy YAML config for older Alacritty versions
cat <<EOF >"$alacritty_config_dir/alacritty.yml"
font:
  normal:
    family: "FiraCode Nerd Font"
  size: 12.0
  bold:
    family: "FiraCode Nerd Font"
  italic:
    family: "FiraCode Nerd Font"
env:
  LANG: en_US.UTF-8
window:
  opacity: 0.95
  padding:
    x: 10
    y: 10
colors:
  primary:
    background: '#1e1e2e'
    foreground: '#cdd6f4'
EOF

log "Alacritty configured to use FiraCode Nerd Font (both TOML and YAML configs created)."
log "✅ Font and terminal setup complete."
