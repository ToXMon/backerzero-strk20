#!/usr/bin/env bash
# Prompt 4 Part C — hosted Starknet Sepolia real-proof reproduction.
#
# Starts an RPC capability proxy and the official transaction prover, then runs
# the smallest real-proof privacy lifecycle (STRK approve, deposit, real proof,
# executeFromOutside, note discovery) against a live Sepolia privacy-pool.
#
# Never broadcasts mainnet transactions and never uses real funds. All identities
# are disposable Sepolia testnet accounts; no private material is written to the
# repository.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${PRIVACY_ROOT:-}" ]]; then
  for d in /home/ubuntu/starknet-privacy /tmp/starknet-privacy-b59d8a1; do
    [[ -d "$d" ]] && { PRIVACY_ROOT="$d"; break; }
  done
fi
PROVER_URL="${PROVER_URL:-http://127.0.0.1:3000}"
PROXY_PORT="${BZ_PROXY_PORT:-8547}"
PROVER_NAME="${PROVER_NAME:-bz-prover}"
PROXY_NAME="${BZ_PROXY_NAME:-bz-rpc-proxy}"

# Immutable platform manifests of ghcr.io/.../transaction-prover:PRIVACY-0.14.3-RC.2
PROVER_AMD64="ghcr.io/starkware-libs/starknet-privacy/transaction-prover@sha256:a62e7764e034ea25d84d4a235f1f683f7c5f03f88f6646a744599171bf5ca58c"
PROVER_ARM64="ghcr.io/starkware-libs/starknet-privacy/transaction-prover@sha256:9882d27692b420a9edae9b50bf8075103044230de0f83ee6bed3db19cace105f"

say() { printf '\n== %s ==\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "$PRIVACY_ROOT" ]] || fail "pinned upstream checkout missing at $PRIVACY_ROOT (clone starkware-libs/starknet-privacy at commit b59d8a141e49a9d940fb14dfe935cbecb8202814 and build it)"
command -v docker >/dev/null || fail "docker is required"
command -v python3 >/dev/null || fail "python3 is required"

# Prefer the arm64 image: the amd64 binary contains AMD-only SSE4a instructions
# and SIGILLs on Intel hosts. ARM64 runs under qemu-user on x86_64.
PROVER_IMAGE="${PROVER_IMAGE:-$PROVER_ARM64}"
if [[ "${PROVER_PLATFORM:-arm64}" == "amd64" ]]; then PROVER_IMAGE="$PROVER_AMD64"; fi

# Default Sepolia endpoints. The proxy lets the prover use PublicNode for full
# v0.10 block headers and Cartridge/Alchemy for storage proofs.
BZ_RPC_URL="${BZ_RPC_URL:-https://starknet-sepolia-rpc.publicnode.com}"
BZ_TX_RPC_URL="${BZ_TX_RPC_URL:-https://api.cartridge.gg/x/starknet/sepolia}"
BZ_WS_URL="${BZ_WS_URL:-wss://starknet-sepolia-rpc.publicnode.com}"
BZ_ACCOUNTS_FILE="${BZ_ACCOUNTS_FILE:-$HOME/.bz-sepolia/accounts.json}"

# The privacy-pool class is already declared on Sepolia for PRIVACY-0.14.3-RC.0.
# Set BZ_POOL_ADDRESS to skip redeployment.
BZ_POOL_ADDRESS="${BZ_POOL_ADDRESS:-}"
BZ_VIEWING_KEY="${BZ_VIEWING_KEY:-0xA11CE}"
BZ_DEPOSIT_AMOUNT="${BZ_DEPOSIT_AMOUNT:-1000000000000000}"
BZ_PROVING_BLOCK_LAG="${BZ_PROVING_BLOCK_LAG:-11}"
BZ_PROVE_TIMEOUT_MS="${BZ_PROVE_TIMEOUT_MS:-7200000}"
BZ_EVIDENCE_FILE="${BZ_EVIDENCE_FILE:-$ROOT/poc/compute-and-invoke/e2e/evidence/sepolia-real-proof.json}"

say "starting RPC capability proxy on :$PROXY_PORT"
python3 "$ROOT/scripts/rpc-capability-proxy.py" \
  --port "$PROXY_PORT" \
  --header-url "$BZ_RPC_URL" \
  --proof-url "$BZ_TX_RPC_URL" &
PROXY_PID=$!
trap 'docker rm -f "$PROVER_NAME" >/dev/null 2>&1 || true; kill "$PROXY_PID" >/dev/null 2>&1 || true' EXIT

say "pulling/starting prover: $PROVER_IMAGE"
docker pull "$PROVER_IMAGE"
docker rm -f "$PROVER_NAME" >/dev/null 2>&1 || true
docker run -d --name "$PROVER_NAME" --network host \
  --platform linux/arm64 \
  -e RPC_URL="http://127.0.0.1:$PROXY_PORT" \
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

say "installing POC tests into the pinned upstream checkout"
shopt -s nullglob
for f in "$ROOT/poc/compute-and-invoke/e2e/"bz-sepolia-*.ts; do
  cp "$f" "$PRIVACY_ROOT/e2e/tests/integration/"
done
shopt -u nullglob

say "Part C — real-prover privacy lifecycle on Sepolia"
(
  cd "$PRIVACY_ROOT/e2e" && \
  BZ_RPC_URL="http://127.0.0.1:$PROXY_PORT" \
  BZ_TX_RPC_URL="$BZ_TX_RPC_URL" \
  BZ_WS_URL="$BZ_WS_URL" \
  BZ_ACCOUNTS_FILE="$BZ_ACCOUNTS_FILE" \
  BZ_POOL_ADDRESS="$BZ_POOL_ADDRESS" \
  BZ_VIEWING_KEY="$BZ_VIEWING_KEY" \
  BZ_DEPOSIT_AMOUNT="$BZ_DEPOSIT_AMOUNT" \
  BZ_PROVING_BLOCK_LAG="$BZ_PROVING_BLOCK_LAG" \
  BZ_PROVE_TIMEOUT_MS="$BZ_PROVE_TIMEOUT_MS" \
  BZ_EVIDENCE_FILE="$BZ_EVIDENCE_FILE" \
    npx vitest run tests/integration/bz-sepolia-real-proof.test.ts
) || true

say "done; evidence (if produced) is at $BZ_EVIDENCE_FILE"
