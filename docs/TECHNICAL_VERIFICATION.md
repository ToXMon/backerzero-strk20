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
