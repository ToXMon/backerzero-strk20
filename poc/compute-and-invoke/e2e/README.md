# Prompt 4 privacy E2E POC (real prover + ComputeAndInvoke)

These tests run inside the pinned upstream checkout of
`starkware-libs/starknet-privacy` at commit
`b59d8a141e49a9d940fb14dfe935cbecb8202814`; they import that repository's e2e
harness, so they are installed into `e2e/tests/devnet/` by
`scripts/run-privacy-real-proof.sh` rather than executed from this directory.

| File | Part | Purpose |
| --- | --- | --- |
| `bz-harness.ts` | C | E2E environment wired to the **real** `ProvingServiceProofProvider` instead of the upstream mock provider. |
| `bz-real-proof.test.ts` | C | Smallest real-proof lifecycle: deposit + private transfer, proof, outside execution, note discovery. |
| `bz-compute-invoke.test.ts` | D | ComputeAndInvoke positive path plus replay/amount/calldata/destination/context negative tests. |

## Reproduce

```bash
scripts/run-privacy-real-proof.sh
```

Prerequisites: the pinned upstream checkout with a built SDK, contracts, and
discovery service (`scripts/run-privacy-e2e.sh`), plus
`scarb build -t -p shadow_account_anonymizer` and
`(cd e2e/contracts/test-token && scarb build)` in that checkout for the Part D
contracts. Docker is required for the prover.

All accounts are disposable devnet accounts. No private key, viewing key, or
receipt secret is committed here or written to `evidence/`.

## Sepolia real-proof attempt (Prompt 4 Part C, hosted)

Files:

- `bz-sepolia-harness.ts` — loads disposable funded Sepolia accounts (public
  addresses only are committed), deploys a fresh pool from the already-declared
  class, and wires the real `ProvingServiceProofProvider` against a local
  capability proxy.
- `bz-sepolia-real-proof.test.ts` — smallest real-proof lifecycle on Sepolia:
  STRK approve, deposit with real proof, `executeFromOutside` settlement, and
  indexer note discovery.

`scripts/run-privacy-real-proof.sh` starts the RPC capability proxy and the
official prover, then runs the Sepolia test in the pinned upstream checkout.

Current status: the prover starts and reaches `starknet_proveTransaction`, but
**real proof generation cannot complete in this VM**:

- `linux/amd64` image: SIGILL (exit 132) — AMD-only SSE4a instructions.
- `linux/arm64` image: runs under `qemu-user` but a deposit proof takes ~5
  minutes, longer than the ~16-block public storage-proof window on every
  reachable hosted Sepolia RPC.

## Evidence

- `evidence/real-proof-prover.log` — official prover startup and the
  `starknet_proveTransaction` failure: `code 42, "Devnet doesn't support storage
  proofs"`. The prover itself reached the proving stage and returned a clean
  upstream RPC error, so the failure is the RPC node's capability, not the prover.
- `evidence/real-proof-sdk-failure.log` — the same failure surfaced through
  `ProvingService.proveTransaction` in the SDK.
- `evidence/part-d-results.json` — per-test outcome of the Part D positive path
  and the five negative tests.

## Part D result caveat

Part D runs on the upstream devnet harness, whose proof provider is
`ScreeningCallMockProofProvider` (a real proof is unobtainable on devnet, see
above). The negative tests therefore demonstrate the **pool contract's** binding
and nullifier logic — tampering the public outside-execution calldata after
authorization fails with `INVALID_PROOF_MSG`, and re-executing a consumed
authorization fails with `NON_ZERO_VALUE` — while the soundness of the proof
itself is *not* exercised. Treat Part D as conformance and binding evidence,
not as cryptographic verification.
