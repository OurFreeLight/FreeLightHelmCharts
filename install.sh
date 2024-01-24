#!/usr/bin/env bash

ENV=$1
VERSION=${2:-"0.5.0"}
NAMESPACE=${3:-"$ENV"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install.sh staging"

    exit 1
fi

if [ ! -f "./env.$ENV/custom-values.yaml" ]; then
    echo "./env.$ENV/custom-values.yaml file is missing."

    exit 1
fi

echo "Installing environment $ENV into namespace $NAMESPACE"

helm install freelight-dao ./charts/freelight-dao/$VERSION/ \
    --namespace $NAMESPACE --create-namespace \
    --values ./env.$ENV/custom-values.yaml