abort() {
  echo -e "\e[31mOmarchy install requires: $1\e[0m"
  echo
  gum confirm "Proceed anyway on your own accord and without assistance?" || exit 1
}

# Must be a Debian distro
if ! grep -q '^ID=debian$' /etc/os-release 2>/dev/null; then
  abort "Vanilla Debian"
fi

# Must not be running as root
if (( EUID == 0 )); then
  abort "Running as root (not user)"
fi

# Must be x86 only to fully work
if [[ $(uname -m) != "x86_64" ]]; then
  abort "x86_64 CPU"
fi

# Must have secure boot disabled
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
  abort "Secure Boot disabled"
fi

# Must not have Gnome or KDE already install
if dpkg-query -W -f='${Status}' gnome-shell 2>/dev/null | grep -q "ok installed" || dpkg-query -W -f='${Status}' plasma-desktop 2>/dev/null | grep -q "ok installed"; then
  abort "Fresh + Vanilla Debian"
fi

# Must have limine installed
command -v limine &>/dev/null || abort "Limine bootloader"

# Must have btrfs root filesystem
[[ $(findmnt -n -o FSTYPE /) = "btrfs" ]] || abort "Btrfs root filesystem" 

# Cleared all guards
echo "Guards: OK"
