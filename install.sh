#!/usr/bin/env bash

ENV=$1
CHART=${2:-"freelight-dao"}
VERSION=${3:-"0.5.0"}
NAMESPACE=${4:-"$ENV"}
APP_NAME=${5:-"$CHART"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install.sh staging"

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

ENV_FILE=${6:-"./env.$ENV/$CHART/custom-values.yaml"}

if [ ! -f "$ENV_FILE" ]; then
    echo "$ENV_FILE file is missing."

    exit 1
fi

echo "Installing chart $CHART for environment $ENV into namespace $NAMESPACE using $ENV_FILE"

helm $KUBECONFIG_STR upgrade --install $APP_NAME ./charts/$CHART/$VERSION/ \
    --namespace $NAMESPACE --create-namespace \
    --values $ENV_FILE