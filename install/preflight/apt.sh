if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  omarchy-pkg-add build-essential

  # Configure apt
  sudo apt-get update
  sudo apt-get full-upgrade -y
fi
