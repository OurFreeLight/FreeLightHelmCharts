#!/usr/bin/env bash
#
# Convenience wrapper: install all three charts into the `ci-testing`
# namespace using env.ci-testing/<chart>/custom-values.yaml. Pairs with
# teardown-ci-testing.sh + seed-bigbuff-hashes-ci-testing.sh.
#
# Usage:
#   ./install-ci-testing.sh [DAO_TAG] [AUTH_TAG]
# Both default to `latest-staging`. CI passes the freshly-built DAO tag.
#
# Order matters:
#   1) freelight-dao  — brings up Postgres + Garnet + Dicebear + DAO itself
#   2) freelight-auth — depends on the Postgres + Garnet from step 1
#   3) botblocker     — depends on the Postgres + bigbuff_hashes schema
#   4) seed 100 bigbuff_hashes rows from staging
set -euo pipefail

readonly NS="ci-testing"
readonly DAO_TAG="${1:-latest-staging}"
readonly AUTH_TAG="${2:-latest-staging}"
readonly DAO_CHART_VERSION="${DAO_CHART_VERSION:-0.6.3}"
readonly AUTH_CHART_VERSION="${AUTH_CHART_VERSION:-0.1.2}"
readonly BB_CHART_VERSION="${BB_CHART_VERSION:-0.6.0}"

if [[ "$NS" != "ci-testing" ]]; then
  echo "FATAL: NS is hard-coded to ci-testing; refusing to run." >&2
  exit 99
fi

cd "$(dirname "$0")"

echo "==> 1/4  helm upgrade --install freelight-dao  (tag: $DAO_TAG)"
helm upgrade --install freelight-dao \
  ./charts/freelight-dao/${DAO_CHART_VERSION}/ \
  --namespace "$NS" \
  --values ./env.ci-testing/freelight-dao/custom-values.yaml \
  --set "freelightDAO_frontend.image=harbor.higheredgesoftware.com/ourfreelight/freelight-dao-frontend:${DAO_TAG}" \
  --set "freelightDAO_API.image=harbor.higheredgesoftware.com/ourfreelight/freelight-dao-api:${DAO_TAG}" \
  --set "freelightDAO_API.database.migrations.image=harbor.higheredgesoftware.com/ourfreelight/postgres-utils:${DAO_TAG}" \
  --wait --timeout 8m

# DAO chart only brings up the Postgres + DAO. Wait for DAO migrations
# to finish before installing Auth (which lives in the same DB).
echo "==> waiting for DAO migrations job to complete"
kubectl -n "$NS" wait --for=condition=complete \
  job -l app.kubernetes.io/component=migrations --timeout=5m \
  || echo "    (no migrations job found — chart may have no separate job)"

echo "==> 2/4  helm upgrade --install freelight-auth  (tag: $AUTH_TAG)"
helm upgrade --install freelight-auth \
  ./charts/freelight-auth/${AUTH_CHART_VERSION}/ \
  --namespace "$NS" \
  --values ./env.ci-testing/freelight-auth/custom-values.yaml \
  --set "freelightAuth_frontend.image=harbor.higheredgesoftware.com/ourfreelight/freelight-auth-frontend:${AUTH_TAG}" \
  --set "freelightAuth_backend.image=harbor.higheredgesoftware.com/ourfreelight/freelight-auth-backend:${AUTH_TAG}" \
  --wait --timeout 5m

echo "==> 3/4  helm upgrade --install botblocker"
helm upgrade --install botblocker \
  ./charts/botblocker/${BB_CHART_VERSION}/ \
  --namespace "$NS" \
  --values ./env.ci-testing/botblocker/custom-values.yaml \
  --wait --timeout 3m

echo "==> 4/4  seed 100 bigbuff_hashes rows from staging"
./seed-bigbuff-hashes-ci-testing.sh

echo "==> All charts installed. Pods in $NS:"
kubectl -n "$NS" get pods
