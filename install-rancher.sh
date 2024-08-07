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

# Setup Rancher
echo "Setting up rancher..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl $KUBECONFIG_STR create namespace cattle-system

# Install rancher
echo "Installing rancher $RANCHER_VERSION"
helm install $KUBECONFIG_STR rancher rancher-stable/rancher --version=$RANCHER_VERSION \
  --namespace cattle-system \
  --set hostname=$DOMAIN \
  --set replicas=1 \
  --set bootstrapPassword="$BOOTSTRAP_PASSWORD" \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email="$ADMIN_EMAIL"
echo "Finished installing rancher..."
