#!/usr/bin/env bash

REPLY=$1

cd ./gcp/

terraform plan -destroy -out=./dist/destroy.tfplan -var-file="./custom.tfvars"

if [ "$REPLY" != "y" ]; then
    read -p "Are you sure you want to destroy? " -n 1 -r
    echo    # (optional) move to a new line
fi

if [[ $REPLY =~ ^[Yy]$ ]]
then
    terraform apply ./dist/destroy.tfplan
fi