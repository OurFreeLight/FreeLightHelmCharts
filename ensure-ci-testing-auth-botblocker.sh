#!/usr/bin/env bash
#
# Idempotently ensure freelight-auth + botblocker exist in the `ci-testing`
# namespace. Used by the DAO pipeline's combined apply+e2e job to SELF-HEAL
# the stack if a concurrent pipeline's teardown wiped auth/botblocker between
# this pipeline's prepare:ci-testing and its e2e run.
#
# Why this exists:
#   teardown-ci-testing.sh runs `when: always` and shares
#   `resource_group: ci-testing` with prepare/apply/e2e. resource_group
#   serializes jobs to one-at-a-time but does NOT order them across
#   pipelines — so an older pipeline's teardown can fire between a newer
#   pipeline's prepare (which installed auth) and its e2e (which needs
#   auth). The e2e then can't port-forward to freelight-auth-frontend and
#   fails with "port-forward 8099 never opened".
#
#   The DAO apply step only ever restored freelight-dao, never auth. This
#   script restores the OTHER two charts — but only when they're actually
#   missing, so the normal path (prepare's stack survived) stays a fast
#   couple of `helm status` checks.
#
# Idempotent: each chart is guarded by `helm status`; we only install what's
# absent. The bigbuff seed is re-run only when we had to (re)install
# botblocker (the seed itself is TRUNCATE+COPY, so safe either way).
#
# Usage:  ./ensure-ci-testing-auth-botblocker.sh [AUTH_TAG]
#   AUTH_TAG defaults to latest-staging (matches install-ci-testing.sh).
set -euo pipefail

readonly NS="ci-testing"
readonly AUTH_TAG="${1:-latest-staging}"
readonly AUTH_CHART_VERSION="${AUTH_CHART_VERSION:-0.1.2}"
readonly BB_CHART_VERSION="${BB_CHART_VERSION:-0.6.0}"
readonly REGISTRY="harbor.higheredgesoftware.com/ourfreelight"

if [[ "$NS" != "ci-testing" ]]; then
  echo "FATAL: NS is hard-coded to ci-testing; refusing to run." >&2
  exit 99
fi

cd "$(dirname "$0")"

# ── freelight-auth ──────────────────────────────────────────────────────────
if helm status freelight-auth --namespace "$NS" >/dev/null 2>&1; then
  echo "==> freelight-auth already present — no action"
else
  echo "==> freelight-auth MISSING — restoring (concurrent-teardown self-heal)"
  helm upgrade --install freelight-auth \
    ./charts/freelight-auth/${AUTH_CHART_VERSION}/ \
    --namespace "$NS" \
    --values ./env.ci-testing/freelight-auth/custom-values.yaml \
    --set "freelightAuth_frontend.image=${REGISTRY}/freelight-auth-frontend:${AUTH_TAG}" \
    --set "freelightAuth_backend.image=${REGISTRY}/freelight-auth-backend:${AUTH_TAG}" \
    --wait --timeout 5m
fi

# ── botblocker (+ bigbuff seed) ─────────────────────────────────────────────
if helm status botblocker --namespace "$NS" >/dev/null 2>&1; then
  echo "==> botblocker already present — no action"
else
  echo "==> botblocker MISSING — restoring + reseeding (concurrent-teardown self-heal)"
  helm upgrade --install botblocker \
    ./charts/botblocker/${BB_CHART_VERSION}/ \
    --namespace "$NS" \
    --values ./env.ci-testing/botblocker/custom-values.yaml \
    --wait --timeout 3m
  ./seed-bigbuff-hashes-ci-testing.sh
fi

echo "==> auth + botblocker confirmed present in $NS"
