#!/usr/bin/env bash

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

echo "Installing nginx ingress $NGINX_VERSION"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

LOAD_BALANCER_IP=""

if [ "$STATIC_IP" != "" ]; then
  LOAD_BALANCER_IP="--set controller.service.loadBalancerIP=$STATIC_IP"
  echo "Using load balancer ip: $STATIC_IP"
fi

helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer $LOAD_BALANCER_IP \
  --version $NGINX_VERSION \
  --create-namespace --set controller.watchIngressWithoutClass=true

echo "Finished installing nginx ingress"

echo "Installing jetstack cert-manager $CERT_MANAGER_VERSION"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v$CERT_MANAGER_VERSION/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v$CERT_MANAGER_VERSION
echo "Finished installing jetstack cert-manager..."