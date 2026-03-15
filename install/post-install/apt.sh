# Configure apt
# No default post-install apt config replacing is necessary for Debian in Omarchy so far.

if lspci -nn | grep -q "106b:180[12]"; then
  echo "Mac T2 hardware detected. Ensure Debian T2 kernel/modules are installed manually if needed."
fi
