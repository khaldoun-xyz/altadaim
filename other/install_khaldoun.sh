#!/usr/bin/env bash

# --- Error Handling ---

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Exit if any command in a pipeline fails.
set -o pipefail

# Define log file
LOG_FILE="$HOME/khaldoun_setup_$(date +%Y%m%d_%H%M%S).log"

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
  error_exit "This script must be run only after install_altadaim.sh. It must be run as root."
fi

# Store the original user who invoked sudo
# This is crucial for operations that need to run as the regular user (e.g., Git cloning with SSH keys)
ORIGINAL_USER="$SUDO_USER"
if [ -z "$ORIGINAL_USER" ]; then
  error_exit "Could not determine the original user who invoked sudo. Please ensure SUDO_USER is set."
fi
log "Script invoked by user: $ORIGINAL_USER"

setup_python_project_ssh() {
  local repo_ssh_url="$1"
  local project_name="$2"
  local venv_dir="/home/$ORIGINAL_USER/virtualenvs/$project_name"
  local project_dir="/home/$ORIGINAL_USER/programming/$project_name"

  log "Setting up Python project (SSH) for user $ORIGINAL_USER: $project_name from $repo_ssh_url"

  # Clone the repository if it doesn't already exist, as ORIGINAL_USER
  if [ ! -d "$project_dir" ]; then
    sudo -u "$ORIGINAL_USER" git clone "$repo_ssh_url" "$project_dir" || error_exit "Failed to clone $repo_ssh_url via SSH for user $ORIGINAL_USER. Ensure their SSH key is set up with the Git provider (e.g., GitHub)."
  else
    log "Repository $project_name already exists. Skipping clone."
  fi

  # Determine Python version to use from pyproject.toml
  local python_cmd="python3"
  if [ -f "$project_dir/pyproject.toml" ]; then
    # Extract Python version requirement from pyproject.toml
    local python_requirement=$(grep -E "requires-python\s*=\s*" "$project_dir/pyproject.toml" | sed -E 's/.*requires-python\s*=\s*"([^"]+)".*/\1/' | head -1)
    if [ -n "$python_requirement" ]; then
      log "Found Python requirement in pyproject.toml: $python_requirement"
      # Extract major.minor version (e.g., ">=3.12,<3.14" -> "3.12")
      local python_version=$(echo "$python_requirement" | grep -oE "[0-9]+\.[0-9]+" | head -1)
      if [ -n "$python_version" ]; then
        # Try to use the specific version if available
        if command -v "python$python_version" >/dev/null 2>&1; then
          python_cmd="python$python_version"
          log "Using Python $python_version for $project_name (from pyproject.toml)"
        else
          log "WARNING: Python $python_version not found, falling back to python3"
        fi
      fi
    fi
  fi

  # Create the virtual environment if it doesn't already exist, as ORIGINAL_USER
  if [ ! -d "$venv_dir" ]; then
    sudo -u "$ORIGINAL_USER" "$python_cmd" -m venv "$venv_dir" || error_exit "Failed to create virtual environment for $project_name for user $ORIGINAL_USER."
  else
    log "Virtual environment for $project_name already exists. Skipping creation."
  fi

  # Install Python requirements within the virtual environment, as ORIGINAL_USER
  log "Installing Python dependencies for $project_name for user $ORIGINAL_USER."

  # Ensure pip, setuptools, and wheel are up-to-date in the venv
  sudo -u "$ORIGINAL_USER" "$venv_dir/bin/pip" install --upgrade pip setuptools wheel || log "Failed to upgrade pip/setuptools/wheel in $project_name venv for user $ORIGINAL_USER."

  # Check for pyproject.toml first, then fallback to requirements.txt
  if [ -f "$project_dir/pyproject.toml" ]; then
    log "Found pyproject.toml for $project_name. Installing in editable mode."
    sudo -u "$ORIGINAL_USER" bash -c "
      cd \"$project_dir\"
      \"$venv_dir/bin/pip\" install -e .
    " || error_exit "Failed to install $project_name from pyproject.toml for user $ORIGINAL_USER."

    # Also install development dependencies if they exist
    if sudo -u "$ORIGINAL_USER" bash -c "cd \"$project_dir\" && \"$venv_dir/bin/pip\" show tomli >/dev/null 2>&1 || \"$venv_dir/bin/pip\" install tomli >/dev/null 2>&1"; then
      if sudo -u "$ORIGINAL_USER" "$venv_dir/bin/python" -c "
import tomli
with open('$project_dir/pyproject.toml', 'rb') as f:
    data = tomli.load(f)
    optional_deps = data.get('project', {}).get('optional-dependencies', {})
    if 'dev' in optional_deps or 'development' in optional_deps:
        exit(0)
    else:
        exit(1)
" 2>/dev/null; then
        log "Installing development dependencies for $project_name."
        sudo -u "$ORIGINAL_USER" bash -c "
          cd \"$project_dir\"
          \"$venv_dir/bin/pip\" install -e .[dev] 2>/dev/null || \"$venv_dir/bin/pip\" install -e .[development] 2>/dev/null || true
        " || log "WARNING: Could not install development dependencies for $project_name."
      fi
    fi

  elif [ -f "$project_dir/requirements.txt" ]; then
    log "Found requirements.txt for $project_name. Installing from requirements file."
    sudo -u "$ORIGINAL_USER" "$venv_dir/bin/pip" install -r "$project_dir/requirements.txt" || error_exit "Failed to install requirements for $project_name for user $ORIGINAL_USER."
  else
    log "No pyproject.toml or requirements.txt found for $project_name. Skipping dependency installation."
  fi

  # Install pre-commit hooks if .pre-commit-config.yaml exists
  if [ -f "$project_dir/.pre-commit-config.yaml" ]; then
    log "Installing pre-commit hooks for $project_name."
    # First ensure pre-commit is installed
    sudo -u "$ORIGINAL_USER" "$venv_dir/bin/pip" install pre-commit || log "WARNING: Failed to install pre-commit for $project_name."

    sudo -u "$ORIGINAL_USER" bash -c "
      source \"$venv_dir/bin/activate\"
      cd \"$project_dir\"
      pre-commit install
    " || log "WARNING: Failed to install pre-commit hooks for $project_name."
  else
    log "No .pre-commit-config.yaml found in $project_name. Skipping pre-commit install."
  fi

}

log "--- Creating ~/virtualenvs/ and ~/programming/ directories ---"
log "If it doesn't exist yet, creating '~/$ORIGINAL_USER/virtualenvs' and '~/$ORIGINAL_USER/programming' directories for $ORIGINAL_USER."
sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/virtualenvs" || log "WARNING: Directory ~/$ORIGINAL_USER/virtualenvs could not be created."
sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/programming" || log "WARNING: Directory ~/$ORIGINAL_USER/programming could not be created."

log "--- Cloning Khaldoun Projects (via SSH) ---"
log "IMPORTANT: Ensure your SSH keys are set up with GitHub for these repositories for user $ORIGINAL_USER."
declare -A khaldoun_ssh_repos
khaldoun_ssh_repos["altadaim"]="git@github.com:khaldoun-xyz/altadaim.git"
khaldoun_ssh_repos["lugha"]="git@github.com:khaldoun-xyz/lugha.git"
khaldoun_ssh_repos["terminal_llm"]="git@github.com:khaldoun-xyz/terminal_llm.git"
khaldoun_ssh_repos["khaldoun"]="git@github.com:khaldoun-xyz/khaldoun.git"
khaldoun_ssh_repos["core_skills"]="git@github.com:khaldoun-xyz/core_skills.git"
khaldoun_ssh_repos["albeyanat"]="git@github.com:khaldoun-xyz/albeyanat.git"
khaldoun_ssh_repos["tanfidh_mini"]="git@github.com:khaldoun-xyz/tanfidh_mini.git"
khaldoun_ssh_repos["taothif"]="git@github.com:khaldoun-xyz/taothif.git"
khaldoun_ssh_repos["sisu"]="git@github.com:khaldoun-xyz/sisu.git"

for project in "${!khaldoun_ssh_repos[@]}"; do
  setup_python_project_ssh "${khaldoun_ssh_repos[$project]}" "$project"
done

log "Khaldoun projects cloning complete."

log "--- Updating .bashrc with aliases ---"

BASHRC_PATH="/home/$ORIGINAL_USER/.bashrc"
BASHRC_MARKER="# --------------------------- added by khaldoun --------------------------------"

# check if the block already exists
if ! sudo -u "$ORIGINAL_USER" grep -q "$BASHRC_MARKER" "$BASHRC_PATH"; then
  sudo -u "$ORIGINAL_USER" bash -c "cat <<'EOF' >> \"$BASHRC_PATH\"
$BASHRC_MARKER
# add venv aliases
alias altadaim='cd ~/programming/altadaim && . ~/virtualenvs/altadaim/bin/activate'
alias lugha='cd ~/programming/lugha && . ~/virtualenvs/lugha/bin/activate'
alias terminal_llm='cd ~/programming/terminal_llm/src && . ~/virtualenvs/terminal_llm/bin/activate && python chat.py'
alias khaldoun='cd ~/programming/khaldoun && . ~/virtualenvs/khaldoun/bin/activate'
alias albeyanat='cd ~/programming/albeyanat && . ~/virtualenvs/albeyanat/bin/activate'
alias tanfidh_mini='cd ~/programming/tanfidh_mini && . ~/virtualenvs/tanfidh_mini/bin/activate'
alias taothif='cd ~/programming/taothif && . ~/virtualenvs/taothif/bin/activate'
alias sisu='cd ~/programming/sisu && . ~/virtualenvs/sisu/bin/activate'
EOF"
  log ".bashrc updated with khaldoun customization for user $ORIGINAL_USER."
else
  log ".bashrc already contains khaldoun customization. skipping append."
fi
