#!/bin/bash

# See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
# and https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

NS="ingress-nginx"
NSAPP="ingress-app"

NODE1_IP=$(kubectl get nodes --selector="! node-role.kubernetes.io/master" \
    -o=jsonpath='{.items[0].status.addresses[0].address}')

# Run on kubeadm cluster
# see "kubernetes in action" p391
kubectl delete ns -l "ingress=nginx"
kubectl create namespace "$NS"
kubectl create namespace "$NSAPP"
kubectl label ns "$NS" "ingress=nginx"
kubectl label ns "$NSAPP" "ingress=nginx"

# Install nginx-controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace "$NS" --create-namespace

# Deploy application
kubectl create deployment web -n "$NSAPP" --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web -n "$NSAPP" --type=NodePort --port=8080
kubectl  wait -n "$NSAPP" --for=condition=available deployment web

# Wait for nginx-controller to be up and running
kubectl wait --for=condition=available deployment -n "$NS" -l app.kubernetes.io/instance=ingress-nginx

# Create ingress route
kubectl apply -n "$NSAPP" -f $DIR/example-ingress.yaml
kubectl get -n "$NSAPP" ingress

echo "WARNING: Add the following line to /etc/hosts"
echo "$NODE1_IP hello-world.info"

NODE_PORT=$(kubectl get svc web -n "$NSAPP"  -o jsonpath="{.spec.ports[0].nodePort}")
echo "INFO: access the application via ingress"
echo "curl hello-world.info:$NODE_PORT"
