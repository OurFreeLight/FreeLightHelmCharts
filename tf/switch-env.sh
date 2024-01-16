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

PREV_ENV=$(cat ./.current-env 2> /dev/null)

# Move the current environment into the previous environment's folder.
mv -f ./custom.tfvars ./env.$PREV_ENV/custom.tfvars 2> /dev/null
mv -f ./.terraform.lock.hcl ./env.$PREV_ENV/.terraform.lock.hcl 2> /dev/null
mv -f ./.terraform ./env.$PREV_ENV/.terraform 2> /dev/null
mv -f ./dist/ ./env.$PREV_ENV/ 2> /dev/null

# Move the new environment into the provider's folder.
echo "$ENV" > ./.current-env
cp -fR ./env.$ENV/* ./