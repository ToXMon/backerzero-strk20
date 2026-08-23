#!/usr/bin/env bash
# Prompt 4 Part B/C/D reproduction: start the official transaction prover, run the
# real-prover privacy lifecycle attempt (Part C) and the ComputeAndInvoke
# conformance/negative tests (Part D) inside the pinned upstream checkout.
#
# Never broadcasts mainnet transactions and never uses real funds. All identities
# are disposable devnet accounts; no private material is written to the repository.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIVACY_ROOT="${PRIVACY_ROOT:-/tmp/starknet-privacy-b59d8a1}"
DEVNET_URL="${DEVNET_URL:-http://127.0.0.1:5050}"
PROVER_URL="${PROVER_URL:-http://127.0.0.1:3000}"
PROVER_NAME="${PROVER_NAME:-prover}"

# Immutable platform manifests of ghcr.io/.../transaction-prover:PRIVACY-0.14.3-RC.2
# (see scripts/privacy-image-digest.txt for how these were verified).
PROVER_AMD64="ghcr.io/starkware-libs/starknet-privacy/transaction-prover@sha256:a62e7764e034ea25d84d4a235f1f683f7c5f03f88f6646a744599171bf5ca58c"
PROVER_ARM64="ghcr.io/starkware-libs/starknet-privacy/transaction-prover@sha256:9882d27692b420a9edae9b50bf8075103044230de0f83ee6bed3db19cace105f"

say() { printf '\n== %s ==\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "$PRIVACY_ROOT" ]] || fail "pinned upstream checkout missing at $PRIVACY_ROOT (see scripts/run-privacy-e2e.sh)"
command -v docker >/dev/null || fail "docker is required"

# The linux/amd64 prover binary contains AMD-only SSE4a instructions (EXTRQ/INSERTQ)
# and aborts with SIGILL on Intel hosts, so default to the arm64 manifest under
# qemu-user emulation, which starts and serves proving requests on x86 hosts.
PROVER_IMAGE="${PROVER_IMAGE:-$PROVER_ARM64}"
if [[ "${PROVER_PLATFORM:-arm64}" == "amd64" ]]; then PROVER_IMAGE="$PROVER_AMD64"; fi

say "prover: $PROVER_IMAGE"
docker pull "$PROVER_IMAGE"
docker rm -f "$PROVER_NAME" >/dev/null 2>&1 || true
docker run -d --name "$PROVER_NAME" --network host \
  -e RPC_URL="$DEVNET_URL" \
  -e CHAIN_ID=SN_SEPOLIA \
  -e PROVER_PORT=3000 \
  -e RUST_LOG=info \
  "$PROVER_IMAGE" >/dev/null

say "waiting for prover readiness on $PROVER_URL"
for _ in $(seq 1 120); do
  if curl -sf -X POST "$PROVER_URL" -H 'content-type: application/json' \
      -d '{"jsonrpc":"2.0","id":1,"method":"starknet_specVersion"}' >/dev/null; then
    break
  fi
  sleep 5
done
curl -s -X POST "$PROVER_URL" -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"starknet_specVersion"}'
echo

# Known blocker, recorded so a re-run reproduces it without reading the logs:
# starknet_proveTransaction needs starknet_getStorageProof from the RPC node, which
# starknet-devnet does not implement (JSON-RPC error 42). The upstream compatibility
# row therefore pairs the prover with Pathfinder v0.22.7 on a live network.
say "RPC storage-proof support of $DEVNET_URL"
curl -s -X POST "$DEVNET_URL" -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"starknet_getStorageProof","params":{"block_id":"latest","class_hashes":[],"contract_addresses":[],"contracts_storage_keys":[]}}'
echo

say "installing POC tests into the pinned upstream checkout"
cp "$ROOT"/poc/compute-and-invoke/e2e/bz-*.ts "$PRIVACY_ROOT/e2e/tests/devnet/"

say "Part C — real-prover privacy lifecycle (expects a real proof; currently blocked)"
(cd "$PRIVACY_ROOT/e2e" && npx vitest run tests/devnet/bz-real-proof.test.ts) || true

say "Part D — ComputeAndInvoke conformance + negative tests"
(cd "$PRIVACY_ROOT/e2e" && BZ_PART_D_RESULTS="$ROOT/poc/compute-and-invoke/e2e/evidence/part-d-results.json" \
  npx vitest run tests/devnet/bz-compute-invoke.test.ts)

say "done"
