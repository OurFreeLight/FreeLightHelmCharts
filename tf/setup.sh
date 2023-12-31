#!/usr/bin/env bash

PROVIDER=$1

if [ "$PROVIDER" == "" ]; then
    echo "Please specify a provider: aws,gcp"
    exit 1
fi

cd ./$PROVIDER/

mkdir -p ./dist 2> /dev/null

terraform init