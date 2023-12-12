#!/usr/bin/env bash

helm uninstall rancher --namespace cattle-system

kubectl delete namespace cattle-system
kubectl delete namespace cattle-fleet-clusters-system
kubectl delete namespace cattle-fleet-system
kubectl delete namespace cattle-global-nt
kubectl delete namespace cattle-impersonation-system
kubectl delete namespace cattle-provisioning-capi-system
