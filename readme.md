# Your entrance to kubernetes

Hello everybody, I am pleased to demonstrate some aspects of Kubernetes (k8s). First of all, I want to talk about the difference between k3s and k8s. k3s works almost with the same functionalities as k8s. However, k3s is lightweight, consumes fewer resources, and you can run it on low configuration systems.

## Table of Contents
- [Architecture](#architecture)
- [Common terms in the world of k8s](#common-terms-in-the-world-of-k8s)
- [Kubeconfig](#kubeconfig)
- [Labels and Selectors](#labels-and-selector)
- [Pods](#pods)
- [ReplicaSet](#replicaset)
- [Deployment](#deployment)
- [Services](#services)
- [Ingress](#ingress)
- [Namespaces](#namespaces)
- [K3d](#k3d)
- [ArgoCD](#argocd)
- [Deploy GitLab using Helm](#deploy-gitlab-using-helm)

## Architecture

k8s follows a master-worker architecture. The master node is responsible for managing the cluster, while the worker nodes run the applications. The key components of the master node include:

- **API Server**: Exposes the Kubernetes API.
- **etcd**: A key-value store for all cluster data.
- **Controller Manager**: Ensures the desired state of the cluster.
- **Scheduler**: Assigns workloads to nodes.

Worker nodes have the following components:

- **Kubelet**: Ensures containers are running in a Pod.
- **Kube-proxy**: Manages network rules.
- **Container Runtime**: Runs the containers (e.g., Docker, containerd).

This architecture ensures high availability, scalability, and efficient management of containerized applications.

 Differences between k8s and k3s

Here are some key dikubectlfferences between Kubernetes (k8s) and k3s:

- **Resource Consumption**: k3s is designed to be lightweight and consume fewer resources compared to k8s.
- **Installation**: k3s has a simplified installation process, making it easier to set up.
- **Components**: k3s combines several components into a single binary, whereas k8s uses multiple binaries.
- **Use Case**: k3s is ideal for edge computing, IoT, and development environments, while k8s is suited for large-scale production environments.
- **Dependencies**: k3s has fewer dependencies and can run on systems with lower specifications.

These differences make k3s a more suitable option for specific scenarios where resource constraints and simplicity are important.

### Example of k8s Architecture

This is an example of Kubernetes (k8s) architecture. Below is a diagram that illustrates the components of the master node and worker node:

![Kubernetes Architecture](./imgs/k8s-architecture.png)

In our situation, we have installed k3s, which combines both the master and worker components into a single node. This setup retains the same components but is optimized for lightweight and resource-constrained environments.

For a better understanding, you can watch this [video](https://www.youtube.com/watch?v=umXEmn3cMWY).

## Common terms in the world of k8s

Understanding the terminology used in Kubernetes is crucial for navigating and managing a cluster. Here are some common terms you will encounter:

- **Cluster**: A group of machines (nodes) working together to run applications and manage workloads.
- **Node**: A machine in the cluster. It can be a physical server or a virtual machine.
Control Plane or (Master) Node: Manages the cluster (API server, scheduler, etc.).
Worker or (agent) Node: Runs application workloads (pods).
- **Resources**: These are the objects that you manage in Kubernetes, such as Pods, Services, and Deployments.
- **Components**: These refer to the individual parts that make up the Kubernetes system, including the API Server, etcd, Controller Manager, Scheduler, Kubelet, and Kube-proxy.
- **Objects**: A record of a resource, stored in etcd (Kubernetes' database). Common objects.  include Pods, Services, Deployment and ConfigMaps.
- **Abstraction**: A way to simplify complex concepts by hiding details:</br>
Pods abstract containers.</br>
Deployments abstract pod scaling and updates.</br>
Services abstract networking and load balancing.
- **Manifest**: A YAML/JSON file that defines a resource or object.

These terms are fundamental to understanding how Kubernetes operates and how to interact with it effectively.

## Kubeconfig

The `kubeconfig` file is a configuration file used by Kubernetes to manage cluster access. It contains information about clusters, users, namespaces, and authentication mechanisms. This file is essential for the `kubectl` command-line tool to interact with Kubernetes clusters.

### Structure of a Kubeconfig File

A typical `kubeconfig` file is divided into three main sections:

1. **Clusters**: Defines the clusters that `kubectl` can connect to.
2. **Users**: Specifies the users who can access the clusters.
3. **Contexts**: Combines clusters and users to define a context. A context is a tuple of (cluster, user, namespace).

### Example Kubeconfig File

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /path/to/ca.crt
    server: https://kubernetes.example.com
  name: example-cluster
users:
- name: example-user
  user:
    client-certificate: /path/to/client.crt
    client-key: /path/to/client.key
contexts:
- context:
    cluster: example-cluster
    user: example-user
    namespace: default
  name: example-context
current-context: example-context
```

After installing k3s, the default path for this configuration is `/etc/rancher/k3s/k3s.yml`. If you are using a different path, you can use the `kubectl` command with the `--kubeconfig` option followed by the path.


## Labesl and Selectors
Labels and selectors are fundamental concepts in Kubernetes, which is a popular container orchestration platform. They play a crucial role in organizing, managing, and deploying applications.

`Labels`
Labels are key-value pairs that are attached to Kubernetes objects, such as pods, services, and deployments. They are used to identify and organize these objects. Labels do not provide uniqueness; instead, they allow you to group and select subsets of objects.

`Example`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: my-app
    environment: production
spec:
  containers:
  - name: my-container
    image: my-image
```

`Selectors`
Selectors are used to filter and select Kubernetes objects based on their labels. There are two types of selectors: equality-based and set-based.
- Equality-based selectors: Match objects where the label key has a specific value.
- Set-based selectors: Match objects where the label key's value is in a set of values.
`Example`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9376
```
Importance of labels and Selectors for some resources like services and deployments.
- Organization: Labels help organize and categorize resources, making it easier to manage large clusters.
- Selection: Selectors allow services, replication controllers, and other resources to dynamically select the appropriate set of pods to manage.
- Scalability: Labels and selectors enable scalable and flexible management of resources, allowing for easy updates and rollouts.
- Isolation: They help in isolating environments (e.g., development, staging, production) by using different labels for different environments.
By using labels and selectors effectively, you can ensure that your Kubernetes deployments and services are well-organized, scalable, and maintainable.


### Pods

A Pod is the smallest and simplest Kubernetes object. It represents a single instance of a running process in your cluster. Pods contain one or more containers, such as Docker containers. When a Pod runs multiple containers, the containers are managed as a single entity and share the Pod's resources, including networking and storage.

#### Key Characteristics of Pods

- **Single IP Address**: Each Pod is assigned a unique IP address, which is shared among all the containers in the Pod.
- **Shared Storage**: Containers in a Pod can share storage volumes, allowing them to access the same data.
- **Lifecycle**: Pods have a defined lifecycle, starting from pending, running, succeeded/failed, and terminating.
- **Ephemeral**: Pods are ephemeral by nature. They are created, destroyed, and re-created as needed by the Kubernetes system.

#### Example Pod Manifest

Here is an example of a simple Pod manifest in YAML format:

```yaml
apiVersion: v1
kind: Pod
metadata:
    name: example-pod
spec:
    containers:
    - name: example-container
        image: nginx:latest
        ports:
        - containerPort: 80
```

In this example, the Pod named `example-pod` runs a single container using the `nginx:latest` image. The container exposes port 80 to the outside world.

Pods are fundamental to Kubernetes and serve as the building blocks for deploying and managing containerized applications.

## ReplicaSet

A ReplicaSet is a Kubernetes resource that ensures a specified number of pod replicas are running at any given time. It is responsible for maintaining the desired state of the application by creating or deleting pods as needed.

### Key Characteristics of ReplicaSet

- **Desired State**: Defines the number of pod replicas that should be running.
- **Self-Healing**: Automatically replaces failed or deleted pods to maintain the desired number of replicas.
- **Label Selector**: Uses label selectors to identify the pods it manages.

### Example ReplicaSet Manifest

Here is an example of a simple ReplicaSet manifest in YAML format:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
    name: example-replicaset
spec:
    replicas: 3
    selector:
        matchLabels:
            app: example-app
    template:
        metadata:
            labels:
                app: example-app
        spec:
            containers:
            - name: example-container
                image: nginx:latest
                ports:
                - containerPort: 80
```

In this example, the ReplicaSet named `example-replicaset` ensures that three replicas of the pod with the label `app: example-app` are running. The pod template specifies the container image and port configuration.

### Use Cases for ReplicaSet

- **High Availability**: Ensures that a specified number of pod replicas are always running, providing high availability for applications.
- **Scaling**: Allows for easy scaling of applications by adjusting the number of replicas.
- **Self-Healing**: Automatically recovers from pod failures, maintaining the desired state of the application.

ReplicaSets are fundamental for managing the lifecycle and availability of pods in a Kubernetes cluster, ensuring that applications run reliably and efficiently.

## Deployment

A Deployment is a higher-level Kubernetes resource that provides declarative updates to applications. It manages ReplicaSets and Pods, ensuring that the desired state of the application is maintained. Deployments offer advanced features such as rolling updates and rollbacks, making them a powerful tool for managing application lifecycle.

### Key Characteristics of Deployment

- **Declarative Updates**: Allows you to define the desired state of your application, and Kubernetes will manage the changes to achieve that state.
- **Rolling Updates**: Supports rolling updates to update Pods incrementally with zero downtime.
- **Rollbacks**: Enables rolling back to previous versions of the application in case of issues.
- **Self-Healing**: Automatically replaces failed or deleted Pods to maintain the desired state.

### Example Deployment Manifest

Here is an example of a simple Deployment manifest in YAML format:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: example-deployment
spec:
    replicas: 3
    selector:
        matchLabels:
            app: example-app
    template:
        metadata:
            labels:
                app: example-app
        spec:
            containers:
            - name: example-container
                image: nginx:latest
                ports:
                - containerPort: 80
```

In this example, the Deployment named `example-deployment` ensures that three replicas of the Pod with the label `app: example-app` are running. The Pod template specifies the container image and port configuration.

### Relationship with ReplicaSet and Pod

- **ReplicaSet**: The Deployment manages a ReplicaSet, which in turn ensures that the specified number of Pod replicas are running. The ReplicaSet is automatically created and updated by the Deployment.
- **Pod**: The Pods are created and managed by the ReplicaSet. The Deployment defines the Pod template, which the ReplicaSet uses to create the Pods.

### Use Cases for Deployment

- **Application Updates**: Perform rolling updates to update applications with zero downtime.
- **Scaling**: Scale applications up or down by adjusting the number of replicas.
- **Version Control**: Roll back to previous versions of the application if needed.
- **Self-Healing**: Ensure high availability and reliability by automatically replacing failed Pods.

Deployments are essential for managing the lifecycle of applications in a Kubernetes cluster, providing powerful features for updates, scaling, and self-healing.

You can imagine the relation Between Deployment, ReplicaSet and Pod is like that :

![Relation between Dep-Replicas-Pod](./imgs/relation-dep-replicas-pod.png)

## Services

In Kubernetes, a Service is an abstraction that defines a logical set of Pods and a policy by which to access them. Services enable communication between different parts of an application and can expose your application to external traffic.

### Types of Services

1. **ClusterIP**: Exposes the Service on an internal IP in the cluster. This type makes the Service only reachable from within the cluster.
2. **NodePort**: Exposes the Service on each Node's IP at a static port. A ClusterIP Service, to which the NodePort Service routes, is automatically created.
3. **LoadBalancer**: Exposes the Service externally using a cloud provider's load balancer. NodePort and ClusterIP Services, to which the external load balancer routes, are automatically created.
4. **ExternalName**: Maps a Service to the contents of the `externalName` field (e.g., `foo.bar.example.com`), returning a CNAME record with its value.

### Example Service Manifest

Here is an example of a simple Service manifest in YAML format:

```yaml
apiVersion: v1
kind: Service
metadata:
    name: example-service
spec:
    selector:
        app: example-app
    ports:
        - protocol: TCP
            port: 80
            targetPort: 9376
    type: ClusterIP
```

In this example, the Service named `example-service` targets Pods with the label `app: example-app`. It exposes port 80 and forwards traffic to port 9376 on the selected Pods.

### Key Characteristics of Services

- **Stable IP Address**: Services provide a stable IP address and DNS name for a set of Pods, ensuring reliable communication.
- **Load Balancing**: Services distribute traffic across the Pods they target, providing load balancing.
- **Service Discovery**: Kubernetes offers built-in service discovery, allowing Pods to find and communicate with Services using DNS names.

Services are essential for managing communication within a Kubernetes cluster and exposing applications to external users.

This image explain how services can wrapped the Pods:

![Services](./imgs/services.png)

## Ingress

In Kubernetes, an Ingress is an API object that manages external access to services within a cluster, typically HTTP and HTTPS. Ingress can provide load balancing, SSL termination, and name-based virtual hosting.

### Key Characteristics of Ingress

- **External Access**: Manages external access to services, allowing users to reach applications from outside the cluster.
- **Load Balancing**: Distributes traffic across multiple backend services, providing load balancing.
- **SSL Termination**: Supports SSL/TLS termination, enabling secure communication.
- **Path-Based Routing**: Routes traffic based on URL paths, allowing multiple services to be accessed through a single IP address.

### Example Ingress Manifest

Here is an example of a simple Ingress manifest in YAML format:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: example-ingress
spec:
    rules:
    - host: example.com
        http:
            paths:
            - path: /
                pathType: Prefix
                backend:
                    service:
                        name: example-service
                        port:
                            number: 80
```

In this example, the Ingress named `example-ingress` routes traffic from `example.com` to the `example-service` on port 80.

### Ingress Controllers

To use Ingress, you need an Ingress Controller, which is responsible for fulfilling the Ingress rules. Popular Ingress Controllers include:

- **NGINX Ingress Controller**: A widely used Ingress Controller based on NGINX.
- **Traefik**: A modern HTTP reverse proxy and load balancer.
- **HAProxy**: A reliable, high-performance TCP/HTTP load balancer.

### Use Cases for Ingress

- **Single Entry Point**: Provides a single entry point for accessing multiple services within the cluster.
- **Secure Communication**: Enables SSL/TLS termination for secure communication.
- **Traffic Management**: Manages and routes traffic based on URL paths and hostnames.
- **Load Balancing**: Distributes traffic across multiple backend services for high availability.

Ingress is a powerful tool for managing external access to services in a Kubernetes cluster, providing advanced routing, load balancing, and security features.

This example Show The idea that ingress Brigns:

![ingress](./imgs/ingress.png)