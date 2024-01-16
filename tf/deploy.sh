#!/usr/bin/env bash

ENV=$1
PROVIDER=$2
REPLY=$3

if [ "$ENV" == "" ]; then
    echo "Please specify an environment: staging,production,..."
    exit 1
fi

if [ "$PROVIDER" == "" ]; then
    echo "Please specify a provider: aws,gcp"
    exit 1
fi

if [ ! -f "./$PROVIDER/custom.tfvars" ]; then
    echo "./$PROVIDER/custom.tfvars file is missing."
    exit 1
fi

cd ./$PROVIDER/

terraform plan -out ./dist/up.tfplan -var-file="./custom.tfvars"

if [ "$REPLY" != "y" ]; then
    read -p "Are you sure you want to deploy? " -n 1 -r
    echo    # (optional) move to a new line
fi

if [[ $REPLY =~ ^[Yy]$ ]]
then
    terraform apply ./dist/up.tfplan
fi