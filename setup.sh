#!/bin/bash

# See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
# and https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

NS="ingress-nginx"

NODE1_IP=$(kubectl get nodes --selector="! node-role.kubernetes.io/master" \
    -o=jsonpath='{.items[0].status.addresses[0].address}')

# Run on kubeadm cluster
# see "kubernetes in action" p391
kubectl delete ns -l "ingress=nginx"
kubectl create namespace "$NS"
kubectl label ns network "ingress=nginx"

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace "$NS" --create-namespace


kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web --type=NodePort --port=8080
kubectl apply -f https://k8s.io/examples/service/networking/example-ingress.yaml
kubectl get ingress

echo "Add the followin line to /etc/hosts"
echo "$NODE1_IP hello-world.info"

# TODO
echo "curl hello-world.info:$NODE_PORT"