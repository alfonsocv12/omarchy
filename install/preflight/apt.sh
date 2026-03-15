if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  omarchy-pkg-add build-essential

  # Configure apt
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
fi
