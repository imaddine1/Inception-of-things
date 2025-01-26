#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

#Devine Vars
CONFIG="--kubeconfig ./kubeconfig.yml"

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

# Function to show a loading animation
show_loading() {
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

####### Update the packages first ########
print_header "Updating Packages"
sudo apt-get update && sudo apt-get

###### install docker then k3d it depend on it ##########
print_header "Installing Docker"
if command -v docker &> /dev/null; then
  info "Docker is already installed"
else
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install docker-ce  containerd.io -y & show_loading || handle_error "Failed to install Docker"

fi



####### Install k3d #######
print_header "Installing k3d"
if command -v k3d &> /dev/null; then
  info "k3d is already installed"
else
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash & show_loading || handle_error "Failed to install k3d"
fi


######## install now the kubectl so you can create your own namespaces and some others stuff ###########
print_header "Installing kubectl"
if command -v kubectl &> /dev/null; then
  info "kubectl is already installed"
else
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" & show_loading || handle_error "Failed to install kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi





####### we are ready to implement the requirement from the subject #######
######### first of all create a cluster that will wrap your resources #########
print_header "Creating k3d Cluster"
k3d cluster create imad
########## Creating kubeconfig file for kubectl #########
print_header "Creating kubeconfig File >> ~/.bashrc"
touch ./kubeconfig.yml
sudo k3d kubeconfig get -a > ./kubeconfig.yml || handle_error "Failed to create kubeconfig file"
info "THIS THE FILE THAT MAKE KUBECTL WORK : ${GREEN}./kubeconfig.yml"
########## create two namespcaces ###############
print_header "Creating Namespaces Dev and ArgoCD"
sudo kubectl get namespace dev $CONFIG || sudo kubectl create namespace dev $CONFIG  || handle_error "Failed to create namespace 'dev'"
sudo kubectl get namespace argocd $CONFIG  || sudo kubectl create namespace argocd $CONFIG || handle_error "Failed to create namespace 'argocd'" 
####### now we are ready to install argoCD ###############
print_header "Installing ArgoCD"

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml $CONFIG || handle_error "Failed to apply ArgoCD on k3d cluster"
########### we add this step to make sure the pods are running ##########
kubectl wait --for=condition=Ready pods --all -n argocd $CONFIG--timeout=300s & show_loading 
info "Pods of argocd are running now !!!"

####  now we are just hoping that argocd running well ########
####  expose port of argocd , for accessing the UI #######
print_header "Exposing ArgoCD Server Port : 8060"
curl -s -o /dev/null localhost:8060
if [ $? -eq 0 ]; then
info "ArgoCD is already running on port 8060" 
else
  kubectl port-forward svc/argocd-server --address 0.0.0.0 8060:80 $CONFIG -n argocd& 
fi

 echo -e "${GREEN}ArgoCD is running on port 8060${RESET}"
  echo -e "${GREEN}UserName is : admin ${RESET}"
  echo -e "${GREEN}Password is : $(kubectl get secret argocd-initial-admin-secret $CONFIG -n argocd -o jsonpath="{.data.password}" | base64 --decode) ${RESET}"

####### now apply yaml file that will responsible for deploying the app from git repo to dev namespace ########
print_header "Make Argocd Watching the Repo"
kubectl apply -f ./confs/application.yaml  $CONFIG -n argocd  || handle_error "Failed to apply application.yaml"

##### check is service running well ######
kubectl get svc -n dev $CONFIG | grep 'my-app-service' || handle_error "Service is not running well"


######### expose the service to access the app ########
kubectl port-forward svc/my-app-service 8061:80 --address 0.0.0.0  $CONFIG -n dev


print_header "ALL DONE"

