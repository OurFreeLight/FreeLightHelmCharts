#!/usr/bin/env bash

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

NAMESPACE="observability"
KUBECONFIG_STR=""

if [ "$KUBECONFIG_PATH" != "" ]; then
  KUBECONFIG_STR="--kubeconfig $KUBECONFIG_PATH"
fi

# Uninstall ELK/OpenTelemetry COllector
echo "Uninstalling ELK $ELK_VERSION"

helm $KUBECONFIG_STR uninstall eck-operator --namespace elastic-system
helm $KUBECONFIG_STR uninstall eck-stack -n elastic-stack

echo "Finished Uninstalling ELK $ELK_VERSION..."
