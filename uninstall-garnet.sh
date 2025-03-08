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
echo "UnInstalling Garnet $GARNET_VERSION"

helm uninstall $KUBECONFIG_STR garnet --namespace $NAMESPACE

echo "Finished uninstalling rancher..."
