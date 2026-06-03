#!/usr/bin/env bash
#
# Tear down everything in the `ci-testing` namespace at end of an
# e2e run. NEVER deletes the namespace itself (the user owns its
# lifecycle), NEVER touches any other namespace.
#
# This script is paranoid by construction: NS is hard-coded at the
# top, asserted before every destructive op, and never read from an
# argument or env var. If you want to teardown a different namespace,
# write a different script — that's intentional.
#
# Safe to run repeatedly; every step tolerates "already gone".
set -euo pipefail

# ── Safety guard ────────────────────────────────────────────────────────────
readonly NS="ci-testing"
guard () {
  if [[ "$NS" != "ci-testing" ]]; then
    echo "FATAL: teardown-ci-testing.sh refuses to operate on namespace '$NS'." >&2
    echo "       This script is hard-coded to ci-testing. Aborting." >&2
    exit 99
  fi
}

# Every kubectl/helm call in this script funnels through these helpers
# so the -n flag can NEVER drift to another namespace by accident.
k () { guard; kubectl -n "$NS" "$@"; }
h () { guard; helm   -n "$NS" "$@"; }

guard
echo "==> Tearing down namespace: $NS (will not delete the namespace itself)"

# ── 1) Helm uninstall every release ─────────────────────────────────────────
echo "==> Uninstalling Helm releases in $NS"
releases="$(h list -q || true)"
if [[ -n "$releases" ]]; then
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    echo "    helm uninstall $rel"
    h uninstall "$rel" --wait --timeout 3m || echo "    (continuing past failure on $rel)"
  done <<< "$releases"
else
  echo "    (no releases found)"
fi

# ── 2) Best-effort namespaced resource cleanup ──────────────────────────────
# helm uninstall doesn't always remove PVCs (storage class retention) or
# resources created by hooks. Sweep what's left without touching the namespace.
echo "==> Sweeping remaining namespaced resources in $NS"
for kind in \
    httproute gateway certificate \
    deployment statefulset daemonset replicaset \
    job cronjob \
    service endpoints \
    configmap pvc pod ingress; do
  echo "    delete all $kind"
  k delete "$kind" --all --ignore-not-found --timeout=2m || true
done

# Secrets last — leave harbor-pull-secret in place so the next pipeline
# doesn't have to re-create it. Everything else goes.
echo "==> Deleting secrets in $NS (preserving harbor-pull-secret)"
k get secret -o name 2>/dev/null \
  | grep -v '^secret/harbor-pull-secret$' \
  | grep -v '^secret/default-token-' \
  | xargs -r -I{} bash -c 'guard; kubectl -n "'"$NS"'" delete {} --ignore-not-found' \
  || true

# ── 3) Final state ──────────────────────────────────────────────────────────
echo "==> Remaining in $NS (should be empty or just the pull secret):"
k get all,pvc,configmap,secret 2>/dev/null || true

guard  # one more belt-and-suspenders before exit
echo "==> Teardown of $NS complete."
