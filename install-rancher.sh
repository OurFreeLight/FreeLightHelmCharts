#!/usr/bin/env bash

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

# Setup Rancher
echo "Setting up rancher..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system

# Install rancher
echo "Installing rancher $RANCHER_VERSION"
helm install rancher rancher-stable/rancher --version=$RANCHER_VERSION \
  --namespace cattle-system \
  --set hostname=$DOMAIN \
  --set replicas=1 \
  --set bootstrapPassword="$BOOTSTRAP_PASSWORD" \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email="$ADMIN_EMAIL"
echo "Finished installing rancher..."
