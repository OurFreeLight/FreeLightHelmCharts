#!/usr/bin/env bash

ENV=$1
NAMESPACE=$ENV

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
echo "Setting up MariaDB..."
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install Database
echo "Installing MariaDB $MARIADB_VERSION"

helm install $KUBECONFIG_STR mariadb bitnami/mariadb --version=$MARIADB_VERSION \
  --namespace $NAMESPACE --create-namespace \
  --set auth.rootPassword=$MARIADB_ROOT_PASSWORD \
  --set auth.database=$MARIADB_DATABASE \
  --set auth.username=$MARIADB_USERNAME \
  --set auth.password=$MARIADB_PASSWORD
echo "Finished installing Database..."
