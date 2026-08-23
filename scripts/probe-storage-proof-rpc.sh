#!/usr/bin/env bash
# Probe hosted Starknet Sepolia RPC endpoints for the capabilities the official
# transaction prover requires. Ordinary RPC availability does NOT imply
# storage-proof support, so each endpoint is checked for:
#   - starknet_specVersion / starknet_chainId (identity)
#   - starknet_getStorageProof (prover hard requirement)
#   - node implementation/version (pathfinder_version / juno_version)
#   - large-request-body tolerance (DECLARE payloads)
#
# Usage: scripts/probe-storage-proof-rpc.sh [url ...]
set -uo pipefail

DEFAULT_URLS=(
  "https://starknet-sepolia-rpc.publicnode.com"
  "https://api.cartridge.gg/x/starknet/sepolia"
  "https://api.zan.top/starknet-sepolia"
  "https://starknet-sepolia.drpc.org"
)
URLS=("${@:-}")
[[ -z "${URLS[0]:-}" ]] && URLS=("${DEFAULT_URLS[@]}")

rpc() { # url method params
  curl -s --max-time 45 -H 'content-type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$2\",\"params\":$3}" "$1"
}

for url in "${URLS[@]}"; do
  echo "=== $url"
  echo -n "  specVersion : "; rpc "$url" starknet_specVersion '[]' | head -c 200; echo
  echo -n "  chainId     : "; rpc "$url" starknet_chainId '[]' | head -c 200; echo
  echo -n "  storageProof: "
  rpc "$url" starknet_getStorageProof \
    '{"block_id":"latest","class_hashes":[],"contract_addresses":[],"contracts_storage_keys":[]}' \
    | head -c 300; echo
  echo -n "  pathfinder  : "; rpc "$url" pathfinder_version '[]' | head -c 120; echo
  echo -n "  juno        : "; rpc "$url" juno_version '[]' | head -c 120; echo
  # ~1.5 MiB body: DECLARE payloads for the privacy pool class exceed 1 MiB.
  body=$(mktemp)
  { printf '{"jsonrpc":"2.0","id":1,"method":"starknet_specVersion","params":["'
    head -c 1500000 /dev/zero | tr '\0' 'a'
    printf '"]}'; } > "$body"
  echo -n "  bigBody     : "
  curl -s --max-time 60 -H 'content-type: application/json' \
    --data-binary "@$body" "$url" | head -c 200; echo
  rm -f "$body"
done
