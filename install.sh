#!/usr/bin/env bash

ENV=$1
CHART=${2:-"freelight-dao"}
VERSION=${3:-"0.5.0"}
NAMESPACE=${4:-"$ENV"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install.sh staging"

    exit 1
fi

if [ ! -f "./env.$ENV/$CHART/custom-values.yaml" ]; then
    echo "./env.$ENV/$CHART/custom-values.yaml file is missing."

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

echo "Installing chart $CHART for environment $ENV into namespace $NAMESPACE"

helm upgrade $KUBECONFIG_STR --install $CHART ./charts/$CHART/$VERSION/ \
    --namespace $NAMESPACE --create-namespace \
    --values ./env.$ENV/$CHART/custom-values.yaml