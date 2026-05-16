#!/usr/bin/env bash

USERNAME=$1
NAMESPACE=$2
EXPIRATION=${3:-"7776000"} # 90 days

if [ -z "$USERNAME" ]; then
    echo "Username is missing."
    exit 1
fi

if [ -z "$NAMESPACE" ]; then
    echo "Namespace is missing."
    exit 1
fi

BASE_PATH="./custom/$NAMESPACE/$USERNAME"

mkdir -p $BASE_PATH 2>/dev/null

if [ ! -f "$BASE_PATH/$USERNAME.crt" ]; then
    openssl genrsa -out "$BASE_PATH/$USERNAME.key" 2048
    openssl req -new -key "$BASE_PATH/$USERNAME.key" -out "$BASE_PATH/$USERNAME.csr" -subj "/CN=$USERNAME,/O=$NAMESPACE"
    openssl x509 -req -in "$BASE_PATH/$USERNAME.csr" -signkey "$BASE_PATH/$USERNAME.key" -out "$BASE_PATH/$USERNAME.crt"
fi

TOKEN=$(cat "$BASE_PATH/$USERNAME.csr" | base64 | tr -d "\n")

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $USERNAME
  namespace: $NAMESPACE
spec:
  request: $TOKEN
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: $EXPIRATION
  usages:
  - client auth
EOF

rm -f "$BASE_PATH/kubeconfig"

kubectl config view --raw -o jsonpath="{.clusters[].cluster.certificate-authority-data}" | base64 -d > "$BASE_PATH/cluster.ca.crt"

kubectl certificate approve $USERNAME
kubectl get csr $USERNAME -o jsonpath="{.status.certificate}" | base64 -d > $BASE_PATH/$USERNAME.crt
kubectl --kubeconfig "$BASE_PATH/kubeconfig" config set-credentials $USERNAME --client-key "$BASE_PATH/$USERNAME.key" --client-certificate "$BASE_PATH/$USERNAME.crt" --embed-certs=true
kubectl --kubeconfig "$BASE_PATH/kubeconfig" config set-context default --cluster default --user $USERNAME
kubectl --kubeconfig "$BASE_PATH/kubeconfig" config use-context default
kubectl --kubeconfig "$BASE_PATH/kubeconfig" config set-cluster default --server=https://api-staging.freelight.org:16443 --certificate-authority="$BASE_PATH/cluster.ca.crt" --embed-certs=true

cat <<EOF > "$BASE_PATH/roles.yaml"
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USERNAME-role
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USERNAME-role-binding
  namespace: $NAMESPACE
subjects:
- kind: User
  name: $USERNAME
roleRef:
  kind: Role
  name: $USERNAME-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f "$BASE_PATH/roles.yaml"