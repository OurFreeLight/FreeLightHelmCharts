#!/usr/bin/env bash

if [ ! -f "./.env" ]; then
  echo ".env file is missing."
  exit 1
fi

source ./.env

KUBECONFIG_STR=""
if [ -n "${KUBECONFIG_PATH:-}" ]; then
  KUBECONFIG_STR="--kubeconfig $KUBECONFIG_PATH"
fi

# Setup cert-manager
echo "Setting up cert-manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl $KUBECONFIG_STR create namespace cert-manager 2>/dev/null || true

# Install cert-manager (with CRDs)
echo "Installing cert-manager ${CERT_MANAGER_VERSION}"
kubectl $KUBECONFIG_STR apply -f https://github.com/jetstack/cert-manager/releases/download/v$CERT_MANAGER_VERSION/cert-manager.crds.yaml
helm $KUBECONFIG_STR upgrade --install cert-manager jetstack/cert-manager --version $CERT_MANAGER_VERSION \
  --namespace cert-manager \
  --create-namespace \
  --wait

echo "Finished installing cert-manager."
