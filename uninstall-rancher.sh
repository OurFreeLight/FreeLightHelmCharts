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

helm uninstall $KUBECONFIG_STR rancher --namespace cattle-system

kubectl $KUBECONFIG_STR delete namespace cattle-system
kubectl $KUBECONFIG_STR delete namespace cattle-fleet-clusters-system
kubectl $KUBECONFIG_STR delete namespace cattle-fleet-system
kubectl $KUBECONFIG_STR delete namespace cattle-global-nt
kubectl $KUBECONFIG_STR delete namespace cattle-impersonation-system
kubectl $KUBECONFIG_STR delete namespace cattle-provisioning-capi-system
