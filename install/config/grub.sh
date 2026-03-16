#!/bin/bash

# Fix kernel parameters in GRUB to suppress kauditd TTY spam on Debian.
# The sed approach is fragile; we use python3 to safely parse and update the file.

if [[ ! -f /etc/default/grub ]]; then
  echo "GRUB not found at /etc/default/grub, skipping."
  exit 0
fi

# Add audit=0 and loglevel=3 to GRUB_CMDLINE_LINUX_DEFAULT if not already set
sudo python3 - /etc/default/grub <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

def add_params(line):
    # Extract current value between the quotes
    m = re.match(r'^(GRUB_CMDLINE_LINUX_DEFAULT=")([^"]*)(")$', line)
    if not m:
        return line
    prefix, value, suffix = m.groups()
    params = value.split()
    for param in ["audit=0", "loglevel=3"]:
        key = param.split("=")[0]
        # Remove any existing setting of this key
        params = [p for p in params if not p.startswith(key + "=") and p != key]
        params.append(param)
    return prefix + " ".join(params) + suffix

new_lines = [add_params(l.rstrip()) if l.startswith("GRUB_CMDLINE_LINUX_DEFAULT=") else l.rstrip() for l in content.splitlines()]
with open(path, "w") as f:
    f.write("\n".join(new_lines) + "\n")
print("Updated GRUB_CMDLINE_LINUX_DEFAULT with audit=0 loglevel=3")
PYEOF

sudo update-grub
