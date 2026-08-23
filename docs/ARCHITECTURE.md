# BackerZero Architecture

## Scope and status boundary

BackerZero is a narrow Starknet mainnet MVP: **Create Campaign → Back Privately → Claim Funding → Claim Refund**. The architecture uses one stateful Cairo helper, one configured STRK20 pool, and one fixed ERC-20 token. It does not include a backend, database, indexing service, custom privacy service, cross-chain support, multi-token campaigns, or anonymous campaign creation.

The following status is authoritative for this document:

- **IMPLEMENTED:** The `BackerZero` Cairo helper contract, test suite, shared Poseidon fixtures, and `strk20-actions` TypeScript package are implemented and unit-tested.
- **PROTOCOL-SUPPORTED BUT CLIENT-UNVERIFIED:** The documented Wallet API/private invocation/OpenNoteDeposit mechanics provide the protocol shape for private balance reads, `strk20PrepareInvoke(actions, true)`, pool-funded helper invocation, `privacy_invoke`, empty `Span<OpenNoteDeposit>` retention, and exact release instructions. Exact-wallet identity-bound `ComputeAndInvoke` conformance is verified by the Prompt 4 POC, but no live-wallet Prompt 5B lifecycle run has been completed yet.
- **UNVERIFIED:** Current mainnet pool address, token address and decimals, final pool/token compatibility, exact final helper compatibility, deployment, and any transaction evidence.
- **REJECTED DESIGN:** Bearer-secret refund authorization must not be silently adopted. A receipt preimage alone does not establish recipient authorization, replay resistance, or safe open-note destination binding.
- **BLOCKER (now Prompt 5B):** A live Sepolia lifecycle run (Create Campaign → Back Privately → Claim Funding → Claim Refund) must pass before mainnet readiness/privacy claims.

No address, token, ABI, deployment, or transaction hash in this architecture is release evidence until verified by current official documentation and read-only chain checks.

## System boundaries and data flow

```text
Browser UI
  ├─ public campaign reads ───────────────► Starknet helper storage/events
  ├─ shielded balance/action requests ────► STRK20 Wallet API
  ├─ private action preparation ──────────► Wallet proof/prover/simulation
  └─ signed submission ───────────────────► Wallet/relayer ─► Starknet

STRK20 pool ── privacy_invoke ──► BackerZero Cairo helper
                                      ├─ public campaign/accounting state
                                      ├─ private contribution liability
                                      └─ OpenNoteDeposit output on release
```

The browser is the only application layer. Financial correctness is owned by the helper contract and the STRK20 pool; the browser must not be trusted to maintain raised totals, claim state, refund state, or liabilities. A backend is intentionally excluded from the MVP so receipt secrets and viewing keys never need to be uploaded.

## Frontend

The frontend provides:

- Explore and campaign-detail views for public metadata, creator, goal, deadline, raised total, derived status, and the narrow privacy disclosure.
- Campaign creation form for metadata, goal, deadline, and configured token.
- Backing flow that generates a cryptographically random receipt secret locally, derives a domain-separated commitment, reads a shielded balance, prepares the private withdrawal followed by helper invocation, and shows explicit progress states.
- Claim/refund flows that use identity-bound `ComputeAndInvoke` authorization without sending secrets to BackerZero servers. A tightly bound capability fallback may be considered only after the exact-wallet POC fails and the limitations are explicitly documented; a bearer-secret refund is not an implicit fallback.
- Local receipt export/import with a prominent loss warning; receipt material must never enter analytics, logs, screenshots, or fixtures.
- Evidence and failure UI that distinguishes mocked browser tests from real wallet/mainnet evidence.

The UI may display public chain data, but it must not infer privacy beyond the approved wording: “BackerZero hides the public link between the backer's wallet and the contribution when funding from an already-shielded STRK20 balance. Campaign activity and amounts remain public.” It must disclose that timing, amounts, shielding deposits, helper actions, open-note amounts, and correlation signals may remain visible.

## Wallet and STRK20 interaction

### Verified interaction mechanics

The intended private path uses the STRK20 Wallet API:

1. Read shielded balances with `strk20Balances`.
2. Build a private `withdraw`/transfer action from the selected token to the helper, using the literal `OPEN` amount where required.
3. Append an `invoke` action for the helper's `Back` entry point.
4. Call `strk20PrepareInvoke(actions, true)` to build, prove, and simulate without submission.
5. Preserve literal `OPEN` and wallet-resolved open-note identifiers exactly; they are not ordinary numeric calldata.
6. Ask the user to confirm in the wallet, then submit through the supported wallet/relayer path.

For funding claims and refunds, the helper returns an exact `OpenNoteDeposit` describing `note_id`, `token`, and `amount`. The wallet action must use wallet-resolved open-note destination semantics and identity-bound `ComputeAndInvoke` context. The protocol shape is supported by the pinned source revision, but exact-wallet conformance and intended-recipient binding remain unverified and block implementation.

### Mainnet boundary

The application must stop before deployment, broadcast, or monetary operation until a human approves the specific operation. Before any live action, verify chain ID, current pool address, token and decimals, helper ABI, wallet/API versions, account behavior, and pool/token compatibility through official sources and read-only checks. Simulations are required before every approved broadcast. Tiny-value rehearsal is required for both successful funding and failed-campaign refund paths. No mainnet evidence exists currently.

## Exactly one Cairo helper

BackerZero has one stateful Cairo helper contract (`contracts/src/backerzero.cairo`) and no second application contract. The helper:

- Is configured for exactly one verified STRK20 pool and one verified token.
- Accepts `privacy_invoke` only from that configured pool.
- Stores public campaign parameters and derived campaign status.
- Stores commitments and contribution liabilities without accepting, storing, or emitting a backer wallet address.
- Tracks explicit `total_escrow`/outstanding liabilities separately from raw token balance; direct donations are not application accounting.
- Uses checked arithmetic and validates positive values, campaign state, deadlines, token, amount, campaign, commitment uniqueness, and solvency.
- Returns an empty `Span<OpenNoteDeposit>` when a private contribution is retained in escrow.
- Changes state before external approval/output interaction for creator claims and refunds, then returns one exact `OpenNoteDeposit` for the release amount.
- Computes a deterministic campaign ID from `chain_id`, helper, creator, goal, and deadline (low 64 bits of a domain-separated Poseidon hash).

The Cairo interface, calldata ordering, and serialization are implemented and unit-tested; compatibility with the live STRK20 pool and exact wallet `ComputeAndInvoke` flows remains unverified until a Prompt 5B live run.

## Campaign state machine

Campaign status is derived without an explicit `finalize()` transaction:

```text
now < deadline                              Active
now >= deadline and raised >= goal and !claimed  Successful
now >= deadline and raised >= goal and claimed   Claimed
now >= deadline and raised < goal             Failed
```

Transitions and guards:

- `Create Campaign → Active`: public creator transaction; stores deterministic campaign ID, metadata/URI, goal, deadline, token, creator, and creator capability commitment.
- `Active → Active`: valid private back; only before the deadline, with a positive amount and sufficient helper balance coverage.
- `Active → Successful`: derived at or after deadline when `raised >= goal`; no separate finalization call.
- `Successful → Claimed`: one valid creator capability after the deadline; full raised amount is released once.
- `Active → Failed`: derived at or after deadline when `raised < goal`; no separate finalization call.
- `Failed → Failed`: one valid refund per contribution commitment after the deadline; each matching liability is released once.

No refund is valid before the deadline. No creator claim is valid before the deadline, even if the goal was already reached. A successful campaign cannot be refunded; a failed campaign cannot be creator-claimed.

## Contribution and refund commitments

### Contribution

The browser generates a random receipt secret locally and computes a domain-separated Poseidon commitment containing, at minimum, version/domain, chain ID, helper address, campaign ID, and secret. The exact field order and encoding are captured in shared Cairo/TypeScript fixtures (`contracts/tests/fixtures.cairo` and `packages/strk20-actions/src/fixtures.ts`). The private pool withdrawal funds the helper atomically with `Back`. The helper verifies pool caller, campaign, token, amount, deadline, unused commitment, and solvency, then increments `raised`, outstanding liabilities, and the contribution record without a backer address.

### Creator capability

Campaign creation stores only a creator claim capability commitment. The creator later presents the capability after a successful deadline. Whether a creator secret alone is sufficient or must be combined with creator-wallet authorization remains an open design question; the implementation must not silently assume recovery or anonymity semantics.

### Refund

After a failed deadline, the browser prepares an identity-bound `ComputeAndInvoke` refund authorization. The helper validates the wallet/application context, campaign and contribution binding, token, exact amount, one-time state, solvency, and the exact `OpenNoteDeposit` shape; it then marks the contribution spent before approval/output interaction and returns one validated deposit. Wrong context, wrong bindings, duplicate use, early refund, successful-campaign refund, and insufficient/invalid release data must fail.

A bearer-secret refund is rejected and must not be silently adopted. If the exact-wallet conformance POC fails, the product must defer/fail closed or use only a tightly bound capability fallback with explicit theft, replay, destination, and privacy limitations. No anonymous or replay-safe claims are permitted without evidence.

## Public/private information matrix

| Information | Expected visibility | Boundary |
| --- | --- | --- |
| Campaign metadata, creator, goal, deadline, status | Public | Campaign accountability is intentional. |
| Raised total and aggregate contribution accounting | Public | Amounts are not hidden by this application layer. |
| Backer wallet address in helper accounting | Not accepted/stored/emitted | STRK20 shields the direct wallet-to-contribution link when funding from an already-shielded balance. |
| Contribution amount and timing | Potentially public/correlatable | Helper actions, deposits, notes, and timing can be observed. |
| Shielding deposit and open-note payout amount | Potentially public | Distinctive timing/amount patterns can weaken privacy. |
| Receipt secret and creator capability preimage | Client-local secret | Never upload, log, emit, screenshot, or place in fixtures. |
| Viewing keys | Wallet-controlled | BackerZero does not handle or implement note discovery. |

The product must never claim anonymous transactions, hidden amounts, total untraceability, total secrecy, or that nobody can discover a contributor.

## Error and failure behavior

The helper rejects, at minimum: unauthorized pool entry; wrong token; zero or overflowing amount; unknown campaign; malformed commitment; duplicate commitment; backing after deadline; insufficient liability coverage; early refund; successful-campaign refund; wrong receipt secret; duplicate refund; early creator claim; below-goal claim; wrong creator capability; duplicate claim; invalid release token/amount/note data; and cross-campaign liability use.

The frontend must map failures to actionable states without exposing secrets: preparation failure, proof failure, simulation failure, wallet rejection, relayer/submission failure, reverted transaction, timeout/unknown confirmation, missing receipt, wrong receipt, already spent capability, and unsupported/unverified network configuration. It must not report a transaction as confirmed without wallet/chain evidence.

## Testing and verification

Before implementation, define fixtures for exact Poseidon parity, campaign-state boundaries, helper calldata, `OpenNoteDeposit` serialization, literal `OPEN`, wallet-resolved note IDs, pool-only authorization, and token/amount/recipient binding. Required test layers are:

- Cairo unit tests for arithmetic, guards, state transitions, liabilities, one-time claims/refunds, and external-call ordering.
- Stateful, fuzz, and invariant tests proving no double release, no cross-campaign spending, and `total_escrow` never exceeds the helper's supported balance coverage.
- TypeScript unit/parity tests for commitment derivation and action construction, with no real secrets in fixtures.
- Wallet/API integration tests using official-compatible mocks and explicit distinction from live evidence.
- Playwright tests for the four flows, receipt loss/wrong-secret paths, progress states, disclosures, and responsive/error UI.
- Manual read-only checks and human-approved tiny-value mainnet rehearsals only after code review; each successful pool-touching hash must be independently verified before evidence use.
- Independent security review focused on refund authorization, destination binding, pool authorization, accounting, and malicious-token behavior. No audit has occurred.

## Summary

- One browser application is the only off-chain application component.
- One stateful Cairo helper owns campaign state and liabilities.
- One configured STRK20 pool and one fixed ERC-20 are MVP constraints.
- Wallet API/private invocation/OpenNoteDeposit mechanics are verified by the Prompt 4 POC.
- Current pool, token, decimals, final compatibility, deployment, and transactions are unverified.
- `privacy_invoke` must accept calls only from the configured pool.
- Raw token balance is not application accounting; explicit liabilities are required.
- Commitments bind domain, chain, helper, campaign, and secret with shared Poseidon fixtures.
- Campaign outcome is derived from deadline, goal, raised total, and claim state.
- Refund and creator claim state must change before release interactions.
- Identity-bound `ComputeAndInvoke` is the intended refund architecture, classified `PROTOCOL_SUPPORTED` by the Prompt 4 POC; the Prompt 5B live-wallet lifecycle remains the next gate.
- Bearer-secret refund authorization is rejected and cannot be silently adopted.
- Mainnet deployment, broadcasts, and monetary operations require human approval.

## Required contracts

Exactly one Cairo helper contract, configured only after the live STRK20 pool, token, decimals, ABI, and compatibility are verified. The contract implementation lives in `contracts/src/backerzero.cairo` and `contracts/src/hashing.cairo`; no live deployment is currently present.

## Required frontend components

Explore/campaign detail, create campaign, private backing, claim funding, claim refund, wallet/API progress, local receipt import/export, public/private disclosure, evidence links, and actionable error states.

## Biggest risk

Exact-wallet conformance for identity-bound `ComputeAndInvoke` may fail to establish authorization and open-note destination binding; this POC blocker prevents refund implementation and production-ready privacy/refund claims. A bearer-secret path is rejected, not an automatic fallback.
