# Setup GPG configuration with multiple keyservers for better reliability
sudo mkdir -p /etc/gnupg
sudo cp ~/.local/share/omarchy/default/gpg/dirmngr.conf /etc/gnupg/
sudo chmod 644 /etc/gnupg/dirmngr.conf
sudo gpgconf --kill dirmngr || true
sudo gpgconf --launch dirmngr || true

# Ensure gpg-agent has a valid pinentry program configured (Debian may not have one by default)
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"
if [[ -x /usr/bin/pinentry-curses ]]; then
  pinentry_bin=/usr/bin/pinentry-curses
elif [[ -x /usr/bin/pinentry ]]; then
  pinentry_bin=/usr/bin/pinentry
fi

if [[ -n ${pinentry_bin:-} ]]; then
  if ! grep -q "^pinentry-program" "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null; then
    echo "pinentry-program $pinentry_bin" >> "$HOME/.gnupg/gpg-agent.conf"
  else
    sed -i "s|^pinentry-program.*|pinentry-program $pinentry_bin|" "$HOME/.gnupg/gpg-agent.conf"
  fi
fi

gpgconf --kill gpg-agent 2>/dev/null || true
