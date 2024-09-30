#!/bin/bash

# See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start
# and https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/conf.sh

usage() {
  cat << EOD

Usage: `basename $0` [options]

  Available options:
    -h         this message
    -s         run exercice and solution

Run ingress exercice
EOD
}

INGRESS_FULL=false

# get the options
while getopts hs c ; do
    case $c in
	    h) usage ; exit 0 ;;
	    s) INGRESS_FULL=true ;;
	    \?) usage ; exit 2 ;;
    esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

NSAPP="ingress-app"
NODE1_IP=$(kubectl get nodes --selector="! node-role.kubernetes.io/master" \
    -o=jsonpath='{.items[0].status.addresses[0].address}')

# Run on kubeadm cluster
# see "kubernetes in action" p391
kubectl delete ns -l "ingress=nginx"
kubectl create namespace "$ingress_ns"
kubectl create namespace "$NSAPP"
kubectl label ns "$ingress_ns" "ingress=nginx"
kubectl label ns "$NSAPP" "ingress=nginx"

ink "Install nginx-controller"
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace "$ingress_ns" --create-namespace

ink "Deploy application"
kubectl create deployment web -n "$NSAPP" --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web -n "$NSAPP" --port=8080
kubectl  wait -n "$NSAPP" --for=condition=available deployment web

ink "Wait for nginx-controller to be up and running (alternatively, use helm --wait)"
kubectl wait --for=condition=available deployment -n "$ingress_ns" -l app.kubernetes.io/instance=ingress-nginx

TMP_STR="$NODE1_IP hello-world.info"
echo "INFO: Add '$TMP_STR' to /etc/hosts"
sudo sh -c "echo '$TMP_STR' >> /etc/hosts"

if [ "$INGRESS_FULL" = false ]
then
    exit 0
fi

ink "Create ingress route"
kubectl apply -n "$NSAPP" -f $DIR/example-ingress.yaml
kubectl get -n "$NSAPP" ingress

ink "Access the application"
NODE_PORT=$(kubectl get svc ingress-nginx-controller -n "$ingress_ns"  -o jsonpath="{.spec.ports[0].nodePort}")

helm upgrade --wait --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace "$ingress_ns" --create-namespace \
  --set controller.service.type=NodePort


echo "INFO: access the application via ingress"
curl hello-world.info:$NODE_PORT
