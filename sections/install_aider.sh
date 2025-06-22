#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
pipx install aider-install || echo "WARNING: Failed to install aider-install with pipx. Check internet connection or pipx issues."
aider-install || echo "WARNING: Failed to run aider-install."
echo "✅Aider installed"
