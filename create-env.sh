#!/usr/bin/env bash

ENV=$1

if [ "$ENV" == "" ]; then
    echo "Please specify an environment: staging,production,..."
    exit 1
fi

mkdir -p ./env.$ENV/ 2> /dev/null