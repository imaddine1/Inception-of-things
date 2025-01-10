#!/bin/bash

#install k3s
curl -sfL https://get.k3s.io | sh -s - server --node-ip 192.168.56.110


#install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

#install gitlab using helm
sudo helm repo add gitlab http://charts.gitlab.io/
sudo helm install  my-gitlab gitlab/gitl#!/bin/bash

#install k3s
curl -sfL https://get.k3s.io | sh -s - server --node-ip 192.168.56.110


#install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

#install gitlab using helm
sudo helm repo add gitlab http://charts.gitlab.io/
sudo helm repo update
sudo helm upgrade  --install  my-gitlab gitlab/gitlab --create-namespace  --namespace gitlab \
    --kubeconfig /etc/rancher/k3s/k3s.yaml \
    -f ./values.yml \
    --timeout 800s

# wait until the webservice is ready
sudo kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab

# get the password
sudo kubectl get secret my-gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode



