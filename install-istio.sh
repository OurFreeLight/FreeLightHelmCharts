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

# Setup Istio
echo "Setting up Istio..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
kubectl $KUBECONFIG_STR create namespace istio-system 2>/dev/null || true

# Install Istio
echo "Installing Istio $ISTIO_VERSION"
helm $KUBECONFIG_STR upgrade --install istio-base istio/base --version=$ISTIO_VERSION --namespace istio-system --wait
helm $KUBECONFIG_STR upgrade --install istiod istio/istiod --version=$ISTIO_VERSION -n istio-system --wait
helm $KUBECONFIG_STR upgrade --install istio-ingress istio/gateway --version=$ISTIO_VERSION -n istio-ingress --create-namespace --wait
echo "Finished installing Istio..."
