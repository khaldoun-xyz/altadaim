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

# Function to install Flatpak packages
install_flatpak_package() {
  local package_name="$1"
  echo "Installing Flatpak package: $package_name"
  if ! flatpak list | grep -q "$package_name"; then
    su - "$ORIGINAL_USER" -c "flatpak install -y flathub '$package_name'" || error_exit "Failed to install Flatpak package $package_name."
  else
    echo "$package_name is already installed. Skipping installation."
  fi
}

# Function to install VS Code extension with retries
install_vscode_extension() {
  local extension="$1"
  local max_retries=3
  local retry_count=0
  local success=false

  echo "Installing VS Code extension: $extension"

  while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
    retry_count=$((retry_count + 1))
    echo "Attempt $retry_count/$max_retries for extension: $extension"

    # Capture output for debugging
    local output
    # Set up proper environment for GUI applications
    output=$(su - "$ORIGINAL_USER" -c "
      export DISPLAY=\${DISPLAY:-:0}
      export DBUS_SESSION_BUS_ADDRESS=\${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/\$(id -u)/bus}
      export XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/\$(id -u)}
      flatpak run com.visualstudio.code --install-extension '$extension'
    " 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
      success=true
      echo "Successfully installed extension: $extension"
      echo "Output: $output"
    else
      echo "Failed attempt $retry_count. Exit code: $exit_code"
      echo "Error output: $output"
      if [ $retry_count -lt $max_retries ]; then
        echo "Waiting 10 seconds before retry..."
        sleep 10
      else
        echo "Failed to install extension after $max_retries attempts: $extension"
      fi
    fi
  done
}

# Install VS Code via Flatpak
install_flatpak_package "com.visualstudio.code" # VS Code

# Initialize VS Code by launching it once and waiting for it to create its initial configuration
echo "Initializing VS Code..."
echo "Starting VS Code for the first time to initialize configuration..."

# Get the user's UID for proper environment setup
USER_UID=$(id -u "$ORIGINAL_USER")

# Start VS Code with proper environment variables
su - "$ORIGINAL_USER" -c "
  export DISPLAY=\${DISPLAY:-:0}
  export DBUS_SESSION_BUS_ADDRESS=\${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$USER_UID/bus}
  export XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$USER_UID}
  
  # Create a temporary file and start VS Code with it
  echo 'VS Code initialization' > /tmp/vscode_init_temp.txt
  timeout 30 flatpak run com.visualstudio.code --new-window --wait /tmp/vscode_init_temp.txt 2>/dev/null || true
  rm -f /tmp/vscode_init_temp.txt
"

echo "Waiting for VS Code initialization to complete..."
sleep 10

# Ensure the extensions directory exists
su - "$ORIGINAL_USER" -c "mkdir -p ~/.vscode/extensions" 2>/dev/null || true

# Check if VS Code is properly initialized by testing a simple command
echo "Testing VS Code initialization..."
if su - "$ORIGINAL_USER" -c "
  export DISPLAY=\${DISPLAY:-:0}
  export DBUS_SESSION_BUS_ADDRESS=\${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$USER_UID/bus}
  export XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$USER_UID}
  flatpak run com.visualstudio.code --list-extensions
" >/dev/null 2>&1; then
  echo "VS Code initialization successful"
else
  echo "VS Code may not be fully initialized, but continuing..."
fi

# Install VS Code extensions with retry logic
echo "Installing VS Code extensions..."

# List of extensions to install
extensions=(
  "eamodio.gitlens"
  "ms-python.python"
  "charliermarsh.ruff"
  "Meezilla.json"
  "mechatroner.rainbow-csv"
)

# Install each extension
for extension in "${extensions[@]}"; do
  install_vscode_extension "$extension"
done

# Create a sample JSON file with schema for color themes
echo "Creating Imeen's theme JSON configuration files..."
su - "$ORIGINAL_USER" -c "
  mkdir -p ~/.vscode/themes
 cat > ~/.vscode/themes/imene-theme.json << 'EOF'
{
  \"\$schema\": \"vscode://schemas/color-theme\",
  \"type\": \"hcDark\",
  \"name\": \"Sample High Contrast Dark Theme\",
  \"colors\": {
    \"editor.background\": \"#000000\",
    \"editor.foreground\": \"#FFFFFF\",
    \"activityBar.background\": \"#000000\",
    \"activityBar.foreground\": \"#FFFFFF\"
  },
  \"tokenColors\": [
    {
      \"scope\": \"comment\",
      \"settings\": {
        \"foreground\": \"#7CA668\",
        \"fontStyle\": \"italic\"
      }
    }
  ]
}
EOF
"

# Configure VS Code settings for JSON formatting
echo "Configuring VS Code settings for JSON formatting..."
su - "$ORIGINAL_USER" -c "
  mkdir -p ~/.config/Code/User
  cat > ~/.config/Code/User/settings.json << 'EOF'
{
  \"json.schemas\": [
    {
      \"fileMatch\": [\"*theme*.json\"],
      \"url\": \"vscode://schemas/color-theme\"
    }
  ],
  \"editor.formatOnSave\": true,
  \"editor.defaultFormatter\": \"esbenp.prettier-vscode\",
  \"[json]\": {
    \"editor.defaultFormatter\": \"ms-vscode.vscode-json\"
  },
  \"json.format.enable\": true,
  \"prettier.tabWidth\": 2,
  \"prettier.useTabs\": false
}
EOF
"

echo "✅ VS Code installation and setup complete"
echo "📝 Imene's theme file created at: ~/.vscode/themes/imene-theme.json"
