#!/usr/bin/env bash

NAMESPACE=$1

if [ "$NAMESPACE" == "" ]; then
    echo "Please specify a namespace to uninstall from: staging,production,..."

    exit 1
fi

echo "Uninstalling from namespace $NAMESPACE"

helm uninstall freelight-dao --namespace $NAMESPACE