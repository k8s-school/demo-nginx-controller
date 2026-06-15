#!/bin/bash

# See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
# and https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

NSAPP="ingress-app"

# Run on openshift cluster
kubectl delete project -l "kubernetes.io/metadata.name=$NSAPP"
oc new-project "$NSAPP"

# Deploy application
kubectl create deployment web -n "$NSAPP" --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web -n "$NSAPP" --port=8080
kubectl  wait -n "$NSAPP" --for=condition=available deployment web

# Create ingress route
kubectl get ingressclasses
kubectl apply -n "$NSAPP" -f $DIR/example-ingress-openshift.yaml
kubectl get -n "$NSAPP" ingress
kubectl get -n "$NSAPP" route

curl https://hello-world.apps-crc.testing
