# Devin Takeover Handoff

## Canonical context

Read [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) first. It is the canonical takeover handoff for BackerZero and governs the mission, STRK20 Privacy Sprint 2026 judging objective, MVP scope, architecture/privacy boundary, evidence status, exact files, next actions, constraints, and stop conditions. This file is only a concise operational pointer and must not contradict it.

## Mission and MVP

BackerZero is the Starknet/STRK20 crowdfunding MVP: **Public campaigns. Private backers. Trustless refunds.** The required flow is:

**Create Campaign → Back Privately → Claim Funding → Claim Refund**

The intended scope is one browser app, one stateful Cairo helper, one configured STRK20 pool, and one fixed ERC-20 token. Do not broaden scope before required pool and lifecycle evidence exists.

## Refund authorization gate

- **Bearer-secret refunds are rejected.** A receipt preimage alone does not prove recipient authorization, prevent replay, or bind the open-note destination.
- Identity-bound **`ComputeAndInvoke`** is intended, but is currently **`PROTOCOL_SUPPORTED_BUT_CLIENT-UNVERIFIED`** and requires an exact-wallet conformance POC.
- **No fallback.** If exact-wallet conformance is not established, defer the private refund flow and fail closed. Do not substitute a bearer secret, guessed capability, or anonymous claim.
- Never place receipt secrets, viewing keys, private keys, seed phrases, credentials, or equivalent private material in calldata, logs, artifacts, fixtures, screenshots, analytics, commits, or manifests.

## Evidence boundary

- Pinned upstream `starknet-privacy` commit: `b59d8a141e49a9d940fb14dfe935cbecb8202814`.
- Documented BackerZero GitHub handoff commit: `1c49b764f80d56040cf0aba8007f452172d36ec2`.
- RC discrepancy remains unresolved: the official prover row is `PRIVACY-0.14.3-RC.2`, while the checked-in SDK manifest is `0.14.3-rc.5`; do not mix revisions speculatively.
- Failed Actions run: <https://github.com/ToXMon/backerzero-strk20/actions/runs/32551221317>.
- The exact recorded failure was the deliberate preflight guard stopping **before `docker pull`** because `scripts/privacy-image-digest.txt` contained no authoritative immutable digest. This does not prove GHCR authentication, tag, platform-resolution, or prover-runtime failure.
- There is **no verified real privacy proof, generic private E2E lifecycle, or `ComputeAndInvoke` POC**. Generic E2E is **`NOT_REACHED`**; `ComputeAndInvoke` is **`NOT_VERIFIED`**. ADR-002 remains **`BLOCKED / PENDING EXACT-WALLET-CONFORMANCE-POC`** and private refunds remain **`DEFER_FAIL_CLOSED`**.
- Local Prompt 4B evidence is only a local devnet/non-private baseline; it is not mainnet, proof, production, or complete-lifecycle evidence.

## Immediate next actions

1. Read `docs/PROJECT_CONTEXT.md`, `docs/PROJECT_STATE.md`, `docs/TECHNICAL_VERIFICATION.md`, `docs/ADR/002-refund-authorization.md`, `docs/ARCHITECTURE.md`, `docs/THREAT_MODEL.md`, `docs/OPEN_QUESTIONS.md`, and `docs/BUILD_PACKET.md`.
2. If separately authorized, retrieve targeted authenticated logs/artifacts for run `32551221317` and preserve the exact blocker.
3. Obtain and independently verify authoritative digest metadata for the unchanged official RC.2 image and one compatible prover-contract row; otherwise preserve the blocker.
4. Keep `strk20.json` unsubmitted and free of placeholders or fabricated hashes.

## Stop conditions and constraints

Work only in `/a0/usr/projects/backerzero-strk20`. Do not run generic E2E or generic `ComputeAndInvoke`. Do not begin Prompt 5. Do not implement refund logic, do not revive bearer-secret authorization, and do not broaden prover investigation beyond a targeted diagnosis/blocker report. Do not deploy to mainnet, broadcast transactions, use real funds, fabricate evidence, commit, or push. Preserve all uncertainty and distinguish local/mock evidence from verified wallet, proof, and mainnet evidence.
