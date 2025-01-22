#!/bin/bash

#install k3s
curl -sfL https://get.k3s.io | sh -s - server --node-ip 192.168.56.110


#in the subject they use a shortuct for kubectl 
echo "alias k='kubectl'" >> /home/vagrant/.bashrc

#run the deployment manifest files to get our pods working
cd /tmp/deployment
kubectl apply -f .

# wait a little bit , to make sure the pods are running
sleep 5

#run the services manifest files so we can access to the working pods
cd /tmp/services
kubectl apply -f .

sleep 3

# now i need to run ingress to route these running services
cd /tmp/ingress
kubectl apply -f ingress-config.yaml






####### ALL THE NEDDED OBJECT RUNNING NOW #############
####### NB: you can use the kube cli to run those object without creating yaml file , if you want ###############