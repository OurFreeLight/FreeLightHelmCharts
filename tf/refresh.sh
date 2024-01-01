#!/usr/bin/env bash

PROVIDER=$1

if [ "$PROVIDER" == "" ]; then
    echo "Please specify a provider: aws,gcp"
    exit 1
fi

cd ./$PROVIDER/

terraform refresh -var-file="./custom.tfvars"