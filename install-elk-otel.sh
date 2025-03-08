#!/usr/bin/env bash

set -e

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

NAMESPACE="observability"
KUBECONFIG_STR=""

if [ "$KUBECONFIG_PATH" != "" ]; then
  KUBECONFIG_STR="--kubeconfig $KUBECONFIG_PATH"
fi

# Install ELK/OpenTelemetry COllector
echo "Installing ELK $ELK_VERSION"

# helm repo add bitnami https://charts.bitnami.com/bitnami
# helm search repo bitnami

# kubectl $KUBECONFIG_STR create namespace elastic-stack 2>/dev/null || true

# helm $KUBECONFIG_STR upgrade --install elasticsearch bitnami/elasticsearch \
#     --values ./elk/elasticsearch-values.yaml -n elastic-stack

helm $KUBECONFIG_STR upgrade --install kibana bitnami/kibana \
    --values ./elk/kibana-values.yaml -n elastic-stack

# helm repo add elastic https://helm.elastic.co
# helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
# helm repo update

# kubectl $KUBECONFIG_STR create namespace elastic-system 2>/dev/null || true

# helm $KUBECONFIG_STR upgrade --install eck-operator elastic/eck-operator \
#   --namespace elastic-system \
#   --set installCRDs=true

# kubectl $KUBECONFIG_STR create namespace elastic-stack 2>/dev/null || true

# helm $KUBECONFIG_STR upgrade --install eck-stack elastic/eck-stack \
#     --values ./elk/kibana-values.yaml -n elastic-stack

echo "Finished installing ELK $ELK_VERSION..."
