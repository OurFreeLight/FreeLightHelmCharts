#!/usr/bin/env bash

set -e

ENV=$1
NAMESPACE=${2:-"$ENV"}

if [ "$ENV" == "" ]; then
    echo "Please specify the environment: ./install.sh staging"

    exit 1
fi

if [ ! -f "./.env" ]; then
  echo ".env file is missing."

  exit 1
fi

source ./.env

if [ "$DATABASE_SERVER" == "" ]; then
  echo "When deploying the restore pod, you must set the environment variables related to the DATABASE in the .env. DATABASE_SERVER was not set."

  exit 1
fi

KUBECONFIG_STR=""

if [ "$KUBECONFIG_PATH" != "" ]; then
  KUBECONFIG_STR="--kubeconfig $KUBECONFIG_PATH"
fi

IMAGE="ourfreelight/postgres-utils:0.5.3"
POD_NAME="restore-db"
TIMEOUT="60s"

echo "Deploying restore pod "${POD_NAME}" using image '${IMAGE}' into namespace '${NAMESPACE}'..."

cat <<EOF | kubectl $KUBECONFIG_STR apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
spec:
  containers:
  - name: app
    image: ${IMAGE}
    imagePullPolicy: Always
    command: 
      - bash
      - -c
      - "sleep infinity"
    env:
      - name: DATABASE_SERVER
        value: "${DATABASE_SERVER}"
      - name: DATABASE_PORT
        value: "5432"
      - name: DATABASE_USERNAME
        value: "${DATABASE_USERNAME}"
      - name: DATABASE_PASSWORD
        value: "${DATABASE_PASSWORD}"
      - name: DATABASE_SCHEMA
        value: "${DATABASE_SCHEMA}"
  restartPolicy: Never
EOF

echo "Restore pod deployed. You can now exec and run 'cd /backup && ./restore.sh' into the pod using:"
echo "kubectl ${KUBECONFIG_STR} exec -n "${NAMESPACE}" -it ${POD_NAME} -- bash"