#!/usr/bin/env bash

VERSION=${1:-"0.5.0"}
NAMESPACE="freelight-dao"

cd ./charts/freelight-dao/$VERSION/

if [ ! -f "./custom-values.yaml" ]; then
    echo "./charts/freelight-dao/$VERSION/custom-values.yaml file is missing."

    exit 1
fi

helm install freelight-dao . --namespace $NAMESPACE --create-namespace --values ./custom-values.yaml