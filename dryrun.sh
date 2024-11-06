#!/usr/bin/env bash

ENV=$1
CHART=${2:-"freelight-dao"}
VERSION=${3:-"0.5.0"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install.sh staging"

    exit 1
fi

if [ ! -f "./env.$ENV/$CHART/custom-values.yaml" ]; then
    echo "./env.$ENV/$CHART/custom-values.yaml file is missing."

    exit 1
fi

helm template --debug --values ./env.$ENV/$CHART/custom-values.yaml --dry-run ./charts/$CHART/$VERSION/