#!/bin/bash

# Install uwsm (Universal Wayland Session Manager) on Debian.
# uwsm is a Python-based tool needed to wrap Wayland app launches in systemd
# user services, used heavily in Omarchy's Hyprland bindings and autostart.
# Not available in standard Debian apt repos.

if command -v uwsm &>/dev/null; then
  echo "uwsm is already installed, skipping."
  exit 0
fi

echo "Installing uwsm..."

# Ensure pip and pipx are available
omarchy-pkg-add python3-pip python3-venv pipx

# Install via pipx so it's available system-wide without virtualenv conflicts
pipx install uwsm --global 2>/dev/null || \
  sudo pipx install uwsm --global 2>/dev/null || \
  pip3 install --user uwsm

# If pipx put it in ~/.local/bin, ensure that's on PATH
if [[ ! -x /usr/local/bin/uwsm ]] && [[ -x "$HOME/.local/bin/uwsm" ]]; then
  sudo ln -sf "$HOME/.local/bin/uwsm" /usr/local/bin/uwsm
fi

# Create the uwsm-app wrapper if it's not already provided
if ! command -v uwsm-app &>/dev/null; then
  sudo tee /usr/local/bin/uwsm-app > /dev/null <<'EOF'
#!/bin/bash
# Wrapper: launch apps via uwsm if session is managed, otherwise exec directly
if command -v uwsm &>/dev/null && uwsm check-is-managed-session 2>/dev/null; then
  exec uwsm app -- "$@"
else
  exec "$@"
fi
EOF
  sudo chmod +x /usr/local/bin/uwsm-app
fi

if ! command -v uwsm-app &>/dev/null; then
  echo "Error: uwsm-app not available after install" >&2
  exit 1
fi

echo "uwsm installed successfully."
