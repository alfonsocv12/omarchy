#!/bin/bash

# Suppress kernel audit logs that spam the TTY
if [[ -f /etc/default/grub ]]; then
  if ! grep -q "audit=0" /etc/default/grub; then
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 audit=0"/' /etc/default/grub
    sudo update-grub
  fi
fi
