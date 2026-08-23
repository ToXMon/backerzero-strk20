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

## 5. OpenNoteDeposit/refund authorization — PROTOCOL_SUPPORTED_BUT_CLIENT_UNVERIFIED

The protocol shape needed by BackerZero is documented, but exact wallet/client conformance is not verified:

- A stateful helper can receive a pool-funded private invocation, record state, retain funds by returning an empty span, and later approve the privacy contract and return an `OpenNoteDeposit` for a claim/refund.
- `OpenNoteDeposit` must be handled as the exact protocol output containing `note_id: felt252`, `token: ContractAddress`, and `amount: u128`; token, amount, output count, liability, and destination/context binding require application validation.
- The intended refund authorization is identity-bound `ComputeAndInvoke`, not a secret-only bearer claim.
- The exact-wallet conformance POC must prove wallet/application identity binding, destination semantics, one-time replay resistance, calldata ordering, and fail-closed behavior.

A bearer-secret refund is rejected and must not be silently adopted. If the POC fails, the explicit options are defer/fail closed or a tightly bound capability fallback with documented theft, replay, front-running, destination, and privacy limitations. No anonymous or replay-safe claim is permitted without evidence.

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

## 9. Privacy runtime execution — EXECUTED, REAL PROOF BLOCKED ON RPC CAPABILITY (2026-08-23)

Prompt 4 Part A/B/C/D were executed with Docker, GHCR, and the pinned upstream
checkout. Reproduce with `scripts/run-privacy-real-proof.sh`.

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
| SDK package | `0.14.3-rc.5` (checked in at that commit) |
| Privacy contracts | `PRIVACY-0.14.3-RC.0` |
| Discovery service | `PRIVACY-0.14.3-RC.2` (built from source at the pinned commit) |
| Node dependency | Pathfinder `v0.22.7`; devnet `v0.8.0-rc.3` |

The RC.2 image is authoritative and exists: it was pulled by immutable digest and
its labels point at the same release train as the README row. The `0.14.3-rc.5`
SDK package version is the in-repo package version at the pinned commit, not a
separate runtime row; RC.2 remains the runtime row to use. Both are recorded
rather than merged.

### Runtime execution status

- Prover starts, initialises its precomputes, and serves JSON-RPC on `:3000`.
- The SDK client reaches the prover and `starknet_proveTransaction` is accepted
  and executed (`Starting transaction proving`).
- ISA constraint: the linux/amd64 binary contains 11 AMD-only SSE4a
  instructions (`EXTRQ`/`INSERTQ`) and aborts with SIGILL (exit 132) on Intel
  hosts. Evidence: `.github/workflows/privacy-prover-cpu-isa-probe.yml`.
  The linux/arm64 manifest under `qemu-user` emulation runs the proving path.

### Real-proof blocker (root cause)

`starknet_proveTransaction` requires `starknet_getStorageProof` from its RPC node.
`starknet-devnet` does not implement it:

```console
$ curl -s -X POST http://127.0.0.1:5050 -H 'content-type: application/json' \
    -d '{"jsonrpc":"2.0","id":1,"method":"starknet_getStorageProof","params":{"block_id":"latest","class_hashes":[],"contract_addresses":[],"contracts_storage_keys":[]}}'
{"jsonrpc":"2.0","id":1,"error":{"code":42,"message":"Devnet doesn't support storage proofs"}}
```

The prover surfaces exactly this upstream error, and the SDK propagates it:

```text
prove_transaction failed: RunnerError(ProofProvider(UpstreamRpcError { code: 42,
  message: "Devnet doesn't support storage proofs", data: None }))
ProvingServiceError: Devnet doesn't support storage proofs
```

This is consistent with the upstream design: the compatibility row pairs the
prover with Pathfinder, upstream's own devnet tests use
`ScreeningCallMockProofProvider`, and upstream's real-proof tests live in
`e2e/tests/integration/` against a live (integration Sepolia) deployment
requiring `VITE_RPC_URL`, `VITE_PROVING_SERVICE_URL`, and funded accounts.

**Conclusion:** a real-proof privacy lifecycle is not obtainable on a local
devnet with this runtime row. It requires a storage-proof-capable node
(Pathfinder) plus a live-testnet privacy pool deployment and funded disposable
accounts. Evidence: `poc/compute-and-invoke/e2e/evidence/`.

### ComputeAndInvoke conformance (Part D)

`poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts`, derived from upstream
`shadow-account-compute-invoke.test.ts`, run on the devnet harness (mock proof
provider, since a real proof is unobtainable there — the negative tests exercise
the pool contract's binding/nullifier logic, not proof soundness):

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

Destination binding is therefore established at the *open-note id* level
(substituting it fails), and identity/context binding is established by
construction (the identity key is derived inside the pool and the dapp/nonce
context is committed in-proof, not in public calldata).

## 10. Hosted Sepolia real-proof attempt — EXECUTED, BLOCKED ON PROVER EXECUTION TIME vs. STORAGE-PROOF RETENTION (2026-08-23)

The local devnet blocker was removed by moving to a storage-proof-capable hosted
Starknet Sepolia endpoint and a live privacy-pool deployment.

### Storage-proof-capable RPC probe

`scripts/probe-storage-proof-rpc.sh` was run against PublicNode, Cartridge,
ZAN, dRPC, and several other public Sepolia endpoints.

| Provider | Network | `starknet_specVersion` | `starknet_getStorageProof` | Notes |
| --- | --- | --- | --- | --- |
| PublicNode Sepolia | `SN_SEPOLIA` | `0.10.2` (Juno v0.16.3) | Works for `latest`/`pending` only | Full v0.10 block headers (`state_diff_commitment`, `transaction_commitment`, `receipt_commitment`) |
| Cartridge Sepolia | `SN_SEPOLIA` | `0.9.0` | Works for ~`latest - 16` to `latest` | Block headers lack v0.10 commitment fields |
| Alchemy Sepolia | `SN_SEPOLIA` | `0.9.0` | Works for ~`latest - 16` | Same commitment/header limitation as Cartridge |
| ZAN Sepolia | `SN_SEPOLIA` | `0.9.0` | Works but rate-limited | Rate/compute-limit errors on heavy use |
| dRPC Sepolia | `SN_SEPOLIA` | `0.9.0` | `Method not found` | — |
| Blast/Lava/Nethermind/BlockPI/OMNIA/1RPC | `SN_SEPOLIA` | — | unreachable/down | — |

No single public endpoint satisfies *both* prover requirements (full v0.10 block
headers plus archive-ish storage proofs), so `scripts/rpc-capability-proxy.py`
routes:

- `starknet_getStorageProof` and storage-proof-compatible reads → Cartridge/Alchemy/ZAN
- all other RPC calls (full block headers, transaction broadcasts) → PublicNode

The proxy runs on `127.0.0.1:8547` and is what the prover uses as `RPC_URL`.

### Testnet account and pool deployment

Two disposable Sepolia accounts were generated locally (`bzsepolia` and
`bzalice`), funded via the official Starknet Sepolia faucet, and deployed.
Public addresses (only):

- `bzsepolia`: `0x017c9e75c61e8b107cbed671b148af8c2d977fb0d6cefa9cb71f324024008db7`
- `bzalice`: `0x0095dca79915061d76e86e7428657e3a2498a188b3d0f6317f3244b3148c0aa5`

The privacy-pool class for `PRIVACY-0.14.3-RC.0` was already declared on
Sepolia at `0x52107fadffab71bdcbb6b2ccb68ba3e1b5558d94036538053e159d3076ad633`.
A fresh pool instance was deployed at
`0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce`
(tx `0x04635f2c6dd6de27aadd61426bce328dcabff27751f53cdedd5de0e246f72d96`).

### Prover execution against hosted Sepolia

- The prover started against the capability proxy and reached the
  `starknet_proveTransaction` stage.
- `linux/amd64` image: SIGILL (exit 132) on the Intel VM because the binary
  contains AMD-only SSE4a instructions (`EXTRQ`/`INSERTQ`). The same failure
  occurs with `QEMU_CPU=Opteron_G5,vendor=AuthenticAMD`.
- `linux/arm64` image: starts under `qemu-user` emulation and runs the proving
  path. A reproduction run reached `Starting transaction proving` for Sepolia
  block `13902905` and transaction
  `0x6415f2ca0f42e8d33bae1bbbfea3b01918cd4bca3d17aa470415e910584ed80`, but the
  proof did not return. After approximately **4 minutes 35 seconds** the prover
  failed with:
  ```text
  prove_transaction failed: RunnerError(ProofProvider(UpstreamRpcError {
    code: 42,
    message: "The node doesn't support storage proofs for blocks that are too far in the past"
  }))
  ```
  surfaced as `ProvingServiceError: The node doesn't support storage proofs for blocks that are too far in the past`.
- The longest-retention public storage-proof window found is approximately
  **16 blocks** (Cartridge/Alchemy). Because the ARM64 emulated prover cannot
  finish within that window, `starknet_getStorageProof` for the proving block
  ages out before the proof completes.

This is an execution-environment mismatch, not a protocol incompatibility: a
native ARM64 or x86-64 prover, or a hosted proving service / node with longer
storage-proof retention, would close the gap.

### Discovery-service TLS patch

The upstream discovery service panicked on startup with
`Could not automatically determine the process-level CryptoProvider` when
multiple `rustls` crypto providers were present. It was patched to install the
ring provider explicitly:

```rust
let _ = rustls::crypto::ring::default_provider().install_default();
```

Patch file is saved at `scripts/discovery-service-rustls.patch`.

### Conclusion for Prompt 4 Part C

A real STARK privacy proof for the pool deposit action was **not generated and
settled** in this environment. The blocker is reproducible and external to the
BackerZero application:

1. No public Sepolia proving service endpoint is documented.
2. Self-hosted `linux/amd64` prover cannot run on the Intel VM (SSE4a).
3. Self-hosted `linux/arm64` prover is too slow for the storage-proof retention
   of every reachable hosted RPC.

Therefore **Prompt 4 generic real-proof E2E remains FAIL / BLOCKED**.
