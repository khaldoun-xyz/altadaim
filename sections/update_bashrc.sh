#!/usr/bin/env bash
set -euo pipefail

# Logging
LOG_FILE="${HOME}/update_bashrc_altadaim_$(date +%Y%m%d_%H%M%S).log"
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "🔧 Updating .bashrc for user $USER"

BASHRC_PATH="$HOME/.bashrc"
BASHRC_MARKER="# --------------------------- ADDED BY ALTADAIM --------------------------------"

# Check if the block already exists
if ! grep -q "$BASHRC_MARKER" "$BASHRC_PATH"; then
  cat <<'EOF' >>"$BASHRC_PATH"

# --------------------------- ADDED BY ALTADAIM --------------------------------
# show git branch in Terminal
function parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

RED="\[\033[01;31m\]"
YELLOW="\[\033[01;33m\]"
GREEN="\[\033[01;32m\]"
BLUE="\[\033[01;34m\]"
NO_COLOR="\[\033[00m\]"
PS1="${GREEN}\u${NO_COLOR}:${BLUE}\w${YELLOW}\$(parse_git_branch)${NO_COLOR}$ "

# add neovim alias
alias n='~/nvim-linux-x86_64.appimage'
EOF

  log ".bashrc updated with ALTADAIM customization."
else
  log ".bashrc already contains ALTADAIM customization. Skipping."
fi

echo "✅ .bashrc updated."
