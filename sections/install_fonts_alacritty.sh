#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "Installing FiraCode Nerd Font"

font_zip="FiraCode.zip"
font_dir="$HOME/.local/share/fonts"

mkdir -p "$font_dir"

if [ ! -f "$font_dir/FiraCodeNerdFont-Regular.ttf" ]; then
  wget -P "$HOME" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip
  unzip -o "$HOME/$font_zip" -d "$font_dir"
  rm "$HOME/$font_zip"
  fc-cache -fv
  log "FiraCode Nerd Font installed and font cache refreshed."
else
  log "FiraCode Nerd Font already installed. Skipping."
fi

log "Configuring Alacritty Terminal"

alacritty_config_dir="$HOME/.config/alacritty"
mkdir -p "$alacritty_config_dir"

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
EOF

log "Alacritty configured to use FiraCode Nerd Font."
log "✅ Font and terminal setup complete."
