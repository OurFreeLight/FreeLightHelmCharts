#!/usr/bin/env bash

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

KUBECONFIG_STR=""

if [ "$KUBECONFIG_PATH" != "" ]; then
  KUBECONFIG_STR="--kubeconfig $KUBECONFIG_PATH"
fi

echo "Installing nginx ingress $NGINX_VERSION"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

LOAD_BALANCER_IP=""

if [ "$STATIC_IP" != "" ]; then
  LOAD_BALANCER_IP="--set controller.service.loadBalancerIP=$STATIC_IP"
  echo "Using load balancer ip: $STATIC_IP"
fi

helm upgrade $KUBECONFIG_STR --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer $LOAD_BALANCER_IP \
  --version $NGINX_VERSION \
  --create-namespace --set controller.watchIngressWithoutClass=true

echo "Finished installing nginx ingress"