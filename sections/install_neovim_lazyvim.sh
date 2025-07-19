#!/usr/bin/env bash

# Exit on errors, unset vars, or failed pipes
set -euo pipefail

# Logging
LOG_FILE="${HOME}/install_neovim_lazyvim_$(date +%Y%m%d_%H%M%S).log"
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}
error_exit() {
  log "ERROR: $1"
  exit 1
}

# User running the script (non-sudo)
ORIGINAL_USER="${USER}"
HOME_DIR="/home/$ORIGINAL_USER"

log "Installing Neovim AppImage for user $ORIGINAL_USER."

nvim_appimage="$HOME_DIR/nvim-linux-x86_64.appimage"
if [ ! -f "$nvim_appimage" ]; then
  curl -fsSLo "$nvim_appimage" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage || error_exit "Failed to download Neovim AppImage."
  chmod u+x "$nvim_appimage" || error_exit "Failed to make Neovim AppImage executable."
  log "Neovim AppImage downloaded and made executable."
else
  log "Neovim AppImage already exists. Skipping download."
fi

log "Setting up LazyVim configuration."

nvim_config_dir="$HOME_DIR/.config/nvim"
if [ ! -d "$nvim_config_dir" ]; then
  git clone https://github.com/LazyVim/starter "$nvim_config_dir" || error_exit "Failed to clone LazyVim starter config."
  rm -rf "$nvim_config_dir/.git" || log "WARNING: Failed to remove .git from LazyVim config. Manual cleanup might be needed."
else
  log "LazyVim config already exists. Skipping clone."
fi

log "Adding LazyExtras plugins for language support ..."
EXTRAS_FILE="$nvim_config_dir/lua/plugins/extras.lua"
mkdir -p "$(dirname "$EXTRAS_FILE")"
tee "$EXTRAS_FILE" >/dev/null <<EOF
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
log "LazyExtras written to $EXTRAS_FILE"

log "Adding Snacks.nvim configuration to show ignored files in tree viewer ..."
SNACKS_FILE="$nvim_config_dir/lua/plugins/snacks.lua"
mkdir -p "$(dirname "$SNACKS_FILE")"
tee "$SNACKS_FILE" >/dev/null <<EOF
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Show both dotfiles and gitignored files in all pickers
        hidden = true,
        ignored = true,

        -- Configure the tree explorer specifically
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
EOF
log "Snacks.nvim configuration written to $SNACKS_FILE"

#!/usr/bin/env bash

# Exit on errors, unset vars, or failed pipes
set -euo pipefail

# Logging
LOG_FILE="${HOME}/install_neovim_lazyvim_$(date +%Y%m%d_%H%M%S).log"
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}
error_exit() {
  log "ERROR: $1"
  exit 1
}

# User running the script (non-sudo)
ORIGINAL_USER="${USER}"
HOME_DIR="/home/$ORIGINAL_USER"

log "Installing Neovim AppImage for user $ORIGINAL_USER."

nvim_appimage="$HOME_DIR/nvim-linux-x86_64.appimage"
if [ ! -f "$nvim_appimage" ]; then
  curl -fsSLo "$nvim_appimage" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage || error_exit "Failed to download Neovim AppImage."
  chmod u+x "$nvim_appimage" || error_exit "Failed to make Neovim AppImage executable."
  log "Neovim AppImage downloaded and made executable."
else
  log "Neovim AppImage already exists. Skipping download."
fi

log "Setting up LazyVim configuration."

nvim_config_dir="$HOME_DIR/.config/nvim"
if [ ! -d "$nvim_config_dir" ]; then
  git clone https://github.com/LazyVim/starter "$nvim_config_dir" || error_exit "Failed to clone LazyVim starter config."
  rm -rf "$nvim_config_dir/.git" || log "WARNING: Failed to remove .git from LazyVim config. Manual cleanup might be needed."
else
  log "LazyVim config already exists. Skipping clone."
fi

log "Adding LazyExtras plugins for language support ..."
EXTRAS_FILE="$nvim_config_dir/lua/plugins/extras.lua"
mkdir -p "$(dirname "$EXTRAS_FILE")"
tee "$EXTRAS_FILE" >/dev/null <<EOF
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
log "LazyExtras written to $EXTRAS_FILE"

log "Adding Snacks.nvim configuration to show ignored files in tree viewer ..."
SNACKS_FILE="$nvim_config_dir/lua/plugins/snacks.lua"
mkdir -p "$(dirname "$SNACKS_FILE")"
tee "$SNACKS_FILE" >/dev/null <<EOF
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Show both dotfiles and gitignored files in all pickers
        hidden = true,
        ignored = true,

        -- Configure the tree explorer specifically
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
EOF
log "Snacks.nvim configuration written to $SNACKS_FILE"

log "Adding Avante.nvim configuration ..."
AVANTE_FILE="$nvim_config_dir/lua/plugins/avante.lua"
mkdir -p "$(dirname "$AVANTE_FILE")"
tee "$AVANTE_FILE" >/dev/null <<EOF
return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false,
  opts = {
    provider = "claude",
    auto_suggestions = true,
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-3-5-sonnet-20241022",
      temperature = 0,
      max_tokens = 4096,
    },
    behaviour = {
      auto_suggestions = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
    },
    mappings = {
      submit = {
        normal = "<CR>",
        insert = "<C-s>", 
      },
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
    },
    hints = { enabled = true },
    windows = {
      position = "right",
      wrap = true,
      width = 30,
      sidebar_header = {
        align = "center",
        rounded = true,
      },
    },
  },
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
EOF

log "--- Setting up Anthropic API Key ---"
BASHRC_FILE="$HOME_DIR/.bashrc"
if ! grep -q "export AVANTE_ANTHROPIC_API_KEY" "$BASHRC_FILE" 2>/dev/null; then
  log "Adding AVANTE_ANTHROPIC_API_KEY to .bashrc..."
  echo "" >>"$BASHRC_FILE"
  echo "# Anthropic API Key for Avante.nvim" >>"$BASHRC_FILE"
  echo 'export AVANTE_ANTHROPIC_API_KEY="YOUR API KEY"' >>"$BASHRC_FILE"
  log "✅ Added AVANTE_ANTHROPIC_API_KEY to .bashrc"
  log "⚠️  IMPORTANT: Please edit ~/.bashrc and replace 'YOUR API KEY' with your actual Anthropic API key!"
else
  log "AVANTE_ANTHROPIC_API_KEY already exists in .bashrc. Skipping."
fi
log "Avante.nvim configuration written to $AVANTE_FILE"

log "Adding LSP to config/init.lua and update options config..."
CONFIG_DIR="$nvim_config_dir/lua/config"
mkdir -p "$CONFIG_DIR"
tee "$CONFIG_DIR/init.lua" >/dev/null <<EOF
vim.g.lazyvim_python_lsp = "basedpyright"
EOF
tee -a "$CONFIG_DIR/options.lua" >/dev/null <<EOF
-- Add any custom options here if needed
EOF

log "Adding autocmds.lua for JSON formatting..."
AUTOCMDS_FILE="$CONFIG_DIR/autocmds.lua"
tee "$AUTOCMDS_FILE" >/dev/null <<EOF
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*.json",
  callback = function()
    -- Only run if jq is available
    if vim.fn.executable("jq") == 1 then
      vim.cmd("%!jq .")
    else
      vim.notify("jq not found, skipping JSON formatting", vim.log.levels.WARN)
    end
  end,
})
EOF
log "Autocmds configuration written to $AUTOCMDS_FILE"

log "--- Installing jq ---"
log "Checking if jq is available..."
if ! command -v jq &>/dev/null; then
  log "jq not found. Attempting to install..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y jq || log "WARNING: Failed to install jq via apt-get."
  else
    log "WARNING: No supported package manager found. Please install jq manually: sudo apt-get install jq"
  fi
  if command -v jq &>/dev/null; then
    log "✅ jq successfully installed: $(jq --version)"
  else
    log "⚠️  jq installation may have failed. JSON auto-formatting will be disabled."
  fi
else
  log "✅ jq is already available: $(jq --version)"
fi

INIT_FILE="$nvim_config_dir/init.lua"
mkdir -p "$(dirname "$INIT_FILE")"
if [ ! -f "$INIT_FILE" ]; then
  tee "$INIT_FILE" >/dev/null <<EOF
-- Load config globals
require("config")

-- Load custom options
require("config.options")

-- Then bootstrap LazyVim
require("config.lazy")
EOF
  log "Created new init.lua."
else
  grep -q 'require("config.options")' "$INIT_FILE" || sed -i '/require("config.lazy")/i require("config.options")' "$INIT_FILE"
  grep -q 'require("config")' "$INIT_FILE" || sed -i '1irequire("config")' "$INIT_FILE"
  log "Updated existing init.lua to require config and options."
fi

log "✅ Neovim + LazyVim setup complete."

# -----------------------------------------------------------------------------
# 🧩 Install Node.js and markdownlint-cli2 using NVM
# -----------------------------------------------------------------------------

log "--- Node.js and npm Tools ---"
log "Installing NVM and Node.js for user $USER."

nvm_dir="$HOME/.nvm"
nvm_install_script="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"

if [ ! -d "$nvm_dir" ]; then
  log "NVM not found. Installing..."
  curl -o- "$nvm_install_script" | bash || log "WARNING: Failed to install NVM."
else
  log "NVM already installed. Skipping."
fi

log "Installing Node.js LTS and markdownlint-cli2..."

bash -c "
  export NVM_DIR=\"$nvm_dir\"
  [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  npm install -g markdownlint-cli2
" || log "WARNING: Failed to complete Node.js setup."

log "✅ Node.js and markdownlint-cli2 setup complete."
