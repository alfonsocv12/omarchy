if command -v limine &>/dev/null; then
  # Detect boot mode
  [[ -d /sys/firmware/efi ]] && EFI=true

  # Find config location
  if [[ -f /boot/EFI/limine/limine.conf ]]; then
    limine_config="/boot/EFI/limine/limine.conf"
  elif [[ -f /boot/EFI/BOOT/limine.conf ]]; then
    limine_config="/boot/EFI/BOOT/limine.conf"
  elif [[ -f /boot/limine/limine.conf ]]; then
    limine_config="/boot/limine/limine.conf"
  elif [[ -f /boot/limine.conf ]]; then
    limine_config="/boot/limine.conf"
  else
    echo "No existing Limine config found, will create a fresh one."
    limine_config=""
  fi

  CMDLINE=""
  if [[ -n $limine_config ]]; then
    CMDLINE=$(grep "^[[:space:]]*cmdline:" "$limine_config" | head -1 | sed 's/^[[:space:]]*cmdline:[[:space:]]*//')
  fi

  # Ensure the default base cmdline includes audit=0 to suppress kauditd TTY spam
  if [[ -z $CMDLINE ]]; then
    CMDLINE="quiet splash audit=0 loglevel=3"
  elif [[ $CMDLINE != *audit=0* ]]; then
    CMDLINE="$CMDLINE audit=0 loglevel=3"
  fi

  sudo cp $OMARCHY_PATH/default/limine/default.conf /etc/default/limine
  sudo sed -i "s|@@CMDLINE@@|$CMDLINE|g" /etc/default/limine

  # Append any drop-in kernel cmdline configs (from hardware fix scripts, etc.)
  for dropin in /etc/limine-entry-tool.d/*.conf; do
    [ -f "$dropin" ] && cat "$dropin" | sudo tee -a /etc/default/limine > /dev/null
  done

  # UKI and EFI fallback are EFI only
  if [[ -z $EFI ]]; then
    sudo sed -i '/^ENABLE_UKI=/d; /^ENABLE_LIMINE_FALLBACK=/d' /etc/default/limine
  fi

  # Install Limine EFI and set up boot entry
  if [[ -n $EFI ]]; then
    sudo mkdir -p /boot/EFI/limine
    sudo limine bios-install /boot 2>/dev/null || true
    sudo cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI 2>/dev/null || \
      sudo cp /usr/share/limine/limine-uefi-cd.bin /boot/EFI/limine/BOOTX64.EFI 2>/dev/null || true
    if command -v efibootmgr &>/dev/null; then
      # Add a new Limine EFI entry if not already present
      if ! efibootmgr | grep -qi "limine"; then
        local disk
        disk=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//')
        local part
        part=$(findmnt -n -o SOURCE / | grep -o '[0-9]*$')
        sudo efibootmgr --create --disk "$disk" --part "$part" \
          --label "Limine" --loader "\\EFI\\limine\\BOOTX64.EFI" > /dev/null 2>&1 || true
      fi
    fi
  fi

  # Write a fresh /boot/limine.conf (limine-update will populate entries)
  sudo cp $OMARCHY_PATH/default/limine/limine.conf /boot/limine.conf
fi

sudo limine-update 2>/dev/null || true

# Verify that limine-update actually added boot entries
if [[ -f /boot/limine.conf ]] && ! grep -q "^/\+" /boot/limine.conf; then
  echo "Warning: limine-update may not have added kernel entries to /boot/limine.conf" >&2
fi
