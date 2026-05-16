#!/usr/bin/env bash

kubectl -n cattle-system apply -f ./wireguard-tunnel-configmap.yaml

kubectl -n cattle-system patch deployment cattle-cluster-agent --type=strategic --patch-file ./wireguard-tunnel.yaml