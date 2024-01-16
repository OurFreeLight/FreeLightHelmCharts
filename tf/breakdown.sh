#!/usr/bin/env bash

ENV=$1
PROVIDER=$2

if [ "$ENV" == "" ]; then
    echo "Please specify an environment: staging,production,..."
    exit 1
fi

if [ "$PROVIDER" == "" ]; then
    echo "Please specify a provider: aws,gcp"
    exit 1
fi

cd ./$PROVIDER/

terraform show -json ./dist/up.tfplan > ./dist/up.tfplan.json
infracost breakdown --path ./dist/up.tfplan.json