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

# Update the packages
print_header "Updating Packages"
sudo apt-get update && sudo apt-get upgrade -y & show_wait_animation || handle_error "Failed to update packages"

# Install Docker
print_header "Installing Docker"
if command -v docker &> /dev/null; then
  info "Docker is already installed"
else
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh -y & show_wait_animation || handle_error "Failed to install Docker"
fi


# Create namespaces
print_header "Creating Namespaces"
kubectl create namespace dev & show_wait_animation || handle_error "Failed to create namespace 'dev'"
kubectl create namespace argocd & show_wait_animation || handle_error "Failed to create namespace 'argocd'"

# Install ArgoCD
print_header "Installing ArgoCD"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml & show_wait_animation || handle_error "Failed to install ArgoCD"

# Wait for ArgoCD pods to be ready
print_header "Waiting for ArgoCD Pods to be Ready"
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s & show_wait_animation || handle_error "ArgoCD pods did not become ready in time"

# Expose ArgoCD server port
print_header "Exposing ArgoCD Server Port"
kubectl port-forward svc/argocd-server --address 0.0.0.0 8070:80 -n argocd &
echo -e "${GREEN}ArgoCD is accessible at http://localhost:8070${RESET}"

##### Download ArgoCD CLI #########
print_header "Downloading ArgoCD CLI"
wget https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -O argocd & show_wait_animation || handle_error "Failed to download ArgoCD CLI"
#### make it accesible within your system ####
chmod +x argocd
sudo mv argocd /usr/local/bin/

print_header "Logging in to ArgoCD"
######## those vars will help me to login on argocd #########
sudo echo "ARGOCD_SERVER='localhost:8070'" >> ~/.bashrc
sudo echo "ARGOCD_USERNAME='admin'" >> ~/.bashrc
source ~/.bashrc
############ login now #######
argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME  \
  --password $(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d) \
  --insecure || handle_error "Failed to login to ArgoCD"

print_header "Creating ArgoCD Application"
###### change the namespace to where argocd live #######
sudo kubectl config set-context --current --namespace=argocd
####### now apply yaml file that will responsible for deploying the app from git repo to dev namespace ########
sudo kubectl apply  -f ./application.yml & show_wait_animation || handle_error "Failed to create ArgoCD application"


print_header "Installation Complete"


##### NB: there is another approach using argo cli to add the repo and the place where should be deployed , 
    ####  from the subject seemed they prefer declarative way , and in real life it is the best practice
    #### thank you for reading until here , see ya