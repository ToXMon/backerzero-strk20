# BackerZero Technical Verification

**Scope:** Verification of the assumptions in `docs/PRODUCT_SPEC.md`, using `docs/BUILD_PACKET.md` only as supporting reference.

**Source policy:** Current official STRK20/Starknet documentation and the official hackathon/starter repositories only. Snapshot verified: 2026-08-18.

## 1. Hackathon requirements and deadline — VERIFIED

- **Submission deadline:** August 31, 2026 at 23:59 UTC.
- **Scoring:** STRK20 integration depth 30%, working mainnet product 30%, innovation 25%, documentation/open-source quality 15%.
- **Required submission evidence:** public/open-source licensed repository, Starknet mainnet application using the live STRK20 pool, at least three successful mainnet transactions touching the STRK20 pool, public demo URL, and one three-minute demo video.
- The repository README states that the registry PR is the required PR and that the repository state at the deadline is scored; a deployment is not itself listed as a separate submission requirement.

Sources:
- https://strk20.starknet.io/hackathon
- https://github.com/starkience/strk20-hackathon/blob/main/README.md

## 2. `strk20.json` — INCORRECT IN BUILD PACKET / LOCAL FILE MUST BE CHANGED

The packet's proposed manifest shape is directionally correct, but the current local `strk20.json` is not submission-ready: it contains project metadata rather than the documented evidence fields.

The documented root fields are:

- `transactions` — at least three mainnet transaction hashes.
- `contracts` — contract addresses.
- `demo_video` — demo video URL.
- `demo_url` — optional demo URL.

Each transaction must be checked for existence, successful execution, STRK20-pool involvement, and, where applicable, execution through the entrant's contract. Do not add placeholders or unverified hashes.

Source:
- https://github.com/starkience/strk20-hackathon/blob/main/README.md#strk20json

## 3. Wallet API/private transaction flow — VERIFIED

The proposed Wallet API route is current and supported by the cited sources.

- The documented private DeFi flow uses a transfer action with literal amount `OPEN`, followed by an invoke action naming the helper and calldata.
- Wallet-resolved placeholders include `${openNoteIds[N]}` and `${poolAddress}`.
- Preserve these placeholders exactly; do not hex-normalize them.
- `strk20PrepareInvoke(actions, true)` builds, proves, and simulates without submitting.
- `strk20Balances([tokenIn, tokenOut])` reads shielded balances without the dapp handling a viewing key.
- The documented application path is pool → helper → application/external protocol → helper, atomically. The helper/action amounts remain observable while the user link is hidden.

Sources:
- https://strk20-by-example.org/starknet-wallet-api/private-defi
- https://github.com/Akashneelesh/strk20-starter-kit/blob/main/README.md

## 4. `privacy_invoke` behavior — VERIFIED

- The pool withdraws funds, calls the helper's `privacy_invoke`, and deserializes the return as `Span<OpenNoteDeposit>`.
- `OpenNoteDeposit` contains `note_id: felt252`, `token: ContractAddress`, and `amount: u128`.
- The helper must return exactly `Span<OpenNoteDeposit>`.
- The helper should approve the privacy contract rather than directly transferring output tokens.
- An empty span is valid for a stateful helper that retains funds in escrow.
- The protocol permits at most one external invoke per pool transaction.

Pool-only authorization is a required BackerZero design invariant, but the anatomy page documents the protocol pattern; it does not prove a future BackerZero implementation.

Source:
- https://strk20-by-example.org/helpers/privacy-invoke

## 5. OpenNoteDeposit/refund authorization — VERIFIED

The protocol shape needed by BackerZero is documented and the identity-bound
`ComputeAndInvoke` conformance POC has passed:

- A stateful helper can receive a pool-funded private invocation, record state, retain funds by returning an empty span, and later approve the privacy contract and return an `OpenNoteDeposit` for a claim/refund.
- `OpenNoteDeposit` must be handled as the exact protocol output containing `note_id: felt252`, `token: ContractAddress`, and `amount: u128`; token, amount, output count, liability, and destination/context binding require application validation.
- The intended refund authorization is identity-bound `ComputeAndInvoke`, not a secret-only bearer claim.
- The `ComputeAndInvoke` wallet/client POC demonstrates wallet/application identity binding, destination semantics, one-time replay resistance, calldata ordering, and fail-closed behavior (see §9).

A bearer-secret refund is rejected and must not be silently adopted. The
refund path may proceed with the identity-bound `ComputeAndInvoke` design.

Sources:
- https://strk20-by-example.org/helpers/escrow
- https://github.com/starkware-libs/starknet-privacy/tree/b59d8a141e49a9d940fb14dfe935cbecb8202814
- https://github.com/starkware-libs/starknet-privacy/commit/b59d8a141e49a9d940fb14dfe935cbecb8202814

## 6. Recommended package/tool versions — VERIFIED FOR STARTER SNAPSHOT; PIN BEFORE BUILD

The current starter snapshot reports:

- `starknet`: `10.4.0`
- `@starknet-io/types-js`: `0.10.3`
- Next.js: `^16.0.8`
- React / React DOM: `19.2.1`
- TypeScript: `^5.9.3`
- Node.js: 20+ required by the privacy repository guidance
- Yarn: `1.22.22` in the starter snapshot

The Wallet API documentation independently references `starknet@^10.4.0` and Wallet API `0.10.3`.

The current `starknet-privacy` compatibility table reports SDK/prover/discovery tag `PRIVACY-0.14.3-RC.2`, privacy contracts `PRIVACY-0.14.3-RC.0`, and Pathfinder `v0.22.7`; components in a compatibility row are tested together. Do not mix arbitrary revisions. Scarb, Starknet Foundry, stable Rust, and Node 20+ are required by the repository guidance.

These are source snapshots, not a promise that newer releases are unavailable. Pin the exact versions selected for the build in a lockfile and record the compatibility row.

Sources:
- https://strk20-by-example.org/starknet-wallet-api/private-defi
- https://github.com/Akashneelesh/strk20-starter-kit/blob/main/package.json
- https://github.com/starkware-libs/starknet-privacy/blob/main/README.md

## 7. STRK20 pool/network configuration — UNVERIFIED

Verified:

- The target integration is the live STRK20 pool on Starknet mainnet.
- The hackathon requires qualifying transactions on Starknet mainnet against that pool.
- The starter supports Sepolia or Mainnet as wallet environments.

Not verified by the authoritative sources checked:

- exact current mainnet pool address;
- exact token address and decimals;
- final pool/token compatibility for BackerZero;
- whether the packet's recorded pool address remains current.

The pool address in the build packet and product spec is a planning assumption only. It must not be used for deployment, configuration, or manifest evidence until confirmed through current official registry/read-only chain verification.

Sources:
- https://strk20.starknet.io/build
- https://github.com/starkience/strk20-hackathon/blob/main/README.md
- https://github.com/Akashneelesh/strk20-starter-kit/blob/main/README.md

## 8. BackerZero feasibility — YES WITH CHANGES

The core flow is technically feasible with shipped infrastructure:

1. Public campaign state can be held in a Cairo helper.
2. A backer can read a shielded balance through the Wallet API.
3. The Wallet API can compose a pool-funded helper invocation.
4. The helper can retain funds by returning an empty span.
5. A later funding claim or refund can approve the pool and return exact `OpenNoteDeposit` instructions.

Required design changes before implementation:

- Bind `privacy_invoke` entry to the configured STRK20 pool.
- Bind token, campaign, amount, commitment, deadline, and one-time claim/refund state.
- Specify and fixture-test exact calldata and `OpenNoteDeposit` serialization.
- Resolve refund destination authorization and secret replay/race risk.
- Verify the live pool, token, decimals, network, and Wallet API compatibility.
- Run `strk20PrepareInvoke` simulations before any human-approved broadcast.
- Treat mocked tests as insufficient; obtain at least three real successful mainnet pool-touching hashes for submission and target five internally.

No source reviewed here proves that BackerZero is deployed, has completed a mainnet lifecycle, or has qualifying hashes. Those remain **UNVERIFIED**.

## Build-packet conflicts

- The packet's exact pool address is **UNVERIFIED**, not an established current constant.
- The packet's `strk20.json` example is incomplete as a submission specification unless it matches the repository's documented root fields and verification rules; the current local file is not submission-ready.
- The packet treats the stateful escrow pattern as the core refund mechanism, but the official example's unaudited status means refund authorization requires a design/security decision before implementation.
- The packet's version recommendations are usable as a starter snapshot, but exact versions must be pinned together with a current `starknet-privacy` compatibility row.

## 9. Privacy runtime execution — REAL PROOF GENERATED AND SETTLED ON SEPOLIA

Prompt 4 Part A/B/C/D were executed with the pinned upstream checkout, an
official-compatible prover, and a hosted Sepolia RPC path. Reproduce with
`scripts/run-privacy-real-proof.sh`.

### Compatibility row (independently verified)

| Field | Value |
| --- | --- |
| Image | `ghcr.io/starkware-libs/starknet-privacy/transaction-prover:PRIVACY-0.14.3-RC.2` |
| OCI index digest | `sha256:a2f71d7139069fa566c4f44bdd66b79cac992c0cbc20ddf0af3a3558c6cabd64` |
| linux/amd64 manifest | `sha256:a62e7764e034ea25d84d4a235f1f683f7c5f03f88f6646a744599171bf5ca58c` |
| linux/arm64 manifest | `sha256:9882d27692b420a9edae9b50bf8075103044230de0f83ee6bed3db19cace105f` |
| Image labels | `version=PRIVACY-0.14.3-RC.2`, `revision=e6b6fd2e9932909107833579e5b6efd6c75fa0af` |
| Prover binary version | `0.19.0-rc.2`; `starknet_specVersion` → `0.10.3-rc.2` |
| Source commit | `b59d8a141e49a9d940fb14dfe935cbecb8202814` |
| Prover source commit (binary label) | `e6b6fd2e9932909107833579e5b6efd6c75fa0af` |
| SDK package | `0.14.3-rc.5` (checked in at that commit) |
| Privacy contracts | `PRIVACY-0.14.3-RC.0` |
| Discovery service | `PRIVACY-0.14.3-RC.2` (built from source at the pinned commit) |
| Node dependency | Pathfinder `v0.22.7`; devnet `v0.8.0-rc.3` |

The RC.2 image is authoritative and exists. The `0.14.3-rc.5` SDK package version
is the in-repo package version at the pinned commit, not a separate runtime row;
RC.2 remains the runtime row. Both are recorded rather than merged.

**Execution note:** the official `linux/amd64` image binary contains AMD-only
SSE4a instructions (`EXTRQ`/`INSERTQ`) and exits with SIGILL (code 132) on the
Intel host. For the Sepolia run the same source commit
`e6b6fd2e9932909107833579e5b6efd6c75fa0af` was built natively with
`CARGO_PROFILE_RELEASE_RUSTFLAGS="-C target-cpu=x86-64"`. The resulting binary
produces the same `starknet_specVersion` (`0.10.3-rc.2`) and RPC behavior as the
official image; it is a CPU-compatibility workaround, not a different version.

### Runtime execution status

- Prover starts, initialises its precomputes, and serves JSON-RPC on `:3000`.
- The SDK client reaches the prover and `starknet_proveTransaction` is accepted
  and executed (`Starting transaction proving`).
- A real proof is produced in ~25–30 seconds for a Sepolia deposit.
- The proof is broadcast via `executeFromOutside` and settles on Sepolia.
- The resulting note is discoverable through the supported indexer/discovery path.

### Real-proof lifecycle on hosted Sepolia

`scripts/run-privacy-real-proof.sh` orchestrates:

1. RPC capability proxy on `127.0.0.1:8547`.
   - `starknet_getStorageProof` and storage-proof-compatible reads are routed to
     ZAN Sepolia (retains ~110–120 blocks; rate-limited).
   - All other calls (full v0.10 block headers, transaction broadcast) are
     routed to PublicNode Sepolia (`starknet_specVersion` `0.10.2`, Juno v0.16.3).
2. Local prover binary from the official source commit.
3. Deposit + real proof + `executeFromOutside` settlement on the live Sepolia
   privacy pool.
4. Indexer/discovery note observation.

Latest successful run evidence (`poc/compute-and-invoke/e2e/evidence/sepolia-real-proof.json`):

| Field | Value |
| --- | --- |
| `poolAddress` | `0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce` |
| `approveTx` | `0x119d289a9d654dc3617aed5fbcd8bc0132af4e7e790f47884a88665f4310d71` |
| `provingBlockId` | `13920374` |
| `provingMs` | `26794` |
| `proofFactsLength` | `9` |
| `proofDataLength` | `305732` |
| `callContract` / `callEntrypoint` | `0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce` / `apply_actions` |
| `settlementTx` | `0x57ba2ec108d116ae5f8851d95ae1b840526f85947ec4bb739acbc7c9dfc1098` |
| `discoveredNotes` | `1` |

Sepolia settlement receipt:

- `execution_status`: `SUCCEEDED`
- `finality_status`: `ACCEPTED_ON_L2`
- `block_number`: `13920409`
- `actual_fee`: `0x27e0cc2aed18b170` FRI

The transaction emits the expected pool and token events; the privacy contract's
`apply_actions` accepted the real `proof` and `proofFacts`.

### ComputeAndInvoke conformance (Part D)

`poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts` was run on the upstream
devnet harness using the same SDK `computeAndInvoke` builder. The devnet harness
uses a mock proof provider because `starknet-devnet` does not implement
`starknet_getStorageProof`; the negative tests exercise the pool contract's
binding/nullifier logic, while the real proof soundness is established by the
Sepolia run above.

| Test | Result | Failure mode |
| --- | --- | --- |
| Positive path | Accepted; open note filled with the exact payout | — |
| Replay of the same authorization | Rejected | `NON_ZERO_VALUE` |
| Amount substitution | Rejected | `INVALID_PROOF_MSG` |
| Calldata/action substitution (selector) | Rejected | `INVALID_PROOF_MSG` |
| Destination substitution (open-note id) | Rejected | `INVALID_PROOF_MSG` |
| Wrong context (anonymizer target address) | Rejected | `INVALID_PROOF_MSG` |
| Wrong context (dapp name / compute data) | Not tamperable | Value is absent from public calldata; it is committed in the proof's private inputs, so post-authorization substitution is not expressible through the client API |

Action structure that was exercised (`computeAndInvoke`):

- `contractAddress` — the anonymizer invoked by the pool;
- `computeAdditionalData` — `[dappName, seqNonce]`, fed to
  `privacy_compute(identity_key, dapp_name, nonce)`; the pool prepends the derived
  identity key, so the resulting commitment selects a per-identity shadow account;
- `invokeAdditionalData` — ABI-compiled `privacy_invoke_with_computation` args
  (`Array<Call>`, `Span<OpenNoteCollect>`) with the leading identity commitment
  sliced off because the pool prepends it.

Destination binding is established at the *open-note id* level (substituting it
fails), and identity/context binding is established by construction (the identity
key is derived inside the pool and the dapp/nonce context is committed in-proof,
not in public calldata).

## Prompt 5B Sepolia execution attempt — 2026-08-23

The autonomous Prompt 5B attempt stopped before any declaration, deployment, or lifecycle broadcast. It confirmed the Sepolia chain identity and read-only RPC reachability but did not establish a complete production path.

Evidence: `poc/compute-and-invoke/e2e/evidence/prompt5b-sepolia-lifecycle.json`.

| Check | Result | Detail |
| --- | --- | --- |
| Sepolia chain identity | **PASS** | `SN_SEPOLIA`; read-only block probe returned block `13926977` |
| PublicNode header RPC | **PASS** | `starknet_specVersion` `0.10.2` |
| Cartridge transaction RPC | **PASS** | `starknet_specVersion` `0.9.0` |
| `scarb fmt --check` | **PASS** | Contracts format clean |
| `scarb build` | **PASS** | BackerZero artifacts generated |
| `snforge test` | **BLOCKED** | `universal-sierra-compiler` unavailable |
| TypeScript typecheck/lint | **PASS** | Development dependencies installed explicitly |
| TypeScript tests | **PASS** | 16/16 |
| Universal Sierra Compiler | **BLOCKED** | No executable found in the pinned/tool search paths |
| Pinned privacy checkout | **BLOCKED** | `/tmp/starknet-privacy-b59d8a1` absent |
| Disposable Sepolia accounts | **BLOCKED** | `$HOME/.bz-sepolia/accounts.json` absent |
| Authorized pool/token/decimals | **NOT_ESTABLISHED** | Prior pool address probe alone is insufficient |
| Declaration/deployment/lifecycle | **NOT_REACHED** | No chain broadcast occurred |
| Mainnet involvement | **NONE** | This attempt was Sepolia preflight only |

No faucet attempt was made because no external account address or signer was available. The minimum STRK requirement cannot be responsibly quoted before exact declaration/deployment/lifecycle calldata and fee estimates exist; the minimum token requirement also remains unknown until the authorized Sepolia pool, token, and decimals are verified.

The prior Prompt 4 real-proof records in this document remain historical evidence. They do not establish that this Prompt 5B attempt completed, and no Prompt 5B transaction hash or deployment address is claimed here.

## 10. Conclusion for Prompt 4

- **Generic real-proof E2E:** PASS — real STARK proof generated and settled on
  Starknet Sepolia; resulting note discovered through the supported client path.
- **Settlement:** PASS — Sepolia transaction
  `0x57ba2ec108d116ae5f8851d95ae1b840526f85947ec4bb739acbc7c9dfc1098` is
  `ACCEPTED_ON_L2` and `SUCCEEDED`.
- **ComputeAndInvoke:** PASS — the SDK builder exposes an identity-bound,
  destination-bound, one-time authorization primitive; all expressible tamper and
  replay attempts fail closed.
- **Refund authorization:** APPROVED_FOR_BUILD — use identity-bound
  `ComputeAndInvoke` for `Claim Refund`; bearer-secret refund remains rejected.
- **Prompt 5:** CLEARED_FULL — implementation of Create Campaign → Back Privately
  → Claim Funding → Claim Refund may proceed.

