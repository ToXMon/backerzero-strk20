# BackerZero Product Specification

## Product mission

BackerZero is a Starknet all-or-nothing crowdfunding application with public campaign accountability, private backers, and trustless refunds.

**Positioning:** Public campaigns. Private backers. Trustless refunds.

The privacy promise is deliberately narrow: when a user funds from an already-shielded STRK20 balance, BackerZero aims to hide the direct public link between that backer's wallet and the campaign contribution. Campaign state, aggregate totals, contribution amounts at the application/helper layer, timing, deposits, helper actions, and open-note payout amounts may remain visible and can be correlated.

## Hackathon objective

Maximize the STRK20 Private Sprint score through a small, technically deep mainnet product rather than feature breadth.

- Use a stateful STRK20 `privacy_invoke` anonymizer helper.
- Demonstrate the complete four-flow lifecycle on Starknet mainnet.
- Record at least five verified STRK20-pool transaction hashes internally; the formal requirement is at least three.
- Ship a public repository, open-source license, live demo, three-minute video, reproducible build, tests, architecture/privacy/security documentation, and verified `strk20.json` evidence.
- Make the product and its privacy boundary understandable to a judge in seconds.

## P0 MVP

### Scope

- One stateful Cairo helper contract.
- One verified STRK20 pool.
- One fixed ERC-20 token.
- Public campaign metadata/parameters, creator, goal, deadline, raised total, and derived status.
- All-or-nothing outcome determined when the deadline is reached.
- Overfunding allowed: if the goal is met, the creator may claim the full amount raised.
- No explicit `finalize()` transaction; status is derived from time, goal, raised amount, and claim state.
- No public backer address stored or emitted by BackerZero accounting.

### Four required user flows

1. **Create Campaign**
   - Creator supplies campaign metadata, goal, deadline, and configured token.
   - The browser generates a creator claim secret and stores only its commitment on-chain.
   - A normal public Starknet transaction creates a deterministic campaign ID.
   - Campaign creation is public; creator anonymity is not an MVP promise.

2. **Back Privately**
   - Backer reads their shielded balance through the STRK20 Wallet API.
   - Browser generates a cryptographically random receipt secret locally and derives a domain-separated commitment.
   - Wallet API prepares a private `withdraw` to the helper followed by `invoke(Back)`.
   - The helper verifies the configured pool, active campaign, positive amount, unused commitment, and solvency; it records the liability and returns an empty `Span<OpenNoteDeposit>` so funds remain in escrow.
   - No backer address is accepted, stored, or emitted.

3. **Claim Funding**
   - Available only at or after the deadline when `raised >= goal`.
   - Creator presents the valid creator capability.
   - Contract changes state before external interaction, reduces outstanding liabilities, approves the pool, and returns one exact `OpenNoteDeposit` for the full raised amount.
   - Claim is one-time and status becomes `Claimed`.

4. **Claim Refund**
   - Available only at or after the deadline when `raised < goal`.
   - Backer imports or uses the locally-held receipt secret.
   - Contract recomputes the commitment, verifies the contribution, marks it refunded before external interaction, reduces liabilities, approves the pool, and returns one exact `OpenNoteDeposit`.
   - Wrong secrets and duplicate refunds fail.

### State rules

```text
now < deadline                              Active
now >= deadline and raised >= goal and !claimed  Successful
now >= deadline and raised >= goal and claimed   Claimed
now >= deadline and raised < goal             Failed
```

No refund is allowed before the deadline. No creator claim is allowed before the deadline, even if the goal is already reached.

### P0 acceptance criteria

- Campaign creation works on the intended mainnet deployment and exposes deterministic ID, public goal/deadline/creator, and Active status.
- A private back increases `raised` and outstanding liabilities exactly by the requested amount.
- Contribution crediting is rejected unless the helper's token balance covers existing liabilities plus the new amount.
- Funding claim releases exactly the raised amount once to a shielded creator destination.
- Refund releases exactly the matching contribution once to a shielded backer destination.
- Unauthorized pool entry, invalid campaign/state, duplicate capability, wrong secret, and repeated claim/refund attempts fail.
- A tiny-value success lifecycle and failed-campaign refund lifecycle both work against the live STRK20 pool.
- At least five successful, independently verified pool-interaction hashes are recorded before release.

## P1 features

Only after the P0 lifecycle is green on mainnet:

- Receipt export/download/import UX with prominent loss warning.
- Cairo/TypeScript Poseidon parity fixtures and cross-language test vectors.
- In-product public/private disclosure, evidence drawer, explorer links, contract/pool addresses, and verified transaction evidence.
- Fuzzing, randomized stateful accounting tests, and independent adversarial review.
- Investigation or implementation of stronger refund authorization, especially destination binding or one-time Stark-key/signature approaches compatible with Wallet API open notes.
- Accessible/mobile UI polish, robust failure states, clean-browser rehearsal, and proof-progress UX.
- Optional reusable `@backerzero/strk20-actions` package if it does not delay the MVP.

Milestone mode is a stretch feature and may be considered only after all P0 release gates are green. If implemented, describe it as anonymous-backer milestone approval unless the approval choice itself is cryptographically hidden.

## Explicit non-goals

Before five verified mainnet STRK20-pool hashes, BackerZero will not build or depend on:

- Milestone mode, private governance, or secret voting claims.
- Cross-chain support.
- Multi-token campaigns.
- AI campaign creation or recommendations.
- A database, authentication system, custom privacy backend, GraphQL/indexing service, or Postgres unless later proven essential.
- Private wallet subaccounts.
- A second product or broad crowdfunding feature set.
- Hidden contribution amounts, hidden timing, anonymous campaign creation, total untraceability, or unsupported privacy claims.
- Automated mainnet deployment, transaction broadcasting, or autonomous spending.
- Production-grade security claims for an unaudited bearer-secret refund design.

## Core user flows and UX requirements

### Explore and campaign detail

The landing/explore surface should explain the positioning and feature one strong demo campaign. Campaign detail should make raised/goal, deadline, status, shielded balance, primary CTA, and privacy disclosure immediately visible. Show that campaign and aggregate funding are public while the backer-wallet link is hidden by STRK20.

### Private transaction progress

Use explicit stages rather than a generic spinner:

```text
Preparing private transaction
↓ Generating privacy proof
↓ Simulating execution
↓ Confirm in wallet/Ready
↓ Submitted by privacy relayer
↓ Confirmed on Starknet
```

Use `strk20PrepareInvoke(actions, true)` before asking the user to sign. Preserve literal Wallet API placeholders such as `OPEN` and wallet-resolved open-note IDs exactly; they are not ordinary numeric calldata.

### Receipt handling

The receipt is a bearer capability in the initial design. It should be downloadable/importable locally, never uploaded to BackerZero servers, never included in analytics/logs, and clearly described as unrecoverable if lost. Demo funds should remain deliberately small while bearer-secret authorization is unresolved.

## Key privacy requirements

- Use the STRK20 Wallet API for private balances and actions; BackerZero must not handle viewing keys or implement note discovery.
- Store only receipt and creator capability commitments on-chain; keep secrets client-side.
- Never upload, log, analyze, screenshot, or include receipt secrets in test fixtures.
- Never accept, store, or emit a backer wallet address in campaign accounting.
- Include a public/private disclosure matrix in the product and README.
- Approved wording: “BackerZero hides the public link between the backer's wallet and the contribution when funding from an already-shielded STRK20 balance. Campaign activity and amounts remain public.”
- Explicitly disclose that campaign creation, contribution amounts, timing, shielding deposits, helper actions, open-note amounts, and correlation signals may be public.
- Warn users that shielding immediately before a distinctive contribution can weaken privacy through timing/amount correlation.
- Never claim anonymous transactions, hidden amounts, untraceability, total secrecy, or that nobody can discover the contributor.

## Key security requirements

- Bind the helper to one configured pool and one configured token for the MVP.
- `privacy_invoke` must reject every caller except the configured STRK20 pool.
- Track explicit `total_escrow` liabilities; raw token balance includes arbitrary direct donations and is not application accounting.
- Require balance coverage before increasing liabilities.
- Use checked arithmetic for goals, raised amounts, refunds, and escrow.
- Reject zero values, unknown campaigns, late backs, duplicate commitments, wrong secrets, early refunds, successful-campaign refunds, early claims, below-goal claims, and duplicate claims.
- Mark refunds/claims spent and update all state before external token approvals/interactions.
- Ensure one campaign cannot spend another campaign's liabilities.
- Use domain-separated Poseidon commitments including version/domain, chain ID, helper address, campaign ID, and secret.
- Test exact token, amount, note ID, and recipient data in every returned `OpenNoteDeposit`.
- Treat preimage replay/theft during refund as a material unresolved risk; do not call the design production-ready until the risk is addressed or explicitly accepted as experimental.
- Run Cairo unit, fuzz, stateful, and invariant tests; TypeScript parity/unit tests; Playwright tests; and independent security review.
- Never commit private keys, viewing keys, receipt secrets, RPC/API credentials, `.env` files, or signer material.
- Require human approval for mainnet deployment, broadcasts, and monetary operations.

## Known technical assumptions

These are working assumptions from the packet and must be verified before implementation:

- Target chain is Starknet mainnet (`SN_MAIN`).
- Packet-reported STRK20 pool: `0x040337b1af3c663e86e333bab5a4b28da8d4652a15a69beee2b677776ffe812a`.
- STRK20 Wallet API is the private-flow integration route; the packet references `starknet.js ^10.4.0` and Wallet API 0.10.3.
- The official starter patterns support withdraw → helper invoke for Back and `OPEN` → helper invoke for claims/refunds.
- The helper may return an empty `Span<OpenNoteDeposit>` when retaining funds and exact `OpenNoteDeposit` output when releasing funds.
- One fixed ERC-20 is sufficient; USDC is preferred semantically, but STRK is an acceptable fallback if wallet/proving reliability is better.
- Metadata can be compactly stored on-chain or represented by a content URI; no backend is required for financial correctness.
- Short demo deadlines of roughly 90–180 seconds are acceptable.
- Cairo and TypeScript can implement identical domain-separated Poseidon hashing.
- Actual fees, proof latency, relayer behavior, open-note semantics, and transaction shapes must be measured rather than guessed.

## Mainnet requirements

- Verify chain ID, pool address, token address/decimals, Wallet API version, account behavior, and action ABI with official documentation and read-only checks.
- Compile, test, and review the helper before declaration/deployment.
- Obtain explicit human approval before each mainnet deployment, broadcast, or monetary operation.
- Deploy one helper bound to the verified pool/token and record class hash, contract address, and constructor values.
- Execute tiny-value success and failure/refund lifecycles against the live pool.
- Verify at least five successful pool-interaction hashes internally; verify receipt success and actual pool involvement before adding hashes to `strk20.json`.
- Maintain mainnet evidence, runbook, contract addresses, transaction records, actual fees, and reproducible commands.
- Keep a conservative STRK reserve after observing real private-action fees.
- Provide a public repository, open-source license, live demo URL, three-minute video, final manifest, and clean-browser rehearsal.
- Distinguish mocked browser tests from manual real-wallet/mainnet evidence.
- Freeze MVP scope once the core gates pass and preserve a submission buffer.

## Definition of done

1. Repository builds reproducibly and contains no secrets.
2. Cairo helper compiles and passes money-safety, state-machine, fuzz, and invariant tests.
3. Web typecheck, lint, unit tests, build, and relevant Playwright tests pass.
4. Cairo/TypeScript commitment parity and exact Wallet API action fixtures pass.
5. All four P0 flows work through the intended Wallet API integration.
6. Tiny-value success and failed-campaign/refund lifecycles work on the intended Starknet mainnet deployment and live STRK20 pool.
7. Invalid transitions, unauthorized callers, duplicate spends, undercollateralized liabilities, and wrong capabilities are rejected.
8. At least five successful mainnet pool-interaction hashes are verified and documented; no hash is fabricated or unverified.
9. Privacy boundaries, threat model, bearer-secret limitations, and receipt loss/theft risks are explicit.
10. README, architecture, privacy, threat model, evidence, runbook, tests, reproducible build instructions, license, demo, video, and `strk20.json` are complete.
11. A clean-browser rehearsal succeeds without developer intervention.
12. A human release owner approves the final submission package.
