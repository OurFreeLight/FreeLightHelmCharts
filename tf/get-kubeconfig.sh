#!/usr/bin/env bash

PROVIDER=$1
ZONE=$2

if [ "$PROVIDER" == "" ]; then
    echo "Please specify a provider: aws,gcp"
    exit 1
fi

if [ "$PROVIDER" == "aws" ]; then
    if [ "$ZONE" == "" ]; then
        echo "Please specify a region: us-east-2,us-west-2,..."
        exit 1
    fi

    aws eks update-kubeconfig --region $ZONE --name freelight-cluster
fi

if [ "$PROVIDER" == "gcp" ]; then
    if [ "$ZONE" == "" ]; then
        echo "Please specify a zone: us-central1-b,..."
        exit 1
    fi

    gcloud container clusters get-credentials freelight-cluster --location=$ZONE
fi