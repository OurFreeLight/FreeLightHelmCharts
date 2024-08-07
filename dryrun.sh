#!/usr/bin/env bash

ENV=$1
VERSION=${2:-"0.5.0"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install.sh staging"

    exit 1
fi

if [ ! -f "./env.$ENV/custom-values.yaml" ]; then
    echo "./env.$ENV/custom-values.yaml file is missing."

    exit 1
fi

helm template --debug --values ./env.$ENV/custom-values.yaml --dry-run ./charts/freelight-dao/$VERSION/