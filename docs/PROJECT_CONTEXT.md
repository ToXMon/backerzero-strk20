# BackerZero — Canonical Devin Project Context

> This is the canonical takeover handoff. Read this file before working on BackerZero. `docs/DEVIN_HANDOFF.md` is a concise pointer and guardrail; it must not contradict this document. Evidence is labeled explicitly. Unverified items are not working features, proofs, deployments, audits, or compatibility claims.

## Mission and judging objective

BackerZero is a narrow Starknet crowdfunding MVP with the promise **“Public campaigns. Private backers. Trustless refunds.”** Its purpose is to keep campaign accountability public while avoiding a direct public wallet-to-campaign link when a backer contributes from an already-shielded STRK20 balance.

The objective is to maximize the official **STRK20 Privacy Sprint 2026** judging score with a working, open-source, well-documented Starknet product. The documented weighting is **30% STRK20 integration depth, 30% working mainnet product, 25% innovation, and 15% documentation/open-source quality**. The documented deadline is **2026-08-31 23:59 UTC**. See `docs/PRODUCT_SPEC.md` and `docs/TECHNICAL_VERIFICATION.md`.

## MVP flow

The required headline flow is:

**Create Campaign → Back Privately → Claim Funding → Claim Refund**

- **Create Campaign:** public campaign metadata records the creator, goal, deadline, token configuration, deterministic campaign ID, and derived status. The browser creates a creator claim secret; only its commitment is intended for on-chain storage.
- **Back Privately:** from a shielded STRK20 balance, the browser generates a cryptographically random receipt secret, derives a domain-separated commitment, prepares the private withdrawal plus helper invocation, and increases raised totals and explicit escrow liabilities.
- **Claim Funding:** after success, the creator may claim the full raised amount, including overfunding. Status is derived; no explicit `finalize()` transaction is required.
- **Claim Refund:** after failure, each valid contribution should be refundable exactly once, but only through the approved authorization and destination-binding design below.

This is the target MVP flow. The complete four-flow lifecycle is not verified end to end.

## Scope and non-goals

### MVP scope

- One browser application.
- One stateful Cairo helper.
- One configured STRK20 pool.
- One fixed ERC-20 token.
- Public campaign creation and public campaign state.
- Private backing from an existing shielded STRK20 balance.
- Creator funding claim after success.
- Private refunds only after the exact authorization gate passes.

### Non-goals

Do not add a backend/database, auth service, indexer, custom privacy service, GraphQL, Postgres, cross-chain support, multi-token campaigns, private campaign creation, private-wallet-subaccount dependence, anonymous campaign creation, milestone mode, private governance, secret voting, AI campaign features, or broader crowdfunding features before the required STRK20 pool evidence exists. Keep the architecture simple until the MVP works with verified evidence.

## Architecture and privacy model

The intended path is:

**browser → official STRK20 Wallet API → wallet proof/prover/simulation → wallet or relayer → Starknet**

The STRK20 pool invokes the helper through `privacy_invoke`. The browser reads public campaign state/events, reads shielded balances through `strk20Balances([token])`, prepares private actions through the Wallet API, and submits through the wallet/relayer path.

The helper is intended to own campaign state, explicit contribution liabilities, pool authorization, and release outputs. Private funding is intended to use `strk20PrepareInvoke(actions, true)`, a pool-funded helper invocation, and an empty `Span<OpenNoteDeposit>` so funds remain in the helper. Funding claims/refunds are intended to approve the pool and return an `OpenNoteDeposit` producing a shielded output.

The privacy claim is narrow: the design aims to remove the **direct public wallet-to-campaign link** for funds already originating in a shielded STRK20 balance. It does **not** claim to hide contribution amounts, timing, deposits, campaign records, helper actions, aggregate totals, open-note payout amounts, campaign metadata, creator, goal, deadline, raised total, status, or relevant transaction activity. Distinctive amounts and rapid shield-to-contribution timing may weaken unlinkability; the UI should warn users to shield funds before contributing and avoid distinctive timing.

Required design invariants include pool-only `privacy_invoke` authorization (`get_caller_address() == configured_pool`), explicit liabilities rather than raw balance accounting, domain/chain/helper/campaign/secret-bound commitments, shared Poseidon fixtures, token/amount/campaign/recipient binding, duplicate and spent-claim rejection, campaign/deadline/creator/token/amount guards, checked arithmetic, state updates before external interactions, and no public backer address in BackerZero accounting. These are design requirements, not proof that the full implementation is verified.

## Refund authorization: bearer-secret refunds rejected; No fallback

**Bearer-secret refunds are rejected.** A receipt preimage alone is **rejected as authorization**. It does not prove recipient authorization, prevent replay, or safely bind the open-note destination to the intended recipient. Never place receipt secrets, viewing keys, private keys, seed phrases, credentials, or equivalent private material in calldata, logs, browser artifacts, fixtures, screenshots, analytics, commits, or manifests.

The intended mechanism is identity-bound **`ComputeAndInvoke`**. Its target behavior binds wallet/application context, one-time state or nonce, authorization, and the resulting `OpenNoteDeposit` destination to the intended recipient. Its status is **`PROTOCOL_SUPPORTED_BUT_CLIENT-UNVERIFIED`**: exact wallet/client conformance for calldata, ordering, destination handling, note serialization, replay resistance, and failure behavior remains to be proven.

There is **no fallback**. The project is fail-closed: if exact-wallet conformance cannot be established, defer the private refund flow. Do not implement a bearer-secret refund, guessed capability, anonymous claim, or other substitute. ADR-002 permits considering a tightly bound capability alternative only after POC failure through a new explicit security/design decision; that is not an approved current fallback.

Current status: ADR-002 is **`BLOCKED / PENDING EXACT-WALLET-CONFORMANCE-POC`** and the private refund MVP is **`DEFER_FAIL_CLOSED`**.

## Evidence status

### Verified or bounded

- The hackathon requirements/deadline snapshot is marked verified in `docs/TECHNICAL_VERIFICATION.md`: public/open-source licensed repository, Starknet mainnet app using the live STRK20 pool, at least three successful mainnet transactions touching the pool, public demo URL, and a three-minute demo video. The internal target is at least five qualifying hashes; seven is the target. This is a requirements snapshot, not proof BackerZero has satisfied those release gates.
- Prompt 4B isolated local baseline/non-private path is **PASS**: local helper declaration/deployment, `sncast` invocation, and starknet.js client execution succeeded on local devnet only. This is not mainnet, privacy, proof, production, or complete-lifecycle evidence.
- Prompt 4B-2A checkout/syntax preparation passed, but bootstrap stops because no authoritative immutable archive/image digest is committed. Real prover execution and generic real-proof E2E were not reached.

### Unverified or blocked

**No verified real privacy proof exists.** There is no verified generic private E2E lifecycle and no verified `ComputeAndInvoke` POC. Generic E2E is **`NOT_REACHED`**; `ComputeAndInvoke` is **`NOT_VERIFIED`**.

Still unverified: mainnet pool address, token and decimals, pool/token compatibility, final helper ABI/calldata, `OpenNoteDeposit` serialization and empty-span encoding, literal `OPEN`, wallet-resolved note IDs, exact wallet support for identity-bound `ComputeAndInvoke`, deployment, mainnet transactions, proving, relayer behavior, simulation, settlement, and the complete four-flow lifecycle.

Do not describe local POC material as privacy proof, mainnet deployment, production demo, audit, or verified wallet compatibility.

## Version and GitHub evidence

- **Pinned upstream `starknet-privacy` source commit:** `b59d8a141e49a9d940fb14dfe935cbecb8202814`.
- **Documented BackerZero handoff baseline/current GitHub commit:** `1c49b764f80d56040cf0aba8007f452172d36ec2`. This is not deployment or privacy proof.
- **Observed local checkout during this handoff:** `e93d51e4fd8a970d9b725938e627f62603f890fa`. Do not silently treat this observed checkout HEAD as the documented handoff baseline; reconcile the GitHub reference before relying on commit identity.
- **Failed Actions run:** <https://github.com/ToXMon/backerzero-strk20/actions/runs/32551221317>.
- The run failed at the official GHCR prover image pull/verification gate for `ghcr.io/starkware-libs/starknet-privacy/transaction-prover:PRIVACY-0.14.3-RC.2`. The recorded preflight guard stopped **before `docker pull`** because `scripts/privacy-image-digest.txt` contained no authoritative immutable digest; cleanup independently stopped at the same missing-digest guard.
- This establishes a missing immutable-digest prerequisite. It does **not** establish GHCR authentication failure, tag absence, platform-resolution failure, or prover-runtime failure.
- **RC.2/RC.5 discrepancy:** the upstream README prover/service row names `PRIVACY-0.14.3-RC.2`, while the checked-in SDK manifest is `0.14.3-rc.5`. The documented compatibility row uses SDK/prover/discovery RC.2, privacy contracts RC.0, and Pathfinder `v0.22.7`. The materials do not establish SDK RC.5 compatibility with the RC.2 prover row. Do not mix revisions speculatively.

## Exact files and next actions

### Evidence and decision sources

1. `docs/PROJECT_STATE.md` — current status; preserve the local-only baseline, missing-digest blocker, unresolved wallet conformance, and deferred refund state.
2. `docs/TECHNICAL_VERIFICATION.md` — primary evidence ledger; preserve the exact Actions run, preflight failure, pinned commit, versions, and non-verification statements.
3. `docs/ADR/002-refund-authorization.md` — keep blocked until an exact-wallet POC proves authorization, destination binding, one-time replay resistance, failure behavior, and version compatibility.
4. `docs/OPEN_QUESTIONS.md` — unresolved pool, wallet, proof, serialization, and lifecycle questions.
5. `docs/THREAT_MODEL.md`, `docs/ARCHITECTURE.md`, `docs/PRODUCT_SPEC.md`, `docs/BUILD_PACKET.md`, and `docs/DECISIONS.md` — privacy boundary, security invariants, product scope, build evidence, and decisions.

### Runtime/configuration and POC files

6. `.github/workflows/privacy-prover-hosted-poc.yml` — if separately authorized, retrieve targeted run/job/log/artifact evidence for run `32551221317`.
7. `scripts/privacy-image-digest.txt` — obtain and independently verify authoritative metadata for the unchanged official RC.2 image; otherwise preserve the blocker.
8. `scripts/privacy-env.sh` — keep immutable toolchain selectors; do not loosen to floating versions.
9. `scripts/privacy-prover-contract.env` — use one authoritative compatibility row; do not mix RC.2/RC.5/RC.0 without proof.
10. `scripts/run-privacy-e2e.sh` — do not use it to claim generic private E2E or real proof before stop conditions clear.
11. `poc/compute-and-invoke/` — local-only POC materials; any future POC must be exact-wallet, identity-bound, destination-aware, and replay-tested.
12. `strk20.json` — not submission-ready; never add placeholders, fabricated hashes, or unverified local transactions.

Planned implementation paths include `contracts/Scarb.toml`, `contracts/snfoundry.toml`, `contracts/src/lib.cairo`, helper/interface/hashing sources and tests, `packages/strk20-actions/src/index.ts` and tests, wallet/action/capability code, and browser code. Planned operations include `scripts/deploy-mainnet.sh`, `verify-contract.ts`, `seed-demo.ts`, `verify-mainnet.ts`, and `record-tx.ts`. The supplied evidence does not establish that all planned paths exist or are complete. Release docs include `docs/PRD.md`, `docs/PRIVACY.md`, `docs/COSTS.md`, `docs/MAINNET_EVIDENCE.md`, `docs/DEMO_SCRIPT.md`, `docs/RUNBOOK.md`, and related ADRs.

## Constraints and stop conditions

- Work only in `/a0/usr/projects/backerzero-strk20`.
- For this handoff, modify only `docs/PROJECT_CONTEXT.md` and `docs/DEVIN_HANDOFF.md`; do not change `docs/PROJECT_STATE.md` or unrelated files.
- Do not touch product/refund logic.
- Do not run generic E2E or generic `ComputeAndInvoke`.
- Do not begin Prompt 5.
- Do not implement or revive bearer-secret refund logic.
- Do not broaden prover investigation beyond a targeted diagnosis/blocker report.
- Do not deploy to mainnet, broadcast transactions, use real funds, or alter the release manifest without explicit human approval.
- Do not fabricate transactions, deployments, demos, tests, audits, privacy proofs, compatibility, or completion claims.
- Do not put secrets or private user data in Git, logs, fixtures, screenshots, analytics, artifacts, or manifests.
- Do not commit or push.

Current release gates are G0 repository build, G1 mainnet pool sanity action, G2 contract invariant suite, G3 simulated Wallet API actions, G4 complete tiny-value lifecycle, G5 at least five successful mainnet pool transactions, G6 production demo, and G7 three-minute video plus final `strk20.json`. Current evidence reaches only the local baseline/non-private path and does not satisfy G1–G7.
