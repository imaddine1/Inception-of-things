#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Function to print a header
print_header() {
  echo -e "${BLUE}========================================${RESET}"
  echo -e "${BLUE}$1${RESET}"
  echo -e "${BLUE}========================================${RESET}"
}

# Function to handle errors
handle_error() {
  echo -e "${RED}Error: $1${RESET}"
  exit 1
}

# Function to print informational messages
info() {
  echo -e "${YELLOW}Info: $1${RESET}"
}


#Update the system
print_header "Updating the system"
sudo apt update -y && sudo apt upgrade -y || handle_error "Failed to update the system"
# Check if curl is installed
print_header "Checking if curl is installed"
command -v curl
if [ $? -eq 0 ]; then
  info "curl is already installed"
else
  sudo apt install curl -y || handle_error "Failed to install curl"
fi

# Install k3s
print_header "Checking if k3s is installed"
command -v k3s
if [ $? -eq 0 ]; then
  info "k3s is already installed"
else
  curl -sfL https://get.k3s.io | sh -s - --flannel-iface eth1 || handle_error "Failed to install k3s"
fi

# Add alias for kubectl
print_header "Adding alias for kubectl"
echo "alias k='kubectl'" >> ~/.bashrc
source ~/.bashrc

# Apply deployment manifests
print_header "Applying deployment manifests"
cd /tmp/deployment || handle_error "Directory /tmp/deployment not found"
sudo kubectl apply -f . || handle_error "Failed to apply deployment manifests"

# Wait for all pods to be in running state
print_header "Waiting for all pods to be in running state"
sleep 10s ; sudo kubectl wait --for=condition=Ready pods --all --timeout=300s || handle_error "Not all pods are in running state"


# if [ $? -eq 0 ]; then
#   info "All pods are in running state"
# else
#   handle_error "Not all pods are in running state"
# fi

# Apply service manifests
print_header "Applying service manifests"
cd /tmp/services || handle_error "Directory /tmp/services not found"
sudo kubectl apply -f . || handle_error "Failed to apply service manifests"

# Wait for all services to be in running state
print_header "Waiting for all services to be in running state"
sudo  kubectl wait --for=jsonpath='{.spec.selector.app}' -f /tmp/services/ --timeout=300s || handle_error "Not all services are in running state"


print_header "Applying ingress manifests"
cd /tmp/ingress || handle_error "Directory /tmp/ingress not found"
sudo kubectl apply -f . || handle_error "Failed to apply ingress manifests"

print_header "Script Complete"
echo -e "${GREEN}All manifests have been successfully applied${RESET}"
echo -e "${GREEN} You can Access The website by visiting ${YELLOW}http://192.168.56.110${RESET}"
echo -e "${GREEN} The Port IS BELOW "
var=$(sudo kubectl get svc -n kube-system --kubeconfig /etc/rancher/k3s/k3s.yaml)
echo -e "${GREEN} $var ${RESET}"

# Just TO remember my self that If i want to use the ip of the machine 192.168.56.110 the port is in the above command
