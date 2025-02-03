#!/bin/bash

# Update and upgrade packages
echo "Updating and upgrading packages..."
sudo apt update && sudo apt upgrade -y
# Install curl
echo "Installing curl..."
sudo apt install -y curl

# Set up DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# Install K3s
if ! command -v k3s &> /dev/null; then
  echo "Installing K3s..."
  curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644 --flannel-iface eth1
else
  echo "K3s is already installed."
fi

# Wait for the token file to be generated ---------------------
TOKEN_PATH="/var/lib/rancher/k3s/server/node-token"
while [ ! -f "$TOKEN_PATH" ]; do
  echo "Waiting for K3s token to be generated..."
  sleep 2
done

# Copy the token to the shared folder ---------------------
cp "$TOKEN_PATH" /vagrant/node-token
echo "K3s token copied to /vagrant/node-token."

# Export kubeconfig for ease of use ---------------------
KUBECONFIG_FILE="/etc/rancher/k3s/k3s.yaml"
if [ -f "$KUBECONFIG_FILE" ]; then
  echo "Setting kubeconfig permissions..."
  sudo chmod 644 "$KUBECONFIG_FILE"
  echo "KUBECONFIG=$KUBECONFIG_FILE" | tee -a ~/.bashrc > /dev/null
  echo "Kubeconfig permissions set and environment variable added."
else
  echo "Kubeconfig file not found!"
fi

# alias kubectl to k ---------------------
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
