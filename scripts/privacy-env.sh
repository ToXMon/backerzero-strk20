#!/usr/bin/env bash
# Reproducible local toolchain selectors for the pinned starknet-privacy investigation.
# Security pins are immutable here; environment variables may select paths only.
set -euo pipefail

PRIVACY_ROOT="${PRIVACY_ROOT:-/tmp/starknet-privacy-b59d8a1}"
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_ROOT="${TOOLS_ROOT:-$SCRIPT_ROOT/../poc/compute-and-invoke/.tools}"

set_immutable_pin() {
  local name="$1" expected="$2" current="${!1-}"
  if [[ -n "$current" ]]; then
    [[ "$current" == "$expected" ]] || {
      printf 'ERROR: %s immutable pin %q does not match expected %q\n' "$name" "$current" "$expected" >&2
      return 1
    }
    readonly "$name"
    return 0
  fi
  printf -v "$name" '%s' "$expected"
  readonly "$name"
}

set_immutable_pin PRIVACY_COMMIT_EXPECTED "b59d8a141e49a9d940fb14dfe935cbecb8202814"
set_immutable_pin NODE_VERSION_EXPECTED "24.8.0"
set_immutable_pin SCARB_VERSION_EXPECTED "2.18.0"
set_immutable_pin STARKNET_FOUNDRY_VERSION_EXPECTED "0.63.0"
set_immutable_pin DEVNET_VERSION_EXPECTED "0.8.0-rc.3"

pin_or_fail() {
  local name="$1" expected="$2" supplied="${!1-}"
  if [[ -n "$supplied" ]]; then
    [[ "$supplied" == "$expected" ]] || {
      printf 'ERROR: %s override %q does not match immutable pin %q\n' "$name" "$supplied" "$expected" >&2
      return 1
    }
    # Do not reassign an already-correct value: callers may source this file
    # repeatedly from a shell where the exported pin is readonly.
    export "$name"
    return 0
  fi
  printf -v "$name" '%s' "$expected"
  export "$name"
}

pin_or_fail PRIVACY_COMMIT "$PRIVACY_COMMIT_EXPECTED"
pin_or_fail NODE_VERSION "$NODE_VERSION_EXPECTED"
pin_or_fail SCARB_VERSION "$SCARB_VERSION_EXPECTED"
pin_or_fail STARKNET_FOUNDRY_VERSION "$STARKNET_FOUNDRY_VERSION_EXPECTED"
pin_or_fail DEVNET_VERSION "$DEVNET_VERSION_EXPECTED"

export PRIVACY_ROOT TOOLS_ROOT
export PATH="$TOOLS_ROOT/node-v${NODE_VERSION}-linux-x64/bin:$TOOLS_ROOT/scarb-v${SCARB_VERSION}-x86_64-unknown-linux-gnu/bin:$TOOLS_ROOT/starknet-foundry-v${STARKNET_FOUNDRY_VERSION}-x86_64-unknown-linux-gnu/bin:$TOOLS_ROOT/starknet-devnet-v${DEVNET_VERSION}/bin:$PATH"

privacy_env_status() {
  printf 'PRIVACY_ROOT=%s\n' "$PRIVACY_ROOT"
  printf 'PRIVACY_COMMIT=%s\n' "$PRIVACY_COMMIT"
  printf 'TOOLS_ROOT=%s\n' "$TOOLS_ROOT"
  printf 'node=%s\n' "$(command -v node || printf missing)"
  printf 'scarb=%s\n' "$(command -v scarb || printf missing)"
  printf 'snforge=%s\n' "$(command -v snforge || printf missing)"
  printf 'sncast=%s\n' "$(command -v sncast || printf missing)"
  printf 'starknet-devnet=%s\n' "$(command -v starknet-devnet || printf missing)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  privacy_env_status
fi
