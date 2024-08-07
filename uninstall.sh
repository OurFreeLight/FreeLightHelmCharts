#!/usr/bin/env bash

NAMESPACE=$1

if [ "$NAMESPACE" == "" ]; then
    echo "Please specify a namespace to uninstall from: staging,production,..."

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

echo "Uninstalling from namespace $NAMESPACE"

helm uninstall $KUBECONFIG_STR freelight-dao --namespace $NAMESPACE