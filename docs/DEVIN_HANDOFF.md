# Devin Takeover Handoff

## Mission and MVP

BackerZero is a Starknet/STRK20 crowdfunding MVP:

**Create Campaign → Back Privately → Claim Funding → Claim Refund**

Keep the implementation narrow: one browser application, one stateful Cairo helper, one verified STRK20 pool, and one fixed ERC-20 token. No backend, database, custom privacy service, cross-chain support, or multi-token scope.

## Non-negotiable security decisions

- **Bearer-secret refunds are rejected.** A receipt preimage alone does not prove recipient authorization, prevent replay, or bind the open-note destination.
- **Identity-bound `ComputeAndInvoke` is intended** for creator claims/refunds and exact wallet/application-context binding.
- **No fallback.** If exact-wallet conformance cannot be established, defer/fail closed. Do not silently substitute a bearer secret, guessed capability flow, or anonymous/replay-safe claim.
- Never log, upload, emit, screenshot, or fixture receipt secrets, viewing keys, private keys, seed phrases, or credentials.

## Verified baseline and current boundary

- Pinned upstream source: `starkware-libs/starknet-privacy` commit `b59d8a141e49a9d940fb14dfe935cbecb8202814`.
- Documented upstream README prover row: `PRIVACY-0.14.3-RC.2`.
- Checked-in SDK manifest: `0.14.3-rc.5`; RC.5 versus README RC.2 remains a compatibility discrepancy.
- Local selectors are immutable in `scripts/privacy-env.sh`: Node `24.8.0`, Scarb `2.18.0`, Starknet Foundry `0.63.0`, starknet-devnet `0.8.0-rc.3`.
- Prompt 4B isolated baseline and non-private local path: **PASS**.
- Local helper declaration/deployment, `sncast` invoke, and starknet.js client execution: **verified locally only**.
- No mainnet deployment, broadcast, real-funds activity, prover runtime, privacy proof, or production audit is claimed.

## Canonical upstream architecture

The intended upstream shape is: browser → official STRK20 Wallet API → wallet proof/prover/simulation → wallet/relayer → Starknet; the STRK20 pool calls the single BackerZero Cairo helper through `privacy_invoke`. Private funding uses shielded balance reads, private action preparation, literal `OPEN` handling where required, and pool-funded helper invocation. Release flows must use the wallet-resolved `OpenNoteDeposit` plus identity-bound `ComputeAndInvoke` context. Exact-wallet conformance and recipient/destination binding are **NOT_VERIFIED** and block refund implementation.

## Exact GitHub state

- Expected handoff baseline commit: `1c49b764f80d56040cf0aba8007f452172d36ec2`.
- Hosted workflow: <https://github.com/ToXMon/backerzero-strk20/actions/runs/32551221317>
- The run failed at the exact official GHCR prover image pull/verification gate for:
  `ghcr.io/starkware-libs/starknet-privacy/transaction-prover:PRIVACY-0.14.3-RC.2`
- The workflow is deliberately fail-closed when no authoritative immutable digest is committed. It does not prove that the image, prover contract, or privacy lifecycle works.
- **No proof is claimed.** No real privacy proof, generic private E2E, or `ComputeAndInvoke` POC has been verified.

## Inspect first

- `docs/PROJECT_STATE.md`
- `docs/ARCHITECTURE.md`
- `docs/TECHNICAL_VERIFICATION.md`
- `docs/ADR/002-refund-authorization.md`
- `.github/workflows/privacy-prover-hosted-poc.yml`
- `scripts/privacy-env.sh`
- `scripts/run-privacy-e2e.sh`
- `scripts/privacy-image-digest.txt`
- `scripts/privacy-prover-contract.env`
- `poc/compute-and-invoke/` (local-only POC materials; do not treat as verified privacy evidence)

## Devin's next actions

1. Use authenticated GitHub CLI/API run and job logs for run `32551221317`; preserve the exact failing step, job conclusion, and relevant GHCR error. Do not infer from summaries or rerun unrelated tests.
2. Confirm whether the failure is registry authentication/permission, tag availability, manifest/platform resolution, digest verification, or the deliberate missing-authoritative-digest guard. Record the exact blocker and evidence.
3. If and only if an authoritative digest for the unchanged official RC.2 image and its documented compatible prover contract can be independently established, propose the smallest **fail-closed** patch. Pin by digest; retain exact tag/image identity and platform checks; do not invoke undocumented endpoints or commands.
4. Otherwise make no speculative code change and report the exact blocker, logs, and required upstream evidence. Do not rebuild, substitute, retag, use `latest`, or use another prover image.
5. Stop after this diagnosis/patch-or-blocker report. Do not implement refund logic, continue the prover investigation beyond the targeted diagnosis, repeat SDK research, run generic E2E/`ComputeAndInvoke`, or begin Prompt 5.

## Constraints

- Local/dev only; no mainnet deployment, broadcast, wallet signing, or real funds.
- No secrets or private user material in Git, logs, artifacts, fixtures, or screenshots.
- Never use `latest`, a substitute image, a rebuilt image, or an unverified tag-only reference for the official prover.
- Preserve fail-closed behavior and distinguish mocked/local checks from real wallet/mainnet evidence.

## Acceptance criteria

- Authenticated logs identify the precise GHCR pull/verification failure, or a minimal digest-only fail-closed patch is proposed with evidence and reviewable diff.
- The unchanged official image identity and pinned upstream source remain explicit.
- No refund logic, generic private E2E, ComputeAndInvoke POC, Prompt 5 work, mainnet activity, or privacy claim is introduced.
- Any patch has targeted syntax/tests only; no generated files, caches, `.tools`, `node_modules`, `target`, secrets, or unrelated files are staged.
- Final report states clearly: **no real privacy proof, generic private E2E, or `ComputeAndInvoke` POC has been verified.**
