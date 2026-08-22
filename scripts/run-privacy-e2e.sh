#!/usr/bin/env bash
# Bootstrap and verify the smallest upstream generic privacy E2E entrypoint.
# This script never runs BackerZero ComputeAndInvoke and never broadcasts mainnet transactions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_ROOT="${TOOLS_ROOT:-$ROOT/poc/compute-and-invoke/.tools}"
PRIVACY_ROOT="${PRIVACY_ROOT:-/tmp/starknet-privacy-b59d8a1}"

source "$ROOT/scripts/privacy-env.sh"

UPSTREAM_ROOT="$PRIVACY_ROOT"
ARCH="x86_64-unknown-linux-gnu"
CHECKSUM_MANIFEST="$ROOT/scripts/privacy-artifacts.sha256"

say() { printf '\n== %s ==\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"; }

checksum_for() {
  local archive="$1" checksum
  [[ -f "$CHECKSUM_MANIFEST" ]] || fail "checksum manifest missing: $CHECKSUM_MANIFEST"
  checksum="$(awk -v archive="$archive" '$1 ~ /^[0-9a-fA-F]{64}$/ && $2 == archive { print tolower($1); exit }' "$CHECKSUM_MANIFEST")"
  [[ -n "$checksum" ]] || fail "no authoritative SHA-256 entry for $archive; refusing unverified download"
  printf '%s\n' "$checksum"
}

validate_members() {
  local archive="$1" member listing mode
  while IFS= read -r member; do
    case "$member" in
      /*|../*|*/../*|..|*/..)
        fail "unsafe archive member $member in $(basename "$archive")"
        ;;
    esac
  done < <(tar -tf "$archive")

  while IFS= read -r listing; do
    mode="${listing:0:1}"
    case "$mode" in
      -|d) ;;
      *) fail "unsafe non-regular archive member in $(basename "$archive"): $listing" ;;
    esac
  done < <(tar -tvf "$archive")
}

fetch_extract() {
  local url="$1" install_root="$2" expected_entry="$3" archive_name tmp stage expected_path
  archive_name="${url##*/}"
  tmp="$(mktemp -p "${TMPDIR:-/tmp}" privacy-tool.XXXXXX)"
  stage="$(mktemp -d -p "${TMPDIR:-/tmp}" privacy-stage.XXXXXX)"
  trap 'rm -f "$tmp"; rm -rf "$stage"' RETURN
  expected_path="$install_root/$expected_entry"

  checksum_for "$archive_name" >/dev/null
  curl --fail --location --retry 3 --connect-timeout 15 --max-time 300 -o "$tmp" "$url"
  printf '%s  %s\n' "$(checksum_for "$archive_name")" "$tmp" | sha256sum -c - >/dev/null
  validate_members "$tmp"
  tar --no-same-owner --no-same-permissions -xf "$tmp" -C "$stage"
  [[ -e "$stage/$expected_entry" ]] || fail "archive $archive_name lacks expected entry $expected_entry"
  [[ ! -e "$expected_path" ]] || fail "refusing to merge archive into existing path $expected_path"
  mkdir -p "$install_root"
  mv "$stage/$expected_entry" "$expected_path"
  rm -f "$tmp"
  rm -rf "$stage"
  trap - RETURN
}

bootstrap() {
  need_cmd curl
  need_cmd sha256sum
  need_cmd tar
  mkdir -p "$TOOLS_ROOT"

  if [[ ! -x "$TOOLS_ROOT/node-v${NODE_VERSION}-linux-x64/bin/node" ]]; then
    say "Node ${NODE_VERSION}"
    fetch_extract "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
      "$TOOLS_ROOT" "node-v${NODE_VERSION}-linux-x64"
  fi

  local scarb_dir="scarb-v${SCARB_VERSION}-${ARCH}"
  local foundry_dir="starknet-foundry-v${STARKNET_FOUNDRY_VERSION}-${ARCH}"
  local devnet_dir="starknet-devnet-v${DEVNET_VERSION}"

  if [[ ! -x "$TOOLS_ROOT/$scarb_dir/bin/scarb" ]]; then
    say "Scarb ${SCARB_VERSION}"
    fetch_extract "https://github.com/software-mansion/scarb/releases/download/v${SCARB_VERSION}/scarb-v${SCARB_VERSION}-${ARCH}.tar.gz" \
      "$TOOLS_ROOT" "$scarb_dir"
  fi

  if [[ ! -x "$TOOLS_ROOT/$foundry_dir/bin/snforge" ]]; then
    say "Starknet Foundry ${STARKNET_FOUNDRY_VERSION}"
    fetch_extract "https://github.com/foundry-rs/starknet-foundry/releases/download/v${STARKNET_FOUNDRY_VERSION}/starknet-foundry-v${STARKNET_FOUNDRY_VERSION}-${ARCH}.tar.gz" \
      "$TOOLS_ROOT" "$foundry_dir"
  fi

  if [[ ! -x "$TOOLS_ROOT/$devnet_dir/bin/starknet-devnet" ]]; then
    say "starknet-devnet ${DEVNET_VERSION}"
    fetch_extract "https://github.com/starknet-io/starknet-devnet/releases/download/v${DEVNET_VERSION}/starknet-devnet-${ARCH}.tar.gz" \
      "$TOOLS_ROOT/$devnet_dir/bin" "starknet-devnet"
  fi

  export SCARB_DIR="$TOOLS_ROOT/$scarb_dir" FOUNDRY_DIR="$TOOLS_ROOT/$foundry_dir" DEVNET_DIR="$TOOLS_ROOT/$devnet_dir"
  export PATH="$SCARB_DIR/bin:$FOUNDRY_DIR/bin:$DEVNET_DIR/bin:$TOOLS_ROOT/node-v${NODE_VERSION}-linux-x64/bin:$PATH"

  say "toolchain"
  node --version
  scarb --version
  snforge --version
  sncast --version
  starknet-devnet --version
}

verify_source() {
  local actual_commit remote_url status_output
  say "pinned upstream source"
  need_cmd git
  [[ -d "$UPSTREAM_ROOT/.git" ]] || fail "upstream checkout missing: $UPSTREAM_ROOT"
  actual_commit="$(git -C "$UPSTREAM_ROOT" rev-parse HEAD)"
  [[ "$actual_commit" == "$PRIVACY_COMMIT" ]] || fail "upstream checkout commit $actual_commit does not match immutable pin $PRIVACY_COMMIT"
  remote_url="$(git -C "$UPSTREAM_ROOT" remote get-url origin 2>/dev/null || true)"
  [[ "$remote_url" == "https://github.com/starkware-libs/starknet-privacy.git" || "$remote_url" == "git@github.com:starkware-libs/starknet-privacy.git" ]] || fail "upstream origin is not the official starkware-libs/starknet-privacy repository"
  status_output="$(git -C "$UPSTREAM_ROOT" status --porcelain=v1)"
  [[ -z "$status_output" ]] || fail "upstream checkout has git status --porcelain=v1 output:\n$status_output"
  [[ -z "$(git -C "$UPSTREAM_ROOT" submodule status --recursive)" ]] || fail "upstream checkout has unverified submodule state"
  grep -q 'transaction-prover:PRIVACY-0.14.3-RC.2' "$UPSTREAM_ROOT/README.md" || fail "expected prover image tag absent from pinned README"
  grep -q 'version": "0.14.3-rc.5"' "$UPSTREAM_ROOT/sdk/package.json" || fail "expected SDK version absent from pinned source"
  grep -q 'createPrivateTransfers' "$UPSTREAM_ROOT/sdk/src/factory.ts" || fail "expected SDK private-transfer factory absent"
  grep -q 'ProvingServiceProofProvider' "$UPSTREAM_ROOT/sdk/src/internal/proving-service-provider.ts" || fail "expected proving provider absent"
  grep -q 'ContractDiscoveryProvider' "$UPSTREAM_ROOT/sdk/src/internal/contract-discovery.ts" || fail "expected contract discovery provider absent"
  printf 'source=OK verified_commit=%s\n' "$actual_commit"
}

verify_hosted_contract() {
  # Deliberately unconditional until an independently sourced and executable
  # upstream health/spec/request/proof contract is established. A repository
  # env file cannot self-attest that an undocumented contract is verified.
  fail "hosted prover health/spec/request/proof contract is unavailable from pinned upstream evidence; refusing guessed invocation"
}

run_upstream_fast_checks() {
  verify_source
  say "upstream dependency install"
  (cd "$UPSTREAM_ROOT/sdk" && npm ci)
  (cd "$UPSTREAM_ROOT/client" && npm ci)
  (cd "$UPSTREAM_ROOT/e2e" && npm ci)
  say "upstream builds"
  (cd "$UPSTREAM_ROOT/sdk" && npm run build)
  (cd "$UPSTREAM_ROOT/client" && npm run build)
  (cd "$UPSTREAM_ROOT/e2e" && npm run typecheck)
  say "smallest generic upstream E2E attempt"
  if [[ "${RUN_DEVNET:-0}" != "1" ]]; then
    printf 'NOT_RUN: set RUN_DEVNET=1 after configuring disposable local E2E fixtures; no mock is evidence of real proving.\n'
    return 0
  fi
  (cd "$UPSTREAM_ROOT/e2e" && npm run test:devnet -- tests/devnet/smoke.test.ts)
}

case "${1:-status}" in
  --bootstrap|bootstrap) bootstrap ;;
  --verify-source|verify-source) verify_source ;;
  --verify-hosted-contract|verify-hosted-contract) verify_hosted_contract ;;
  --upstream-fast-checks|upstream-fast-checks) run_upstream_fast_checks ;;
  --status|status) source "$ROOT/scripts/privacy-env.sh"; privacy_env_status ;;
  *) printf 'usage: %s [--bootstrap|--verify-source|--verify-hosted-contract|--upstream-fast-checks|--status]\n' "$0" >&2; exit 2 ;;
esac
