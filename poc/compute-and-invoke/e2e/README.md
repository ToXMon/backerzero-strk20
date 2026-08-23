# Prompt 4 privacy E2E POC (real prover + ComputeAndInvoke)

These tests run inside the pinned upstream checkout of
`starkware-libs/starknet-privacy` at commit
`b59d8a141e49a9d940fb14dfe935cbecb8202814`; they import that repository's e2e
harness, so they are installed into `e2e/tests/devnet/` (Part D) and
`e2e/tests/integration/` (Sepolia Part C) by `scripts/run-privacy-real-proof.sh`
rather than executed from this directory.

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

All accounts are disposable devnet/Sepolia test accounts. No private key, viewing
key, or receipt secret is committed here or written to `evidence/`.

## Sepolia real-proof success (Prompt 4 Part C, hosted)

Files:

- `bz-sepolia-harness.ts` — loads disposable funded Sepolia accounts (public
  addresses only are committed), deploys a fresh pool from the already-declared
  class, and wires the real `ProvingServiceProofProvider` against a local
  capability proxy.
- `bz-sepolia-real-proof.test.ts` — smallest real-proof lifecycle on Sepolia:
  STRK approve, deposit with real proof, `executeFromOutside` settlement, and
  indexer note discovery.

`scripts/run-privacy-real-proof.sh` starts the RPC capability proxy and the
prover (or a local source-built binary when the official `linux/amd64` image
SIGILLs on the host), then runs the Sepolia test in the pinned upstream checkout.

Latest successful real-proof evidence:

| Field | Value |
| --- | --- |
| Pool class | `0x52107fadffab71bdcbb6b2ccb68ba3e1b5558d94036538053e159d3076ad633` |
| Pool instance | `0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce` |
| Pool deployment tx | `0x04635f2c6dd6de27aadd61426bce328dcabff27751f53cdedd5de0e246f72d96` |
| STRK approve tx | `0x119d289a9d654dc3617aed5fbcd8bc0132af4e7e790f47884a88665f4310d71` |
| Proving block | `13920374` |
| Proving time | `26794 ms` |
| Proof facts | `9` |
| Proof data bytes | `305732` |
| Settlement tx | `0x57ba2ec108d116ae5f8851d95ae1b840526f85947ec4bb739acbc7c9dfc1098` |
| Notes discovered | `1` |

The settlement receipt reports `execution_status: SUCCEEDED` and
`finality_status: ACCEPTED_ON_L2` on Sepolia block `13920409`.

## Evidence

- `evidence/sepolia-real-proof.json` — latest successful Part C run evidence.
- `evidence/part-d-results.json` — per-test outcome of the Part D positive path
  and the five negative tests.
- `evidence/sepolia-prover-*.log` and `evidence/sepolia-real-proof-*.log` —
  prior run logs (kept for comparison; may include failed attempts).

## Part D result caveat

Part D runs on the upstream devnet harness, whose proof provider is
`ScreeningCallMockProofProvider` (a real proof is unobtainable on devnet because
`starknet-devnet` does not implement `starknet_getStorageProof`). The negative
tests therefore demonstrate the **pool contract's** binding and nullifier logic
— tampering the public outside-execution calldata after authorization fails with
`INVALID_PROOF_MSG`, and re-executing a consumed authorization fails with
`NON_ZERO_VALUE` — while the soundness of the proof itself is exercised by the
separate Sepolia real-proof run. Treat Part D as conformance and binding
evidence plus the real-proof run as cryptographic verification.
