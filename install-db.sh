#!/usr/bin/env bash

ENV=$1
NAMESPACE=${2:-"$ENV"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install-db.sh staging"

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

# Setup Database
echo "Setting up Postgres..."
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install Database
echo "Installing Postgres $POSTGRES_VERSION"

helm install $KUBECONFIG_STR postgres bitnami/postgresql --version=$POSTGRES_VERSION \
  --namespace $NAMESPACE --create-namespace \
  --set auth.database=$POSTGRES_DB \
  --set auth.username=$POSTGRES_USER \
  --set auth.password=$POSTGRES_PASSWORD
echo "Finished installing Database..."
