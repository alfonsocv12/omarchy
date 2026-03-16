#!/bin/bash

# Install Limine bootloader on Debian using the official binary release from Codeberg.
# Binary releases ship ready-to-use on the v*-binary branches — no full toolchain needed.

if command -v limine &>/dev/null; then
  echo "Limine is already installed, skipping."
  exit 0
fi

echo "Installing Limine bootloader..."

# Build dependencies: only make + gcc needed to compile the host utility from the binary branch
omarchy-pkg-add git make gcc

# Clone the latest binary release (no source build of the full bootloader required)
LIMINE_DIR=$(mktemp -d /tmp/limine-XXXXXX)
git clone --depth=1 --branch=v9.x-binary \
  https://codeberg.org/Limine/Limine.git "$LIMINE_DIR"

pushd "$LIMINE_DIR" > /dev/null

# Build the host utility (limine bios-install etc.) from the binary release
make

# Install everything into /usr/local (binary → /usr/local/bin, data → /usr/local/share/limine)
sudo make install

popd > /dev/null
rm -rf "$LIMINE_DIR"

# Verify host utility is available
if ! command -v limine &>/dev/null; then
  echo "Error: Limine host utility not found after install" >&2
  exit 1
fi

# UEFI: copy the EFI application to the standard EFI/BOOT location on the ESP
EFI_SRC=/usr/local/share/limine/BOOTX64.EFI
if [[ -f $EFI_SRC ]]; then
  sudo mkdir -p /boot/EFI/BOOT
  sudo cp -v "$EFI_SRC" /boot/EFI/BOOT/BOOTX64.EFI
  # Also keep a copy in /boot/EFI/limine/ for our own efibootmgr entry
  sudo mkdir -p /boot/EFI/limine
  sudo cp -v "$EFI_SRC" /boot/EFI/limine/BOOTX64.EFI
fi

# BIOS: limine-bios.sys (Stage 3) must be present BEFORE bios-install is run.
# Limine searches for it in these directories on the boot partition:
#   /boot/limine, /boot, /limine, or root directory.
# We copy it to all likely locations to be safe.
BIOS_SYS=/usr/local/share/limine/limine-bios.sys
if [[ -f $BIOS_SYS ]]; then
  sudo mkdir -p /boot/limine
  sudo cp -v "$BIOS_SYS" /boot/limine/limine-bios.sys
  sudo cp -v "$BIOS_SYS" /boot/limine-bios.sys
fi

# Place a minimal limine.conf at /boot/limine.conf if not already there
# (limine-snapper.sh will overwrite this with the full Omarchy config later)
if [[ ! -f /boot/limine.conf ]]; then
  sudo tee /boot/limine.conf > /dev/null <<'EOF'
# Temporary minimal config — will be replaced by limine-snapper.sh
timeout: 3
default_entry: 1

/
  protocol: linux
  kernel_path: boot:///vmlinuz
  cmdline: root=auto quiet splash audit=0 loglevel=3
  module_path: boot:///initrd.img
EOF
fi

# Write Limine into the MBR/VBR of the boot disk
ROOT_DISK=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" 2>/dev/null | head -1)
if [[ -n $ROOT_DISK ]]; then
  echo "Running limine bios-install on /dev/$ROOT_DISK"
  sudo limine bios-install "/dev/$ROOT_DISK"
else
  echo "Warning: could not determine root disk for BIOS install" >&2
fi

echo "Limine installed successfully."
