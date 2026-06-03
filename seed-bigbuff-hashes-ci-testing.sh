#!/usr/bin/env bash
#
# Seed 100 pre-computed (seed, hash) pairs into the ci-testing namespace's
# bigbuff_hashes table by copying from staging. The BotBlocker hasher pod
# is disabled in ci-testing (numHashers: "0") so without this seed the
# bigbuff_hashes table would stay empty and /v1/botblocker/getSeed would
# 500/502 — same failure mode that hit the staging environment when the
# hasher deployment scaled to zero (memory note: botblocker-hasher.md).
#
# Read-only on the staging side. Write-only to ci-testing. Hard-coded
# namespaces — same paranoia as teardown-ci-testing.sh.
set -euo pipefail

readonly SRC_NS="staging"
readonly DST_NS="ci-testing"
readonly SAMPLE_SIZE=100

if [[ "$DST_NS" != "ci-testing" ]]; then
  echo "FATAL: this script writes only to ci-testing; refusing to run." >&2
  exit 99
fi

echo "==> Dumping $SAMPLE_SIZE bigbuff_hashes rows from $SRC_NS into a SQL fixture"

# Find the staging DB pod (pattern matches both `freelight-dao-db-0`
# (StatefulSet) and any rename, but is scoped to $SRC_NS).
src_pod="$(kubectl -n "$SRC_NS" get pods -l app.kubernetes.io/component=db -o name 2>/dev/null \
  | head -1 \
  | sed 's|pod/||')"
# Fallback for older labels.
if [[ -z "$src_pod" ]]; then
  src_pod="freelight-dao-db-0"
fi
if ! kubectl -n "$SRC_NS" get pod "$src_pod" >/dev/null 2>&1; then
  echo "FATAL: couldn't find staging postgres pod ($src_pod)." >&2
  exit 1
fi
echo "    source pod: $SRC_NS/$src_pod"

# Find the ci-testing DB pod — must exist (freelight-dao chart deploys it).
dst_pod="$(kubectl -n "$DST_NS" get pods -l app.kubernetes.io/component=db -o name 2>/dev/null \
  | head -1 \
  | sed 's|pod/||')"
if [[ -z "$dst_pod" ]]; then
  dst_pod="freelight-dao-db-0"
fi
if ! kubectl -n "$DST_NS" get pod "$dst_pod" >/dev/null 2>&1; then
  echo "FATAL: couldn't find ci-testing postgres pod ($dst_pod). Did the freelight-dao chart finish installing?" >&2
  exit 1
fi
echo "    destination pod: $DST_NS/$dst_pod"

# Wait for ci-testing postgres to actually accept connections.
echo "==> Waiting for ci-testing postgres to be ready"
for i in $(seq 1 30); do
  if kubectl -n "$DST_NS" exec "$dst_pod" -- pg_isready -U freelight -d freelight >/dev/null 2>&1; then
    echo "    ready"; break
  fi
  sleep 2
done

# Check that bigbuff_hashes table exists in ci-testing — created by the
# DAO chart's db-init migrations. If it isn't there yet, we can't seed.
if ! kubectl -n "$DST_NS" exec "$dst_pod" -- psql -U freelight -d freelight -tAc \
    "SELECT to_regclass('public.bigbuff_hashes');" 2>/dev/null \
    | grep -q "bigbuff_hashes"; then
  echo "FATAL: bigbuff_hashes table not present in ci-testing yet — migrations haven't run." >&2
  exit 1
fi

# Pull SAMPLE_SIZE rows out of staging as plain INSERT statements. Skip
# `num_uses` and `created_date` so the destination uses defaults. The
# `password` (seed) and `hash` columns are what BotBlocker needs to verify
# a client's submitted proof-of-work.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
echo "==> Pulling $SAMPLE_SIZE rows from $SRC_NS"
kubectl -n "$SRC_NS" exec "$src_pod" -- bash -lc "
  psql -U freelight -d freelight -At -F $'\t' -c \"
    SELECT id, hash_type::text, hash, password
    FROM bigbuff_hashes
    ORDER BY num_uses ASC
    LIMIT $SAMPLE_SIZE;
  \"
" > "$tmp"

count="$(wc -l < "$tmp")"
echo "    pulled $count rows"
if [[ "$count" -lt 1 ]]; then
  echo "FATAL: dumped 0 rows; staging table looks empty." >&2
  exit 1
fi

# Build the COPY statement. Using COPY (not INSERT) keeps it fast +
# avoids parser issues with the binary-looking hash data.
echo "==> Loading rows into $DST_NS"
{
  echo "BEGIN;"
  echo "TRUNCATE bigbuff_hashes;"
  echo "COPY bigbuff_hashes (id, hash_type, hash, password) FROM STDIN WITH (FORMAT text, DELIMITER E'\\t');"
  cat "$tmp"
  echo "\\."
  echo "COMMIT;"
} | kubectl -n "$DST_NS" exec -i "$dst_pod" -- psql -U freelight -d freelight -v ON_ERROR_STOP=1

# Verify.
loaded="$(kubectl -n "$DST_NS" exec "$dst_pod" -- psql -U freelight -d freelight -tAc \
  "SELECT COUNT(*) FROM bigbuff_hashes;" | tr -d '[:space:]')"
echo "==> bigbuff_hashes in $DST_NS now contains $loaded rows."

if [[ "$loaded" -ne "$count" ]]; then
  echo "WARN: expected $count rows, got $loaded." >&2
fi
