#!/bin/bash

# Uninstall k3s
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  sudo /usr/local/bin/k3s-uninstall.sh
else
  echo "k3s uninstall script not found. k3s may not be installed."
fi

# Verify uninstallation
if ! command -v k3s &> /dev/null; then
  echo "k3s successfully uninstalled."
else
  echo "k3s uninstallation failed."
fi

# Optional: Additional cleanup
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /var/lib/kubelet
sudo rm -rf /etc/systemd/system/k3s.service
sudo rm -rf /etc/systemd/system/k3s.service.env