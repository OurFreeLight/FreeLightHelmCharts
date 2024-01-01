#!/usr/bin/env bash

PROVIDER=$1
REPLY=$2

if [ "$PROVIDER" == "" ]; then
    echo "Please specify a provider: aws,gcp"
    exit 1
fi

cd ./$PROVIDER/

terraform plan -destroy -out=./dist/destroy.tfplan -var-file="./custom.tfvars"

if [ "$REPLY" != "y" ]; then
    read -p "Are you sure you want to destroy? " -n 1 -r
    echo    # (optional) move to a new line
fi

if [[ $REPLY =~ ^[Yy]$ ]]
then
    terraform apply ./dist/destroy.tfplan
fi