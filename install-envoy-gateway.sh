#!/usr/bin/env bash

ENV=$1
NAMESPACE=${2:-"$ENV"}

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

KUBECONFIG_STR=""

if [ "$KUBECONFIG_PATH" != "" ]; then
  KUBECONFIG_STR="--kubeconfig $KUBECONFIG_PATH"
fi

# Install Envoy Gateway
echo "Installing Envoy Gateway $ENVOY_GATEWAY_VERSION"

helm $KUBECONFIG_STR upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
    --version $ENVOY_GATEWAY_VERSION \
    -n envoy-gateway-system \
    --create-namespace

echo "Waiting for Envoy Gateway to be ready..."
kubectl $KUBECONFIG_STR wait --timeout=5m -n envoy-gateway-system \
    deployment/envoy-gateway --for=condition=Available

# Create the GatewayClass
echo "Creating GatewayClass 'eg'..."
kubectl $KUBECONFIG_STR apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF

# Create a Gateway resource in the target namespace
if [ "$ENV" != "" ]; then
  echo "Creating Gateway 'freelight-gateway' in namespace $NAMESPACE..."

  kubectl $KUBECONFIG_STR create namespace $NAMESPACE 2>/dev/null || true

  kubectl $KUBECONFIG_STR apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: freelight-gateway
  namespace: $NAMESPACE
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
EOF

  echo "Waiting for Gateway to be programmed..."
  kubectl $KUBECONFIG_STR wait --timeout=5m -n $NAMESPACE \
      gateway/freelight-gateway --for=condition=Programmed 2>/dev/null || \
      echo "Gateway created (may take a moment to be fully programmed)"
fi

echo "Finished installing Envoy Gateway"
