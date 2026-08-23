# Project State

- Project: BackerZero
- Slug: `backerzero-strk20`
- Current phase: Technical verification / authorization gate — **Prompt 4 complete**
- Prompt 4 classification: **GO_FULL**
- Architecture status: The official privacy runtime row is established, a real generic privacy proof lifecycle is verified on Starknet Sepolia, and the identity-bound `ComputeAndInvoke` authorization/negative-test suite passes. Prompt 5 is cleared for all four MVP flows.

## Prompt 4 verification results

| Gate | Result | Evidence |
| --- | --- | --- |
| Generic real-proof E2E | **PASS** | `poc/compute-and-invoke/e2e/evidence/sepolia-real-proof.json` |
| Settlement | **PASS** | Sepolia tx `0x57ba2ec108d116ae5f8851d95ae1b840526f85947ec4bb739acbc7c9dfc1098` (ACCEPTED_ON_L2, SUCCEEDED) |
| Note discovery | **PASS** | `discoveredNotes: 1` in the evidence file |
| ComputeAndInvoke | **PASS** | `poc/compute-and-invoke/e2e/evidence/part-d-results.json` |
| Replay | **PASS** | `NON_ZERO_VALUE` revert |
| Destination substitution | **PASS** | `INVALID_PROOF_MSG` revert |
| Amount substitution | **PASS** | `INVALID_PROOF_MSG` revert |
| Calldata/action substitution | **PASS** | `INVALID_PROOF_MSG` revert |
| Wrong context | **PASS** | `INVALID_PROOF_MSG` revert or value not tamperable (committed in proof inputs) |
| Refund authorization | **APPROVED_FOR_BUILD** | Identity-bound `ComputeAndInvoke` demonstrated; bearer-secret refund remains rejected |
| Prompt 5 | **CLEARED_FULL** | All four flows may be implemented |

## Privacy runtime row

- Image: `ghcr.io/starkware-libs/starknet-privacy/transaction-prover:PRIVACY-0.14.3-RC.2`
- OCI index digest: `sha256:a2f71d7139069fa566c4f44bdd66b79cac992c0cbc20ddf0af3a3558c6cabd64`
- linux/amd64 digest: `sha256:a62e7764e034ea25d84d4a235f1f683f7c5f03f88f6646a744599171bf5ca58c`
- linux/arm64 digest: `sha256:9882d27692b420a9edae9b50bf8075103044230de0f83ee6bed3db19cace105f`
- Prover binary version: `0.19.0-rc.2`
- Prover RPC spec version: `0.10.3-rc.2`
- Upstream source commit: `b59d8a141e49a9d940fb14dfe935cbecb8202814`
- Prover source commit (binary label): `e6b6fd2e9932909107833579e5b6efd6c75fa0af`
- SDK package version: `0.14.3-rc.5` (in-repo at the pinned commit)
- Privacy contracts: `PRIVACY-0.14.3-RC.0`
- Discovery/service version: `PRIVACY-0.14.3-RC.2`
- Node dependency: Pathfinder `v0.22.7`; devnet `v0.8.0-rc.3`

**Execution note:** the official `linux/amd64` image contains AMD-only SSE4a `EXTRQ`/`INSERTQ` instructions and exits with SIGILL (code 132) on the Intel host. The same source revision was built natively with `-C target-cpu=x86-64` and used for the Sepolia real-proof run. The source, binary version, and RPC spec match the official image row; the local build is a CPU-compatibility workaround, not a different runtime version.

## Real-proof execution summary

- Pool class already declared on Sepolia: `0x52107fadffab71bdcbb6b2ccb68ba3e1b5558d94036538053e159d3076ad633`
- Fresh pool deployed: `0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce` (tx `0x04635f2c6dd6de27aadd61426bce328dcabff27751f53cdedd5de0e246f72d96`)
- RPC capability proxy: PublicNode Sepolia for full v0.10 block headers + ZAN Sepolia for storage proofs
- Prover: source-built `starknet_transaction_prover` at `/tmp/sequencer-shallow/target/release/starknet_transaction_prover`
- Approve tx: `0x119d289a9d654dc3617aed5fbcd8bc0132af4e7e790f47884a88665f4310d71`
- Proof generated for block `13920374` in `26794 ms`
- `proofFactsLength`: 9, `proofDataLength`: 305732
- Settlement tx: `0x57ba2ec108d116ae5f8851d95ae1b840526f85947ec4bb739acbc7c9dfc1098`
- Resulting note: discovered through the supported indexer/discovery path (`discoveredNotes: 1`)

## ComputeAndInvoke conformance summary

The Part D POC (`poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts`) was run against the upstream devnet harness using the same SDK `computeAndInvoke` builder that would be used on mainnet. It demonstrates:

- Positive path: a `computeAndInvoke` authorization settles a payout into the intended open note.
- Authorization is one-time: replay of the same signed/proven authorization reverts with `NON_ZERO_VALUE`.
- Authorization is bound to the open-note destination: changing `note_id` reverts with `INVALID_PROOF_MSG`.
- Authorization is bound to the invoked helper/amount/calldata: tampering the selector, token amount, or target contract reverts with `INVALID_PROOF_MSG`.
- Compute context (`dapp_name`, sequence nonce) is not in public calldata; it is committed in the proof's private inputs and cannot be substituted through the client API.

This establishes the identity-bound, one-time, destination-bound authorization primitive needed for the `Claim Refund` flow.

## Security decisions

- Bearer-secret refund authorization: **REJECTED**.
- Private refund: **APPROVED_FOR_BUILD** via identity-bound `ComputeAndInvoke`, subject to the helper contract enforcing campaign/contribution binding and exact `OpenNoteDeposit` output validation.
- Prompt 5: **CLEARED_FULL**.

## Next action

Begin Prompt 5 MVP implementation: implement the Create Campaign → Back Privately → Claim Funding → Claim Refund flows, starting with the stateful Cairo helper contract and wallet/client integration against the verified `computeAndInvoke` and `OpenNoteDeposit` semantics.
