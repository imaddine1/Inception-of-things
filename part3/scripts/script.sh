

####### update the packages first ########
sudo apt-get update
sudo apt-get upgrade -y

###### install docker then k3d it depend on it ##########
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh -y

###### make the docker work without sudo ##########
sudo groupadd docker
sudo usermod -aG docker $USER
sudo newgrp docker

########## creating kubeconfig file , for kubectl #########
sudo mkdir -p ~/.kube
sudo touch ~/.kube/config

####### now it's the time for installing k3d #######
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

######## install now the kubectl so you can namespaces and some others stuff ###########
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


####### we are ready to implement the requirement from the subject #######
    ######### first of all create a cluster that will wrap your resources #########
        k3d cluster create iharile
    ###### insert config of k3d to the kubectl in the host #######
        k3d kubeconfig get -a > ~/.kube/config
    ########## create two namespcaces ###############
        kubectl create namespace dev
        kubectl create namespace argocd # the last created namespace is the current-context or you can switch to it , if you write it in the first command
    ####### now we are ready to install argoCD ###############
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 
    ########### we add this step to make sure the pods are running ##########
    kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s
    ####  now we are just hoping that argocd running well ########
    ####  expose port of argocd , for accessing the ui of it #######
    kubectl port-forward svc/argocd-server 8070:80 -n argocd&
    ##### downloading the agrocd UI #########
    wget https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -O argocd
    #### make it accesible within your system ####
    chmod +x argocd
    sudo mv argocd /usr/local/bin/
    ######## those vars will help me to login on argocd #########
    ARGOCD_SERVER='localhost:8070'
    ARGOCD_USERNAME='admin'
    argocd admin initial-password -n argocd | head -n 1 > sec.txt 
    ARGOCD_PASSWORD=$(cat sec.txt)
    ############ login now #######
    argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure
    ###### change the namespace to where argocd live #######
    kubectl config set-context --current --namespace=argocd
    ####### now apply yaml file that will responsible for deploying the app from git repo to dev namespace ########
    kubectl apply  -f ../confs/application.yaml

##### NB: there is another approach using argo cli to add the repo and the place where should be deployed , 
    ####  from the subject seemed they prefer declarative way , and in real life it is the best practice
    #### thank you for reading until here , see ya
    
