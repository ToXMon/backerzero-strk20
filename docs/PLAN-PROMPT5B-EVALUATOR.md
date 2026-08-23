# Prompt 5B Independent Evaluation & Validation Plan

- **Document:** `docs/PLAN-PROMPT5B-EVALUATOR.md`
- **Role:** Independent EVALUATOR (Audit & Verification Charter)
- **Phase:** Prompt 5B — Sepolia Lifecycle & Protocol Verification Planning
- **Status:** **PLANNING ONLY (NON-IMPLEMENTATION MODE)**
- **Constraints Applied:** No production code edits, no deployments, no fund expenditures, no secret creation, no mainnet broadcast.

---

## 1. Executive Summary & Evaluation Charter

This document establishes the independent evaluation and verification plan for **Prompt 5B** of the BackerZero project. BackerZero implements a privacy-preserving crowdfunding protocol on Starknet using the official STRK20 privacy pool architecture.

### 1.1 Objective
Verify that the complete four-step MVP lifecycle operates correctly, securely, and privately on Starknet Sepolia using the real STRK20 privacy runtime:
1. **Create Campaign** (Public creation, deterministic ID computation, creator capability commitment).
2. **Back Privately** (Shielded deposit via STRK20 pool, pool-mediated `privacy_invoke`, identity-bound refund commitment storage, escrow liability tracking).
3. **Claim Funding** (Creator withdrawal on campaign success, secret validation against commitment, pool approval, `OpenNoteDeposit` shielded payout).
4. **Claim Refund** (Backer withdrawal on campaign failure via identity-bound `ComputeAndInvoke`, 10-parameter Poseidon binding verification, `OpenNoteDeposit` shielded refund).

### 1.2 Evaluation Principles
- **Evidence-grounded:** Every pass/fail determination must cite an immutable on-chain receipt (`transaction_hash`), verified storage state, or deterministic test log.
- **Fail-closed:** Any ambiguity, assertion failure, missing receipt, or invariant violation immediately halts the evaluation with a status of `FAIL`.
- **Zero-knowledge & information boundary integrity:** Verify that no backer wallet address is stored, emitted, or leaked in calldata, while strictly respecting the narrow STRK20 privacy boundary (amounts, timing, and campaign IDs remain public).
- **Human approval gate:** No live transaction execution or deployment shall occur without explicit human approval.

---

## 2. Current Baseline Assessment (Prompt 5A Audit)

The codebase baseline as established by Prompt 5A and Prompt 4:

| Component | Repository Path | Prompt 5A Status | Evaluation Focus for 5B |
| :--- | :--- | :--- | :--- |
| **Cairo Protocol** | `contracts/src/backerzero.cairo` | 28/28 `snforge` tests pass | Live Sepolia execution & pool callbacks |
| **Cairo Types & Hashes** | `contracts/src/types.cairo`, `contracts/src/hashing.cairo` | Complete & domain-separated | Poseidon hash parity on Sepolia |
| **TypeScript Action Package** | `packages/strk20-actions/` | 16/16 `vitest` tests pass | Packaging & E2E integration |
| **Shared Fixtures** | `contracts/tests/fixtures.cairo`, `packages/strk20-actions/src/fixtures.ts` | Complete | Deterministic Cairo/TS vector consistency |
| **Privacy Runtime Row** | `ghcr.io/.../transaction-prover:PRIVACY-0.14.3-RC.2` | Verified on Sepolia (tx `0x57ba...`) | Real proof generation & `computeAndInvoke` |
| **Refund Authorization** | `docs/ADR/002-refund-authorization.md` | `BINDING_DEMONSTRATED` / `APPROVED_FOR_BUILD` | Live Sepolia `ComputeAndInvoke` execution |

---

## 3. Measurable 11-Gate Validation Plan

### Gate 1: Cairo & TypeScript Protocol Baseline
**Objective:** Confirm complete local test suite health, compilation integrity, type safety, and fixture parity before any network interaction.

- **Prerequisites:** Local Scarb v2.18.0, snforge v0.63.0, Node.js v20+, npm.
- **Commands:**
  ```bash
  # 1. Cairo Build & Format
  cd contracts
  scarb fmt --check
  scarb build
  snforge test

  # 2. TypeScript Actions Build & Tests
  cd ../packages/strk20-actions
  npm install --silent
  npm run typecheck
  npm run lint
  npm test
  ```
- **Assertions:**
  - `scarb build` compiles with 0 errors and 0 warnings.
  - `snforge test` passes 28/28 tests (including campaign creation, back, claim funding, claim refund, tamper tests, and escrow accounting).
  - `npm run typecheck` passes with zero diagnostics (`tsc --noEmit`).
  - `npm run lint` reports zero errors.
  - `npm test` passes 16/16 tests (unit and hash fixture parity).

---

### Gate 2: Production Sepolia Deployment & Class Verification
**Objective:** Deploy the compiled `BackerZero` helper contract to Starknet Sepolia, linked to the verified STRK20 privacy pool and test token.

- **Prerequisites:** Sepolia deployer account with sufficient STRK gas, declared `BackerZero` class hash, verified Sepolia STRK20 pool (`0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce` or equivalent declared class `0x52107fadffab71bdcbb6b2ccb68ba3e1b5558d94036538053e159d3076ad633`), and Sepolia ERC-20 token.
- **Execution:**
  1. Declare `BackerZero` class on Sepolia if not already declared.
  2. Deploy `BackerZero` with constructor arguments: `[pool_address, token_address]`.
- **Assertions:**
  - Deploy transaction reaches `ACCEPTED_ON_L2` and execution status `SUCCEEDED`.
  - Read `get_pool()` on helper returns the exact specified pool address.
  - Read `get_token()` on helper returns the exact specified token address.
  - Read `get_total_escrow()` on helper returns `0`.

---

### Gate 3: Real Pool-Mediated Private Backing (Success & Failure Campaigns)
**Objective:** Verify that backing occurs strictly through the STRK20 pool via shielded transfers and `privacy_invoke`, storing valid liability and zero backer address leakage.

- **Campaign 1 (Success Flow Campaign):**
  - Creator: Account A.
  - Goal: 2,000 units.
  - Deadline: `T_current + 300s`.
  - Creator secret: `S_creator`.
- **Campaign 2 (Failure Flow Campaign):**
  - Creator: Account A.
  - Goal: 10,000 units.
  - Deadline: `T_current + 300s`.
  - Creator secret: `S_creator_fail`.
- **Backing Actions:**
  - Backer B1 backs Campaign 1 with 1,000 units (receipt secret `S_b1`, identity binding `I_b1`, seq nonce `N_b1`).
  - Backer B2 backs Campaign 1 with 1,000 units (receipt secret `S_b2`, identity binding `I_b2`, seq nonce `N_b2`).
  - Backer B3 backs Campaign 2 with 1,000 units (receipt secret `S_b3`, identity binding `I_b3`, seq nonce `N_b3`).
- **Assertions:**
  - STRK20 pool withdraws tokens and calls `BackerZero.privacy_invoke(BackOperation)`.
  - Helper emits `Backed(campaign_id, amount, raised)`.
  - Helper storage for each contribution records `{ amount, refunded: false, refund_id }`.
  - Helper storage does NOT contain any backer contract address.
  - Helper returns empty span `[]` of `OpenNoteDeposit` (funds retained in escrow).
  - On-chain token balance of helper contract increases by backing amount.

---

### Gate 4: Creator Claim Validation (Success Flow)
**Objective:** Validate that upon campaign success and deadline expiration, the creator can privately claim the raised funds into a shielded open note.

- **Execution:**
  1. Wait until block timestamp exceeds Campaign 1 deadline.
  2. Campaign 1 state: `raised (2,000) >= goal (2,000)` -> `CampaignStatus::Successful`.
  3. Creator initiates `privacy_invoke(ClaimFundingOperation)` via STRK20 pool with `creator_secret = S_creator`, `amount = 2,000`, `note_id = O_creator`.
- **Assertions:**
  - Helper verifies `compute_creator_commitment(chain_id, helper, campaign_id, creator_secret) == campaign.creator_claim_commitment`.
  - Helper executes `IERC20.approve(pool, 2,000)`.
  - Helper decrements `total_escrow` by 2,000.
  - Helper sets `campaign.claimed = true`.
  - Helper returns `[OpenNoteDeposit { note_id: O_creator, token, amount: 2,000 }]`.
  - STRK20 pool creates the open note for creator.
  - Discovery service decrypts and confirms note receipt with amount 2,000.

---

### Gate 5: Identity/Context/Nonce-Bound ComputeAndInvoke Refund (Failure Flow)
**Objective:** Validate that upon campaign failure and deadline expiration, a backer can claim their refund through an identity-bound `ComputeAndInvoke` authorization, producing a shielded refund note.

- **Execution:**
  1. Wait until block timestamp exceeds Campaign 2 deadline.
  2. Campaign 2 state: `raised (1,000) < goal (10,000)` -> `CampaignStatus::Failed`.
  3. Backer B3 constructs `ComputeAndInvoke` call with `receipt_secret = S_b3`, `identity_binding = I_b3`, `context = C_b3`, `seq_nonce = N_b3`, `destination = D_b3`, `note_id = O_refund_b3`.
  4. SDK generates proof for the `ComputeAndInvoke` authorization.
  5. Transaction settles via `executeFromOutside` on the STRK20 pool.
- **Assertions:**
  - Helper computes `receipt_commitment` and verifies active unrefunded contribution exists.
  - Helper computes `refund_id` from all 10 preimage fields and verifies `refund_id == contribution.refund_id`.
  - Helper sets `contribution.refunded = true` and updates `campaign.refunded_total`.
  - Helper decrements `total_escrow` by 1,000.
  - Helper executes `IERC20.approve(pool, 1,000)`.
  - Helper returns `[OpenNoteDeposit { note_id: O_refund_b3, token, amount: 1,000 }]`.
  - STRK20 pool creates the open note for Backer B3.
  - Discovery service detects note matching `O_refund_b3` with amount 1,000.

---

### Gate 6: Adversarial, Replay, and Tampering Negatives
**Objective:** Execute exhaustive negative tests verifying that authorization proofs, preimages, and helper operations cannot be replayed, hijacked, or tampered.

- **Negative Test Scenarios:**
  | # | Test Scenario | Attack / Tamper Vector | Expected Revert / Failure |
  | :- | :--- | :--- | :--- |
  | 6.1 | **Direct Helper Invocation** | Non-pool caller calls `privacy_invoke` directly | `'CALLER_NOT_POOL'` revert |
  | 6.2 | **Double Refund** | Submit identical `ClaimRefund` for already refunded contribution | `'ALREADY_REFUNDED'` revert |
  | 6.3 | **Double Claim** | Submit identical `ClaimFunding` for already claimed campaign | `'ALREADY_CLAIMED'` revert |
  | 6.4 | **Premature Claim** | Call `ClaimFunding` before block timestamp >= deadline | `'NOT_FINISHED'` revert |
  | 6.5 | **Premature Refund** | Call `ClaimRefund` before block timestamp >= deadline | `'NOT_FINISHED'` revert |
  | 6.6 | **Claim on Failed Campaign** | Call `ClaimFunding` on campaign where raised < goal | `'GOAL_NOT_REACHED'` revert |
  | 6.7 | **Refund on Successful Campaign** | Call `ClaimRefund` on campaign where raised >= goal | `'CAMPAIGN_SUCCEEDED'` revert |
  | 6.8 | **Wrong Creator Secret** | Call `ClaimFunding` with invalid `creator_secret` | `'BAD_CREATOR_CAPABILITY'` revert |
  | 6.9 | **Tampered Refund Destination** | Tamper `destination` address in `ComputeAndInvoke` | `'REFUND_ID_MISMATCH'` / `'INVALID_PROOF_MSG'` |
  | 6.10 | **Tampered Refund Amount** | Tamper amount in `ClaimRefundOperation` | `'WRONG_REFUND_AMOUNT'` / `'INVALID_PROOF_MSG'` |
  | 6.11 | **Tampered Identity Binding** | Alter `identity_binding` or context in `ClaimRefund` | `'REFUND_ID_MISMATCH'` |
  | 6.12 | **Replay of Authorization Proof** | Resubmit identical `executeFromOutside` proof payload | `'NON_ZERO_VALUE'` (Blockifier/Pool revert) |
  | 6.13 | **Calldata Substitution** | Tamper selector or calldata inside proven invocation | `'INVALID_PROOF_MSG'` |
  | 6.14 | **Wrong Note ID Substitution** | Tamper `note_id` in `OpenNoteDeposit` args | `'INVALID_PROOF_MSG'` |

---

### Gate 7: Escrow, Solvency, and Accounting Invariants
**Objective:** Formally verify that contract solvency and escrow liabilities strictly satisfy mathematical conservation invariants at every lifecycle state.

- **Invariants Checked:**
  1. **Solvency Invariant:** `ERC20.balanceOf(helper) >= helper.total_escrow` at all times.
  2. **Total Liability Sum:** `helper.total_escrow == Sum(campaign[i].raised - campaign[i].claimed_amount - campaign[i].refunded_total)`.
  3. **Campaign Balance Bounds:** For every campaign `i`:
     - If `status == Active`: `raised == Sum(active_contributions)` and `refunded_total == 0` and `claimed == false`.
     - If `status == Claimed`: `raised >= goal` and `claimed == true` and `refunded_total == 0`.
     - If `status == Failed`: `raised < goal` and `refunded_total <= raised`.
  4. **No Underflow/Overflow:** All arithmetic in `total_escrow`, `raised`, and `refunded_total` uses checked arithmetic (`CheckedAdd`, `CheckedSub`).

---

### Gate 8: Privacy Leakage and Information Boundary Analysis
**Objective:** Audit all emitted events, public storage variables, calldata payloads, and RPC transmissions to guarantee adherence to the narrow STRK20 privacy boundary.

- **Checks:**
  - Emitted `Backed` event contains only `(campaign_id, amount, raised)`.
  - Emitted `FundingClaimed` event contains only `(campaign_id, amount)`.
  - Emitted `Refunded` event contains only `(campaign_id, amount)`.
  - Storage mapping `contributions` keys on `(campaign_id, receipt_commitment)` and stores `{ amount, refunded, refund_id }`. No `ContractAddress` of the backer is stored.
  - Public calldata of `privacy_invoke` contains the `BackOperation` / `ClaimFundingOperation` / `ClaimRefundOperation` struct. The backer's account identity is decoupled via the STRK20 pool outside-execution relayer path.
  - Transparent data (amounts, timestamps, campaign goals) are confirmed as intentional public metadata according to the product specification.

---

### Gate 9: On-Chain Receipt & Explorer Verification
**Objective:** Extract, parse, and verify full Starknet execution receipts for all transactions executed during the Sepolia validation run.

- **Receipt Verification Checklist:**
  - `finality_status`: `ACCEPTED_ON_L2`.
  - `execution_status`: `SUCCEEDED`.
  - Actual fee paid <= max fee configured.
  - Event log matches expected event ABI signature.
  - Transaction hash resolvable on Starknet Sepolia block explorers (Voyager, Starkscan).

---

### Gate 10: Evidence Accuracy & Manifest Integrity (`strk20.json`)
**Objective:** Validate that the project manifest and all supporting evidence files adhere to official hackathon submission requirements and verifiable cryptographic checksums.

- **Checks:**
  - `strk20.json` conforms to official schema:
    ```json
    {
      "transactions": [
        "0x<valid_sepolia_or_mainnet_tx_1>",
        "0x<valid_sepolia_or_mainnet_tx_2>",
        "0x<valid_sepolia_or_mainnet_tx_3>"
      ],
      "contracts": [
        "0x<valid_deployed_helper_address>"
      ],
      "demo_video": "https://<valid_url>",
      "demo_url": "https://<valid_url>"
    }
    ```
  - Zero placeholder transaction hashes (`0x123...`, `0x0...`).
  - Every transaction listed in `strk20.json` verified to exist on-chain and touch the STRK20 pool.
  - Reproducibility logs recorded in `poc/compute-and-invoke/e2e/evidence/` with matching sha256 checksums in `scripts/privacy-artifacts.sha256`.

---

### Gate 11: Documentation, Git Hygiene, & PR Packaging
**Objective:** Confirm repository cleanliness, updated state documentation, clean git history, and complete PR description reflecting net diffs.

- **Checklist:**
  - `docs/PROJECT_STATE.md` updated with Prompt 5B results, transaction hashes, and deployment addresses.
  - `docs/TECHNICAL_VERIFICATION.md` updated with lifecycle execution data.
  - Pre-commit secret scan: `git diff --cached | grep -iE "api_key|secret|password|private_key"` yields 0 matches.
  - Git history uses `git mv` for refactoring, commit messages follow standard convention, and PR body focuses on net diff vs `main`.

---

## 4. Integration Failure Modes & Mitigation Matrix

The following table details high-probability integration risks identified during Prompt 5A inspection and their exact mitigations:

| # | Failure Mode | Root Cause | Impact | Detection / Indicator | Prevention & Mitigation |
| :- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Prover SIGILL Crash (AMD64)** | Prover binary contains AMD-only SSE4a instructions (`EXTRQ`/`INSERTQ`) | Prover crashes with exit code 132 on Intel host | `dmesg` or docker exit code 132 | Use ARM64 image with qemu or source-built binary with generic x86-64 target. |
| 2 | **Storage Proof RPC Mismatch** | Node does not support `starknet_getStorageProof` or rejects large headers | Proof generation fails | `Method not found: starknet_getStorageProof` | Run `scripts/rpc-capability-proxy.py` routing headers to PublicNode and proofs to Cartridge/ZAN. |
| 3 | **Helper Pre-funding Invariant Revert** | Helper checks `balance >= total_escrow` in `back()`; fails if pool hasn't transferred tokens | `privacy_invoke` reverts with `'NOT_FUNDED'` | On-chain revert with error `'NOT_FUNDED'` | Verify STRK20 pool transfer happens before helper callback in the execute flow. |
| 4 | **Pool Approval Mismatch on Payout** | Helper must approve pool to pull ERC20 for `OpenNoteDeposit` | Pool cannot pull tokens; transaction reverts | `'APPROVE_FAILED'` or ERC20 allowance revert | Helper explicitly calls `IERC20.approve(pool, amount)` before returning `OpenNoteDeposit`. |
| 5 | **Timestamp Expiration Deadlock** | Sepolia block timestamp has not reached campaign deadline | `claim_funding` or `claim_refund` reverts | `'NOT_FINISHED'` revert | Set short test deadlines (e.g., `+180s` to `+300s`) and poll block timestamp via RPC before invoking. |
| 6 | **Poseidon Hash Preimage Mismatch** | Parameter ordering, types, or domain separation differ between Cairo and TS | `refund_id` or `creator_commitment` mismatch | `'REFUND_ID_MISMATCH'` or `'BAD_CREATOR_CAPABILITY'` | Verified by shared fixtures (`fixtures.cairo` vs `fixtures.ts`). Use exact helper functions from `@backerzero/strk20-actions`. |
| 7 | **Prover Block Hash Lag Exceeded** | Proving against a block outside blockifier `STORED_BLOCK_HASH_BUFFER` | Prover generates proof, but settlement reverts on-chain | Revert during `executeFromOutside` | Use `latest - 11` block for proving as configured in `BZ_PROVING_BLOCK_LAG`. |
| 8 | **Testnet STRK Depletion** | Deployer or test accounts run out of fee tokens | Transactions cannot be broadcast | `Insufficient max fee` or `insufficient balance` | Pre-flight balance checks on all test accounts before starting the run. |

---

## 5. Command-by-Command Verification Playbook

### Step 1: Pre-Flight Environment & Tooling Verification
```bash
# Verify Cairo & Scarb toolchain
export PATH="/home/opadmin/agent-stack/volumes/agent-zero-v210/usr/projects/backerzero-strk20/poc/compute-and-invoke/.tools/scarb-v2.18.0-x86_64-unknown-linux-gnu/bin:/home/opadmin/agent-stack/volumes/agent-zero-v210/usr/projects/backerzero-strk20/poc/compute-and-invoke/.tools/starknet-foundry-v0.63.0-x86_64-unknown-linux-gnu/bin:$PATH"
scarb --version
snforge --version

# Verify Node & NPM
node --version
npm --version

# Run local test baselines
cd contracts && scarb build && snforge test
cd ../packages/strk20-actions && npm install && npm test
```

### Step 2: RPC & Prover Capability Validation
```bash
# Verify RPC endpoints for storage proof capability
python3 scripts/rpc-capability-proxy.py --help

# Test RPC capability proxy connectivity
curl -s -X POST "https://starknet-sepolia-rpc.publicnode.com" \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"starknet_specVersion"}'

# Verify prover container readiness
docker run --rm ghcr.io/starkware-libs/starknet-privacy/transaction-prover@sha256:9882d27692b420a9edae9b50bf8075103044230de0f83ee6bed3db19cace105f --version || true
```

### Step 3: Sepolia Lifecycle Rehearsal Execution (Pending Human Approval)
```bash
# Set environment variables for the rehearsal run
export BZ_RPC_URL="https://starknet-sepolia-rpc.publicnode.com"
export BZ_TX_RPC_URL="https://api.cartridge.gg/x/starknet/sepolia"
export BZ_PROVER_PLATFORM="arm64"
export BZ_ACCOUNTS_FILE="$HOME/.bz-sepolia/accounts.json"

# Execute lifecycle test script
bash scripts/run-privacy-real-proof.sh
```

---

## 6. Evaluator Blockers & Readiness Checklist

Before moving from Planning to Execution Phase, the following items must be satisfied:

- [x] **Cairo protocol & tests verified:** 28/28 `snforge` tests pass in repo.
- [x] **TypeScript action layer verified:** 16/16 `vitest` tests pass in repo.
- [x] **Poseidon domain separation verified:** Hash formulas in Cairo and TS match golden fixtures.
- [x] **ADR-002 confirmed:** Identity-bound `ComputeAndInvoke` verified on devnet & approved.
- [ ] **Blocker 1 (Human Approval):** Explicit human authorization to broadcast Sepolia transactions and spend testnet funds.
- [ ] **Blocker 2 (Sepolia Accounts File):** `$HOME/.bz-sepolia/accounts.json` populated with funded testnet accounts.
- [ ] **Blocker 3 (Universal Sierra Compiler):** Local `snforge test` toolpath environment needs compiler binary configured or CI runner fallback.
- [ ] **Blocker 4 (NPM Dependencies):** `packages/strk20-actions/node_modules` needs installation in fresh checkouts.

---
*Plan created by Independent Evaluator for BackerZero Prompt 5B.*
