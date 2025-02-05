#!/bin/bash

# Update and upgrade packages
echo "Updating and upgrading packages..."
sudo apt-get update && sudo apt-get upgrade -y
# Install curl
echo "Installing curl..."
sudo apt-get install -y curl

# Set up DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# Wait for the token file with a timeout of 60 seconds
TOKEN_FILE="/vagrant/node-token"
TIMEOUT=600
WAIT_INTERVAL=5
WAIT_TIME=0

while [ ! -f "$TOKEN_FILE" ]; do
  if [ "$WAIT_TIME" -ge "$TIMEOUT" ]; then
    echo "Timeout waiting for token file from Server."
    exit 1
  fi
  echo "Waiting for token file from Server..."
  sleep "$WAIT_INTERVAL"
  WAIT_TIME=$((WAIT_TIME + WAIT_INTERVAL))
done

# Read the token
TOKEN=$(cat "$TOKEN_FILE")

# Join the worker to the cluster
if ! command -v k3s-agent &> /dev/null; then
  echo "Joining the cluster..."
  curl -sfL https://get.k3s.io  | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN sh -s -  --flannel-iface eth1
else
  echo "K3s-agent is already installed."
fi

