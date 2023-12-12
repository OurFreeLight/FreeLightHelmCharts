#!/usr/bin/env bash

cd ./gcp/

mkdir -p ./dist 2> /dev/null

terraform init
terraform plan -out ./dist/up.tfplan -var-file="./custom.tfvars"