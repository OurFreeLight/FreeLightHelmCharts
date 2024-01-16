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

mkdir -p ./env.$ENV/dist 2> /dev/null

terraform init

if [ ! -f "./custom.tfvars" ]; then
    echo "./$ENV/custom.tfvars file is missing. Be sure to create one before running the next scripts."
    exit 1
fi