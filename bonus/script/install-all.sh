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

# Function to show a loading bar animation
show_loading_bar() {
  local pid=$!
  local delay=0.1
  local progress=0
  local bar_length=50
  echo -n "["
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    progress=$(( (progress + 1) % (bar_length + 1) ))
    printf "\r["
    for ((i=0; i<progress; i++)); do
      printf "#"
    done
    for ((i=progress; i<bar_length; i++)); do
      printf " "
    done
    printf "]"
    sleep $delay
  done
  echo -e "]"
}

# Function to run a script and display completion message
run_script() {
  local script_name=$1
  print_header "Running $script_name"
  bash $script_name || (handle_error "Failed to run $script_name" )
  clear
  echo -e "${GREEN}$script_name installation is complete${RESET}"
}

# Run the individual scripts
run_script "install-gitlab.sh"
read -p "Please enter the repository URL: " repo_url
info "Cloning repository from $repo_url"
export REPO_URL="$repo_url"
run_script "install-argocd.sh"

print_header "All Installations Complete"

curl -s -o /dev/null localhost:8888
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Gitlab is running on port 8080${RESET}"
  echo -e "${GREEN}UserName is : root ${RESET}"
  echo -e "${GREEN}Password is : ${sudo kubectl get secret my-gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode} ${RESET}"
else
  echo -e "${RED}Gitlab is not running on port 8888${RESET}"
fi

curl -s -o /dev/null localhost:8070
if [ $? -eq 0 ]; then
  echo -e "${GREEN}ArgoCD is running on port 8070${RESET}"
  echo -e "${GREEN}UserName is : admin ${RESET}"
  echo -e "${GREEN}Password is : ${sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode} ${RESET}"
else
  echo -e "${RED}ArgoCD is not running on port 8070${RESET}"
fi

print_header "All Installations Complete"
echo -e "${GREEN}All scripts have been successfully installed${RESET}"