#!/usr/bin/env bash

PROVIDER=$1

if [ "$PROVIDER" == "" ]; then
    echo "Please specify a provider: aws,gcp"
    exit 1
fi

cd ./$PROVIDER/

terraform show -json ./dist/up.tfplan > ./dist/up.tfplan.json
infracost breakdown --path ./dist/up.tfplan.json