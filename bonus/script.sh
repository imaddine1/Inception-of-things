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

# Function to show a waiting animation
show_wait_animation() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  echo -n " "
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  echo "    "
}


# Install k3s
print_header "Installing k3s"
if command -v k3s &> /dev/null; then
  info "k3s is already installed"
else
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s || handle_error "Failed to install k3s"
fi

# Install Helm
print_header "Installing Helm"
if command -v helm &> /dev/null; then
  info "Helm is already installed"
else
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null || handle_error "Failed to download Helm signing key"
  sudo apt-get install apt-transport-https --yes || handle_error "Failed to install apt-transport-https"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list || handle_error "Failed to add Helm repository"
  sudo apt-get update || handle_error "Failed to update package list"
  sudo apt-get install helm || handle_error "Failed to install Helm"
fi

# Add GitLab Helm repository
print_header "Adding GitLab Helm Repository"
if helm repo list | grep -q 'gitlab'; then
  info "GitLab Helm repository is already added"
else
  helm repo add gitlab https://charts.gitlab.io/ || handle_error "Failed to add GitLab Helm repository"
fi
sudo helm repo update || handle_error "Failed to update Helm repositories"

# Install or upgrade GitLab using Helm

print_header "Installing or Upgrading GitLab"
sudo helm upgrade --install my-gitlab gitlab/gitlab --create-namespace --namespace gitlab \
  --kubeconfig /etc/rancher/k3s/k3s.yaml \
  -f ./values.yml \
  --timeout 800s 
# Wait until the webservice is ready
print_header "Waiting for GitLab Webservice to be Ready"
(sudo kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab) & show_wait_animation || handle_error "GitLab webservice did not become ready in time"

# Retrieve the initial root password for GitLab
print_header "Retrieving GitLab Initial Root Password"
GITLAB_PASSWORD=$(sudo kubectl get secret my-gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode) || handle_error "Failed to retrieve GitLab initial root password"
echo -e "${GREEN}GITLAB PASSWORD: $GITLAB_PASSWORD${RESET}"

# Port-forward to access GitLab
print_header "Setting Up Port Forwarding to Access GitLab"
if pgrep -f "kubectl port-forward svc/gitlab-webservice-default" > /dev/null; then
  info "Port forwarding is already set up"
else
  sudo kubectl port-forward svc/gitlab-webservice-default -n gitlab 82:8181 2>&1 >/dev/null &
  echo -e "${GREEN}GitLab is accessible at http://localhost:82${RESET}"
fi

print_header "Installation Complete"