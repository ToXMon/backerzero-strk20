# Prompt 5B Builder Plan — Sepolia Lifecycle Rehearsal

**Date:** 2026-08-23
**Owner:** Builder
**Phase:** Planning only; no implementation or chain execution authorized by this document
**Objective:** Rehearse the smallest end-to-end BackerZero lifecycle against Starknet Sepolia, using the existing Prompt 5A Cairo helper and STRK20 action/proof infrastructure, without involving Starknet mainnet.

## 1. Planning boundary and safety gate

This document is a plan only. During this planning phase:

- Do not edit implementation code.
- Do not deploy contracts.
- Do not broadcast transactions.
- Do not spend Sepolia or mainnet funds.
- Do not create, copy, or commit secrets.
- Do not change `strk20.json`.
- Do not claim that a rehearsal succeeded until its receipts, status, event/output data, and evidence files are independently checked.
- Do not use any mainnet RPC, account, pool, token, or deployment profile.

The planned network is **Starknet Sepolia only**. No mainnet path is involved in the Prompt 5B execution plan. Mainnet deployment and mainnet transactions remain a separate, explicit human-approval gate and are out of scope here.

The existing repository contains two contradictory status narratives:

1. `docs/PROJECT_STATE.md` and `docs/TECHNICAL_VERIFICATION.md` record a successful Prompt 4 Sepolia real-proof rehearsal and a passing ComputeAndInvoke conformance run.
2. `docs/PROJECT_CONTEXT.md` and `docs/DEVIN_HANDOFF.md` preserve an older handoff state in which the proof and ComputeAndInvoke work are still blocked.

The plan therefore treats the recorded hashes and status labels as **prior evidence to revalidate**, not as permission or proof that Prompt 5B is complete. The fresh run must produce its own evidence.

## 2. Smallest end-to-end target

The smallest useful Prompt 5B target is:

1. Build and test the existing Prompt 5A implementation locally.
2. Verify the deployed BackerZero class artifact and the Sepolia RPC/prover prerequisites read-only.
3. Declare the BackerZero class on Sepolia if absent, then deploy one helper instance with the configured Sepolia pool and token. Both actions require explicit human approval because they broadcast and consume testnet funds.
4. Create one short-lived **success campaign** with a tiny goal.
5. Perform one private Back operation from a shielded STRK20 balance.
6. Wait for expiry and perform Claim Funding into a shielded open note.
7. Create one short-lived **failure campaign**.
8. Perform one private Back operation below the goal.
9. Wait for expiry and perform Claim Refund through identity-bound ComputeAndInvoke, only if exact-wallet/client conformance is freshly verified.
10. Verify both lifecycle outputs, one-time behavior, accounting, pool involvement, and receipts.
11. Run negative tests against both the local contract and the Sepolia action/proof path where a safe, independently authorized negative transaction is justified.
12. Write a redacted evidence record and update the designated documentation. Never write private keys, viewing keys, receipt secrets, or seed phrases to the repository or evidence.

This deliberately avoids a frontend, database, indexer, or multi-token expansion. The existing helper and action package are the smallest surfaces needed to demonstrate the protocol lifecycle.

## 3. Existing Prompt 5A production path

### 3.1 Cairo helper

The production helper is `contracts/src/backerzero.cairo`, with interfaces in:

- `contracts/src/interfaces.cairo`
- `contracts/src/types.cairo`
- `contracts/src/hashing.cairo`
- `contracts/src/lib.cairo`

Constructor:

```text
constructor(pool: ContractAddress, token: ContractAddress)
```

Public operations:

```text
create_campaign(goal, deadline, creator_claim_commitment) -> campaign_id
privacy_invoke(operation) -> Span<OpenNoteDeposit>
```

The `privacy_invoke` entrypoint first requires:

```text
get_caller_address() == configured_pool
```

The three operation variants are:

- `Back(BackOperation)`
- `ClaimFunding(ClaimFundingOperation)`
- `ClaimRefund(ClaimRefundOperation)`

BackerZero stores explicit `total_escrow`, campaign state, and contribution state. It does not store a public backer address. Back parks funds and returns an empty output span. Funding and refund claims mark state before approving the configured pool and return exactly one `OpenNoteDeposit`.

### 3.2 Hashing and capability binding

Cairo hashing is in `contracts/src/hashing.cairo`; TypeScript parity is in `packages/strk20-actions/src/hash.ts`.

The required domain-separated values and field order are:

- Campaign ID: domain, chain ID, helper, creator, goal, deadline; low 64 bits, with zero mapped to one.
- Receipt commitment: domain, chain ID, helper, campaign ID, receipt secret.
- Refund ID: domain, chain ID, helper, campaign ID, token, amount, destination, receipt secret, identity binding, context, sequence nonce.
- Creator commitment: domain, chain ID, helper, campaign ID, creator secret.

The back operation stores the refund ID at contribution time. A refund must reproduce the exact identity, context, sequence nonce, destination, token, amount, and receipt-secret binding.

Reusable cross-language fixtures are in:

- `contracts/tests/fixtures.cairo`
- `packages/strk20-actions/src/fixtures.ts`

### 3.3 TypeScript action layer

The reusable package is `packages/strk20-actions/`.

Relevant builders in `packages/strk20-actions/src/actions.ts`:

- `buildCreateCampaign`
- `buildBackOperation`
- `buildClaimFundingOperation`
- `buildClaimRefundOperation`
- `buildOpenNoteDeposit`
- `buildRefundComputeAndInvoke`
- `getSelector`

The package currently builds typed operation data and ComputeAndInvoke payload data. It does not itself prove that a real privacy-capable wallet accepts the complete Prompt 5B lifecycle. That must be tested through the selected wallet/client path.

The current provider file, `packages/strk20-actions/src/provider.ts`, has a shielded-balance stub. It must not be treated as production Wallet API integration. Prompt 5B should use the proven upstream privacy SDK/wallet harness path for the rehearsal and record this package limitation rather than silently treating the stub as live functionality.

### 3.4 Existing proof infrastructure

The existing Prompt 4 infrastructure is:

- `scripts/run-privacy-real-proof.sh`
- `scripts/rpc-capability-proxy.py`
- `poc/compute-and-invoke/e2e/bz-sepolia-harness.ts`
- `poc/compute-and-invoke/e2e/bz-sepolia-real-proof.test.ts`
- `poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts`
- `poc/compute-and-invoke/e2e/bz-sepolia-real-proof.test.ts`
- `poc/compute-and-invoke/e2e/README.md`

The shell script starts:

1. A local capability-splitting RPC proxy.
2. A prover using either a pinned prover image or an explicitly supplied local binary.
3. The upstream privacy E2E test with the repository’s Sepolia harness copied into the pinned checkout.

The proxy routes:

- Header/full-block/broadcast calls to `BZ_RPC_URL`, defaulting to PublicNode Sepolia.
- `starknet_getStorageProof` to `BZ_PROOF_URL`, configured for the storage-proof-capable Sepolia provider.

The current harness loads disposable accounts from the external file:

```text
${BZ_ACCOUNTS_FILE:-$HOME/.bz-sepolia/accounts.json}
```

It must never log or commit private keys. The viewing key must remain external as well.

The prior harness defaults include:

```text
BZ_RPC_URL=https://starknet-sepolia-rpc.publicnode.com
BZ_TX_RPC_URL=https://api.cartridge.gg/x/starknet/sepolia
BZ_WS_URL=wss://starknet-sepolia-rpc.publicnode.com
BZ_PROVER_URL=http://127.0.0.1:3000
BZ_PROVING_BLOCK_LAG=11
BZ_PROVE_TIMEOUT_MS=7200000
```

These are defaults, not a claim that the providers remain available or compatible. Before execution, issue read-only capability checks and record provider responses.

## 4. Baseline commands

Run these before any implementation or chain action. They are local/read-only or local test commands:

```bash
git status --short --branch
node --version
pnpm --version
scarb --version
snforge --version
docker --version
python3 --version
```

Repository/package baseline:

```bash
corepack enable
pnpm install --frozen-lockfile
pnpm typecheck
pnpm test
pnpm build
```

Cairo baseline:

```bash
cd contracts
scarb fmt --check
scarb build
snforge test
cd ..
```

Package-specific baseline, if the workspace does not expose equivalent root scripts:

```bash
cd packages/strk20-actions
npm ci
npm run typecheck
npm test
cd ../..
```

Expected pre-chain gates:

- Cairo formatting, build, and existing tests pass.
- TypeScript typecheck and existing tests pass.
- No implementation files are changed by the baseline run.
- Git diff contains no generated secrets or account material.

The baseline must be recorded as a command/result table in the eventual evidence file, not as an unsupported “all tests pass” statement.

## 5. Sepolia preflight and account strategy

### 5.1 Accounts

Use only disposable Sepolia accounts loaded from an external file outside the repository. The existing harness names are:

- `admin`: deployer/relayer and outside-execution submitter.
- `alice`: shielded backer and note owner.

A successful rehearsal may use one account for both roles only if the wallet/proof path requires it, but keeping `admin` and `alice` separate is preferable because it exercises the outside-execution boundary.

Required external inputs:

- account addresses and private keys in `$BZ_ACCOUNTS_FILE`;
- a disposable viewing key supplied through `BZ_VIEWING_KEY`;
- a chosen tiny-value Sepolia token balance;
- enough Sepolia STRK for declaration/deployment, ordinary transactions, and private proof settlement;
- enough configured token balance for the two tiny contributions.

No secrets may be written to:

- Git-tracked files;
- `poc/compute-and-invoke/e2e/evidence/`;
- logs;
- screenshots;
- test fixtures;
- manifests;
- issue/PR text.

Before running, confirm the account file permissions and redact any command output that could reveal a key.

### 5.2 Funding

Funding is a human-operated prerequisite:

1. Obtain a small Sepolia STRK fee reserve for the external accounts.
2. Obtain a tiny amount of the chosen configured ERC-20 token.
3. Confirm balances by read-only RPC calls.
4. Do not use mainnet assets or a mainnet signer.
5. Set a hard maximum rehearsal budget before any broadcast.
6. Stop if fee estimates or required token amounts exceed that budget.

The plan does not prescribe a specific token address. The exact token, decimals, and pool compatibility remain an open question and must be verified from current official/read-only chain data before deployment.

### 5.3 Read-only RPC capability checks

Against the selected Sepolia endpoints, check and record:

```text
starknet_specVersion
starknet_chainId
starknet_blockNumber
starknet_getBlockWithTxHashes
starknet_getClass
starknet_getNonce
starknet_call
starknet_getStorageAt
starknet_getStorageProof
```

Also confirm:

- the chain ID is `SN_SEPOLIA`;
- the header endpoint supplies the commitment fields required by the prover;
- the proof endpoint accepts a sufficiently recent proving block;
- the proving block is at least the required stored-block lag and still inside the provider’s storage-proof retention window;
- transaction broadcast is routed only through the selected Sepolia transaction endpoint;
- no endpoint URL or environment value resolves to `SN_MAIN`.

The current proxy is intentionally simple and caches storage-proof responses. Its endpoint routing and cache behavior must be logged without logging private proof inputs.

## 6. Class and deployment checks

### 6.1 Build artifacts

After `scarb build`, identify the exact generated Sierra and CASM files for the BackerZero class. Do not guess paths. Use the build output and inspect the generated artifact names.

Compute and record, locally before broadcasting:

- Sierra class hash;
- compiled class hash;
- constructor ABI shape;
- ABI entrypoint selectors;
- artifact checksums.

The declaration payload must use the exact Sierra/CASM pair generated by the same build. Do not mix artifacts from another branch, compiler, or dependency row.

### 6.2 Declaration

Read-only check:

```text
starknet_getClass(class_hash)
```

If the class already exists on Sepolia, record the class hash and skip declaration.

If absent, prepare:

```text
sncast --profile <sepolia-profile> declare \
  --contract-name <BackerZero contract name>
```

The exact profile name is operator-specific and must not be hard-coded in repository docs as a credential-bearing configuration. Declaration requires explicit human approval before broadcast.

After declaration:

- wait for the receipt;
- require successful execution/finality;
- read the declared class back by class hash;
- compare the chain class hash with the locally computed class hash;
- store only public hashes and receipt metadata in evidence.

### 6.3 Deployment

Constructor values must be verified before approval:

```text
pool = verified Sepolia STRK20 pool address
token = verified Sepolia ERC-20 address
```

Prepare the deployment with a fresh salt and exact constructor calldata. Do not use the Prompt 4 privacy-pool constructor shape for BackerZero; that harness deploys a privacy pool, not the BackerZero helper.

Before broadcast:

- estimate deployment fee;
- display the class hash and constructor addresses;
- verify both addresses are nonzero and on Sepolia;
- verify the pool/token values match the planned action builders;
- require explicit human approval.

After broadcast:

- wait for a successful deployment receipt;
- derive/record the helper address;
- read `get_pool()` and `get_token()` from the deployed helper;
- confirm they equal the approved constructor values;
- read the class at the deployed address;
- record deployment transaction, class hash, helper address, pool, and token.

No mainnet deployment command may be used or copied into this rehearsal.

## 7. Campaign lifecycle calls

The following calls are the intended Sepolia sequence. Exact calldata must be generated using the existing ABI/action definitions and then reviewed before approval.

### 7.1 Create success campaign

Generate a fresh creator secret outside Git and derive:

```text
creator_claim_commitment =
  computeCreatorCommitment(
    chainId,
    helper,
    campaignId,
    creatorSecret
  )
```

Because the campaign ID includes the creator, goal, deadline, chain ID, and helper, the implementation must either:

1. obtain the creator address and calculate the deterministic campaign ID before calling `create_campaign`, or
2. use the returned campaign ID and verify it equals the independently calculated value.

Use a short future deadline suitable for a rehearsal, but long enough to account for transaction confirmation and proof generation. Suggested operating range: several minutes, not seconds.

Call:

```text
create_campaign(goal, deadline, creator_claim_commitment)
```

Verify:

- successful receipt;
- `CampaignCreated` event;
- creator, goal, deadline, token, and commitment;
- campaign ID matches the local hash calculation;
- status is `Active`;
- raised and refunded totals are zero.

The creator secret remains external and is never put in evidence.

### 7.2 Private Back into success campaign

Before the private action:

- verify Alice has the required shielded balance through the supported privacy discovery path;
- generate a fresh receipt secret externally;
- derive the receipt commitment;
- obtain the exact identity binding, context, destination, sequence nonce, and refund ID required by the approved wallet/client flow;
- verify action calldata has the exact Back operation shape;
- use the configured token and tiny amount.

The wallet action must follow the existing STRK20 composition pattern:

```text
withdraw/transfer from shielded balance
    -> invoke BackerZero privacy action
```

For the parked Back operation, the expected helper output is an empty `Span<OpenNoteDeposit>`.

Run the wallet’s prepare/simulate step first:

```text
strk20PrepareInvoke(actions, true)
```

Do not submit if simulation fails or if the action contains:

- a public backer address in helper accounting;
- a numeric replacement for a wallet-resolved `OPEN` placeholder where `OPEN` is required;
- a hex-normalized `${openNoteIds[0]}` placeholder;
- a wrong token, helper, campaign ID, amount, or commitment;
- an unapproved destination/context binding.

After human approval, submit through the selected Sepolia wallet/relayer path and wait for success.

Verify:

- pool involvement;
- helper `Backed` event;
- raised increases exactly by the contribution;
- contribution count increments;
- `total_escrow` increases exactly by the contribution;
- no backer address is stored/emitted by BackerZero;
- `get_contribution` exposes only the expected commitment-derived state;
- status remains `Active` before the deadline;
- returned output is empty for Back.

### 7.3 Claim Funding

After the success campaign deadline:

- read the campaign and confirm `raised >= goal`;
- prepare a private claim with the creator capability;
- use the wallet’s literal `OPEN` transfer and wallet-resolved open-note ID convention exactly as documented by the selected client;
- validate the operation amount equals the full raised amount, including any overfunding;
- run prepare/simulate before submission.

The helper must:

1. validate deadline, success, token, amount, and creator commitment;
2. mark the campaign claimed;
3. reduce `total_escrow`;
4. approve the pool;
5. return one exact `OpenNoteDeposit`.

After human approval and settlement, verify:

- `FundingClaimed` event;
- campaign status is `Claimed`;
- `claimed == true`;
- total escrow decreases to the expected value;
- allowance to the pool equals the claim amount;
- one shielded note is discoverable for the intended recipient;
- a second claim fails with `ALREADY_CLAIMED`.

### 7.4 Create failure campaign

Create a second campaign with:

- a goal larger than the planned contribution;
- a short future deadline;
- a fresh creator secret and commitment.

Verify the same creation invariants as above. Keep this campaign separate from the success campaign so evidence can distinguish the two state machines.

### 7.5 Private Back into failure campaign

Repeat the Back flow with a fresh receipt secret and a contribution below the goal.

Verify:

- simulation succeeds;
- the helper records the exact contribution;
- `raised < goal`;
- the campaign remains `Active` before expiry;
- no public backer address is recorded;
- the external receipt metadata is retained only by the operator, not in repository evidence.

### 7.6 Claim Refund through ComputeAndInvoke

This is the critical gate. Do not use a receipt secret alone as authorization.

Proceed only if the exact selected wallet/client path has freshly demonstrated:

- identity-bound ComputeAndInvoke construction;
- correct call and note serialization;
- destination binding;
- one-time replay resistance;
- correct context and sequence handling;
- fail-closed behavior for amount, destination, target, calldata, and context substitution;
- compatibility with the pinned privacy runtime row.

Use the existing `buildRefundComputeAndInvoke` structure as the serialization reference, but verify it against the actual wallet/client ABI rather than assuming the package builder is sufficient.

The expected conceptual action is:

```text
open-note collection using wallet-resolved OPEN semantics
    -> ComputeAndInvoke call to BackerZero ClaimRefund
    -> exact OpenNoteDeposit to the intended shielded recipient
```

Before submission:

- verify the campaign is expired and below goal;
- verify the refund amount equals the stored contribution;
- recompute the receipt commitment and refund ID;
- verify identity binding, context, destination, and sequence nonce match the values committed at Back time;
- run prepare/simulate;
- display the intended helper, campaign, amount, output destination, and proof context;
- obtain human approval.

After settlement, verify:

- `Refunded` event;
- contribution is marked refunded;
- `refunded_total` increases exactly;
- `total_escrow` decreases exactly;
- allowance to the pool equals the refund amount;
- one shielded refund note is discoverable;
- replay fails;
- altered destination, amount, context, target, or calldata fails closed.

If exact-wallet conformance is not established, stop this flow and record `DEFER_FAIL_CLOSED`. Do not substitute a bearer-secret refund or a guessed anonymous claim.

## 8. Negative-test matrix

### 8.1 Existing local contract tests

Run, preserve, and report the existing tests in `contracts/tests/test_backerzero.cairo`, including:

- zero goal;
- past deadline;
- campaign ID collision;
- non-pool caller;
- backing after deadline;
- wrong token;
- zero amount;
- insufficient helper balance;
- creator claim before deadline;
- creator claim below goal;
- wrong creator secret;
- refund before deadline;
- refund on successful campaign;
- wrong refund identity;
- wrong refund destination;
- double refund;
- multiple-backer accounting;
- overfunding claim;
- exact OpenNoteDeposit token, amount, and note ID;
- allowance and escrow accounting.

Do not weaken or disable any failing test. A failure is a blocker to chain rehearsal until explained and fixed through a separately authorized implementation change.

### 8.2 Sepolia negative tests

Only run negative transactions after confirming the cost and state impact are acceptable. Prefer simulation or locally prepared malformed calls first.

Required cases:

1. Direct non-pool call to `privacy_invoke` is rejected.
2. Back with wrong token is rejected.
3. Back with zero amount is rejected.
4. Back after deadline is rejected.
5. Duplicate receipt commitment is rejected.
6. Claim Funding before deadline is rejected.
7. Claim Funding below goal is rejected.
8. Wrong creator capability is rejected.
9. Claim Funding replay is rejected.
10. Refund before deadline is rejected.
11. Refund on successful campaign is rejected.
12. Wrong amount is rejected.
13. Wrong identity binding is rejected.
14. Wrong destination is rejected.
15. Wrong context or sequence nonce is rejected.
16. Refund replay is rejected.
17. ComputeAndInvoke public calldata substitution is rejected.
18. The selected client cannot express private-context substitution as public calldata, and this limitation is recorded rather than overstated as a separate cryptographic test.

For every negative result, capture the expected revert/error classification without recording secrets. A malformed broadcast must not be used when an offline simulation can establish the same guard.

## 9. Evidence schema

Create a redacted, machine-readable evidence artifact outside the implementation path first; copy it into the repository only if the final approved schema permits it and after a secret scan.

Proposed schema:

```json
{
  "schemaVersion": 1,
  "run": {
    "label": "prompt5b-sepolia-lifecycle",
    "startedAtUtc": "2026-08-23T00:00:00Z",
    "finishedAtUtc": "2026-08-23T00:00:00Z",
    "network": "SN_SEPOLIA",
    "mainnetInvolved": false,
    "operatorApproval": {
      "declaration": false,
      "deployment": false,
      "lifecycleBroadcasts": false
    }
  },
  "toolchain": {
    "repositoryCommit": "public git commit",
    "scarbVersion": "version",
    "snforgeVersion": "version",
    "nodeVersion": "version",
    "starknetJsVersion": "version",
    "privacySourceCommit": "b59d8a141e49a9d940fb14dfe935cbecb8202814",
    "runtimeRow": "verified compatibility row or unresolved",
    "proverMode": "pinned image or local source-built binary",
    "proverVersion": "public version only"
  },
  "endpoints": {
    "headerRpc": "public Sepolia URL",
    "transactionRpc": "public Sepolia URL",
    "proofRpc": "public Sepolia URL",
    "proxyPort": 8547,
    "proverUrl": "http://127.0.0.1:3000"
  },
  "contracts": {
    "helperClassHash": "0x...",
    "compiledClassHash": "0x...",
    "declarationTx": "0x...",
    "helperAddress": "0x...",
    "deploymentTx": "0x...",
    "poolAddress": "0x...",
    "tokenAddress": "0x...",
    "tokenDecimals": null
  },
  "baseline": {
    "commands": [
      {"command": "scarb build", "result": "PASS"},
      {"command": "snforge test", "result": "PASS"},
      {"command": "pnpm typecheck", "result": "PASS"},
      {"command": "pnpm test", "result": "PASS"}
    ]
  },
  "lifecycle": [
    {
      "name": "create-success-campaign",
      "campaignId": "0x...",
      "tx": "0x...",
      "status": "PASS",
      "receiptStatus": "SUCCEEDED",
      "eventsChecked": true
    },
    {
      "name": "private-back-success",
      "tx": "0x...",
      "status": "PASS",
      "proof": {
        "provingBlockId": 0,
        "provingMs": 0,
        "proofFactsLength": 0,
        "proofDataLength": 0
      },
      "amount": "public tiny test amount",
      "poolInvolved": true,
      "outputCount": 0
    },
    {
      "name": "claim-funding",
      "tx": "0x...",
      "status": "PASS",
      "poolInvolved": true,
      "outputCount": 1,
      "noteAmount": "public tiny test amount"
    },
    {
      "name": "create-failure-campaign",
      "campaignId": "0x...",
      "tx": "0x...",
      "status": "PASS"
    },
    {
      "name": "private-back-failure",
      "tx": "0x...",
      "status": "PASS",
      "poolInvolved": true,
      "outputCount": 0
    },
    {
      "name": "claim-refund",
      "tx": "0x...",
      "status": "PASS",
      "authorization": "identity-bound-compute-and-invoke",
      "poolInvolved": true,
      "outputCount": 1,
      "noteAmount": "public tiny test amount"
    }
  ],
  "negativeTests": [
    {
      "name": "refund-replay",
      "result": "REJECTED",
      "errorClass": "public revert classification"
    }
  ],
  "accountingChecks": {
    "raisedMatchesContributions": true,
    "escrowNeverBelowLiabilities": true,
    "creatorClaimExactlyOnce": true,
    "refundExactlyOnce": true,
    "noBackerAddressInBackerZeroEvents": true
  },
  "notes": [
    "No private keys, viewing keys, receipt secrets, creator secrets, or seed phrases are present."
  ]
}
```

Never include:

- account private keys;
- seed phrases;
- viewing keys;
- receipt secrets;
- creator secrets;
- raw private proof inputs;
- unredacted wallet export files;
- credentials or authenticated RPC URLs;
- fabricated or placeholder transaction hashes.

A run that stops before broadcast must be recorded as `NOT_REACHED` or `BLOCKED`, with the precise blocker.

## 10. Exact reusable files and expected roles

### Existing files to reuse without broadening scope

- `contracts/src/backerzero.cairo` — deployed helper behavior.
- `contracts/src/interfaces.cairo` — public ABI.
- `contracts/src/types.cairo` — operation serialization.
- `contracts/src/hashing.cairo` — commitment/refund binding.
- `contracts/tests/test_backerzero.cairo` — local lifecycle and negative tests.
- `packages/strk20-actions/src/actions.ts` — operation and ComputeAndInvoke builders.
- `packages/strk20-actions/src/hash.ts` — cross-language hash parity.
- `packages/strk20-actions/src/fixtures.ts` — fixed parity vectors.
- `poc/compute-and-invoke/e2e/bz-sepolia-harness.ts` — external-account/prover/discovery harness.
- `poc/compute-and-invoke/e2e/bz-sepolia-real-proof.test.ts` — real-proof baseline.
- `poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts` — conformance and negative-test model.
- `scripts/run-privacy-real-proof.sh` — proxy/prover/upstream-test orchestration.
- `scripts/rpc-capability-proxy.py` — split Sepolia RPC capabilities.
- `poc/compute-and-invoke/e2e/README.md` — reproduction and evidence conventions.

### Files that may be added or updated only after separate implementation authorization

- A Prompt 5B Sepolia lifecycle harness/test under `poc/compute-and-invoke/e2e/`, if the existing harness cannot express the BackerZero helper lifecycle.
- A narrowly scoped deployment/preflight script under `scripts/`, if repeated manual commands create material transcription risk.
- A redacted evidence file under `poc/compute-and-invoke/e2e/evidence/`.
- `docs/PROJECT_STATE.md`, `docs/TECHNICAL_VERIFICATION.md`, `docs/OPEN_QUESTIONS.md`, `docs/THREAT_MODEL.md`, `docs/ARCHITECTURE.md`, and a runbook/evidence document, after facts are freshly verified.

Do not create a mainnet deployment script as part of Prompt 5B. Do not add a web application or database to complete this rehearsal.

## 11. Documentation updates after execution

Only after a successful or precisely blocked rehearsal, update:

1. `docs/PROJECT_STATE.md`
   - Prompt 5B status;
   - exact Sepolia helper/class/deployment facts;
   - lifecycle status by flow;
   - evidence path;
   - explicit `mainnetInvolved: false`.

2. `docs/TECHNICAL_VERIFICATION.md`
   - fresh Sepolia receipt evidence;
   - runtime/prover/provider row;
   - what was verified versus what remains unverified;
   - distinction between real proof, local mock, and client conformance.

3. `docs/OPEN_QUESTIONS.md`
   - resolve only questions answered by fresh evidence;
   - keep token, wallet, serialization, and mainnet questions open if not independently proven.

4. `docs/ARCHITECTURE.md`
   - document the actual Prompt 5A helper-to-pool operation shape and the exact private action path used in the rehearsal.

5. `docs/THREAT_MODEL.md`
   - record negative-test outcomes;
   - preserve the no-bearer-secret rule;
   - record residual timing/amount correlation and any wallet/client limitations.

6. `poc/compute-and-invoke/e2e/README.md`
   - add the Prompt 5B reproduction command and evidence schema;
   - clearly label Sepolia testnet evidence and do not call it mainnet evidence.

Do not update `strk20.json` from Sepolia rehearsal hashes. The hackathon manifest requires qualifying mainnet evidence and remains untouched.

## 12. Risks and mitigations

| Risk | Mitigation / stop condition |
| --- | --- |
| Current docs disagree about Prompt 4 evidence | Re-run and independently verify; preserve disagreement in status until reconciled |
| Wrong network or accidental mainnet endpoint | Require `SN_SEPOLIA`; inspect all endpoint/config values; hard-fail on `SN_MAIN` |
| Missing or incompatible prover/runtime | Verify pinned source/runtime row; stop rather than mixing RC versions |
| Storage-proof retention window expires | Select proving block only after capability checks; use the existing lag/window constraints |
| Hosted RPC rate limits or body limits | Use the existing capability proxy; keep requests small; stop on inconsistent responses |
| BackerZero ABI differs from privacy pool ABI | Generate calldata from exact Cairo types and test against a controlled local harness before broadcast |
| Incorrect token or decimals | Verify token metadata/read-only state before constructor approval; use one tiny token amount |
| Deploying the wrong class | Compare local Sierra/CASM hashes with chain declaration and deployed class |
| Campaign deadline expires during proof generation | Use a multi-minute rehearsal deadline and confirm state before each action |
| Refund remains bearer-secret-only | Stop and record `DEFER_FAIL_CLOSED`; no fallback |
| Open-note placeholder mishandled | Assert literal `OPEN` and `${openNoteIds[0]}` preservation in tests and prepared calldata |
| Lost or exposed operator secret | Keep all secrets in external files/environment; run secret scans; do not log raw inputs |
| Approval/interaction ordering causes state inconsistency | Verify existing effects-before-approval implementation and receipt behavior |
| Real testnet funds are lost due to contract bug | Tiny amounts, separate disposable accounts, local tests first, explicit human approval per broadcast |
| Negative test itself spends funds or mutates state | Prefer simulation; use disposable campaigns and tiny values; record any mutation |
| Overclaiming privacy | State only that the direct wallet-to-campaign link is intended to be obscured; amounts/timing/activity remain public |
| Package provider is still a stub | Use the verified upstream wallet/proof harness; do not label the package stub as live balance support |

## 13. Proposed execution gates

The builder must stop at each gate unless the result is satisfactory:

- **P0 — Baseline:** local Cairo/package tests and typechecks pass.
- **P1 — Network:** read-only RPCs prove Sepolia routing and required proof capabilities.
- **P2 — Artifact:** class hash, compiled class hash, constructor ABI, and checksums are known.
- **P3 — Approval:** a human explicitly approves declaration/deployment and gives a budget.
- **P4 — Deployment:** helper deployment succeeds and on-chain pool/token reads match the approved values.
- **P5 — Public setup:** success/failure campaigns are created and independently verified.
- **P6 — Private Back:** shielded-to-helper action simulates and settles with empty output and correct accounting.
- **P7 — Claim Funding:** success path returns one exact open-note output and rejects replay.
- **P8 — Refund authorization:** exact-wallet ComputeAndInvoke conformance passes; otherwise fail closed.
- **P9 — Claim Refund:** failure path returns one exact open-note output and rejects replay/substitution.
- **P10 — Evidence:** all hashes, receipts, events, outputs, provider/runtime data, and negative tests are redacted and verified.
- **P11 — Docs:** status and technical docs distinguish Sepolia rehearsal from mainnet qualification.

## 14. Open questions before implementation authorization

1. Which current Sepolia STRK20 pool address is authorized for this rehearsal?
2. Which single ERC-20 token and decimals are compatible with that pool and the selected wallet/prover path?
3. Is the existing `packages/strk20-actions` operation serialization accepted by the actual selected wallet, or is a narrowly scoped adapter required?
4. What exact ABI encoding does the live pool expect for `BackerZeroOperation` and `OpenNoteDeposit`?
5. Can the existing upstream harness invoke the BackerZero helper directly, or is a new focused Sepolia test required?
6. Which exact prover artifact/runtime row will be used, and does the host require the documented source-built CPU-compatible binary?
7. Can the selected wallet perform identity-bound ComputeAndInvoke for the refund path with destination binding and replay resistance?
8. What safe, redacted evidence location will be used for the fresh Prompt 5B run?
9. Which existing docs should be reconciled first to resolve the contradictory “verified” versus “blocked” Prompt 4 status?
10. What exact human approval procedure and maximum Sepolia budget will govern each broadcast?

## 15. Final scope statement

Prompt 5B is a **Sepolia-only, tiny-value, human-approved rehearsal** of the existing Prompt 5A protocol. It is not a mainnet deployment, not mainnet evidence, not a submission-manifest update, and not authorization to spend funds. The smallest acceptable result is either:

- a freshly verified success-and-failure lifecycle with redacted evidence and explicit limits; or
- a precise blocker report showing the first gate that could not be passed, without weakening tests, reviving bearer-secret refunds, mixing runtime versions, or fabricating completion claims.
