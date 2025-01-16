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


# Create namespaces
print_header "Creating Namespaces"
sudo kubectl get namespace dev || sudo kubectl create namespace dev || handle_error "Failed to create namespace 'dev'"
sudo kubectl get namespace argocd || sudo kubectl create namespace argocd || handle_error "Failed to create namespace 'argocd'"

# Install ArgoCD
print_header "Installing ArgoCD"
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml & show_wait_animation || handle_error "Failed to install ArgoCD"

# Wait for ArgoCD pods to be ready
print_header "Waiting for ArgoCD Pods to be Ready"
sudo kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s & show_wait_animation || handle_error "ArgoCD pods did not become ready in time"

# Expose ArgoCD server port
print_header "Exposing ArgoCD Server Port"
sudo curl localhost:8070
if [ $? -eq 0 ]; then
  info "ArgoCD Server port is already exposed"
else
  sudo kubectl port-forward svc/argocd-server --address 0.0.0.0 8070:80 -n argocd &
fi
echo -e "${GREEN}ArgoCD is accessible at http://localhost:8070${RESET}"

##### Download ArgoCD CLI #########
print_header "Downloading ArgoCD CLI"
if ls /usr/local/bin/argocd &> /dev/null; then
  info "ArgoCD CLI is already installed"
else
  print_header "Start Downloading ArgoCD CLI"
  sudo wget https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -O argocd & show_wait_animation || handle_error "Failed to download ArgoCD CLI"
  sudo chmod +x argocd
  sudo mv argocd /usr/local/bin/
fi


print_header "Logging to ArgoCD"

############ login now #######
argocd login 127.0.0.1:8070 --username admin --password $(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d) --insecure

#### Check if the login is successful or not ####
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully logged in to ArgoCD${RESET}"
else
  handle_error "Failed to login to ArgoCD"
fi

print_header "Creating ArgoCD Application"
####### now apply yaml file that will responsible for deploying the app from git repo to dev namespace ########
sudo kubectl apply  -f /confs/application.yml -n argocd  || handle_error "Failed to create ArgoCD application"

print_header "Installation Complete"

##### NB: there is another approach using argo cli to add the repo and the place where should be deployed , 
    ####  from the subject seemed they prefer declarative way , and in real life it is the best practice
    #### thank you for reading until here , see ya