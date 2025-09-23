#!/usr/bin/env bash

ENV=$1
NAMESPACE=${2:-"$ENV"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install-garnet.sh staging"

    exit 1
fi

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

KUBECONFIG_STR=""

if [ "$KUBECONFIG_PATH" != "" ]; then
  KUBECONFIG_STR="--kubeconfig $KUBECONFIG_PATH"
fi

# Install Garnet
echo "Installing Garnet $GARNET_VERSION"

# helm install $KUBECONFIG_STR garnet ./charts/garnet/$GARNET_VERSION/ \
#     --namespace $NAMESPACE --create-namespace \
#     --set cluster.enabled=false

helm $KUBECONFIG_STR upgrade --install garnet oci://ghcr.io/microsoft/helm-charts/garnet --version=$GARNET_VERSION \
    --namespace $NAMESPACE --create-namespace

echo "Finished installing Garnet..."
