# Prompt 4 Part C — Sepolia real-proof lifecycle test plan

**Scope:** Run the reproduction script `scripts/run-privacy-real-proof.sh` with `BZ_POOL_ADDRESS` pinned to the live Sepolia privacy pool, using the official `ghcr.io/starkware-libs/starknet-privacy/transaction-prover:PRIVACY-0.14.3-RC.2` image (default arm64 manifest) and the RPC capability proxy. Verify whether the full real-privacy lifecycle reaches `starknet_proveTransaction`, returns a proof, settles on Sepolia, and produces a discoverable note.

**What success looks like:**
- Prover container starts and responds to `starknet_specVersion`.
- `starknet_proveTransaction` completes and returns non-empty proof data.
- `executeFromOutside` is accepted on Sepolia and the receipt succeeds.
- Note discovery returns at least one note and writes `evidence/sepolia-real-proof.json` with `discoveredNotes > 0`.

**What failure modes we must classify:**
- `SIGILL`/`exit 132` from the prover (amd64-only SSE4a instructions on an Intel VM).
- Storage-proof timeout/window error (`starknet_getStorageProof` fails because the proving block is outside the RPC retention window).
- Any other exact error, exit code, or vitest failure.

This is a shell-only, no-UI execution. No screen recording is required. No private keys, seed phrases, or account files are committed or logged.

## Test case 1 — RPC capability probe (pre-flight)

**Command:**
```bash
bash scripts/probe-storage-proof-rpc.sh > /home/ubuntu/rpc-probe-fresh.log 2>&1
```

**Relevant code:** `scripts/probe-storage-proof-rpc.sh` (default endpoints lines 13-18; `starknet_getStorageProof` probe lines 32-34).

**Pass criteria:**
- `https://starknet-sepolia-rpc.publicnode.com` returns `specVersion` `0.10.2`, `chainId` `SN_SEPOLIA`, and `starknet_getStorageProof` returns a result with `global_roots`.
- `https://api.cartridge.gg/x/starknet/sepolia` returns `specVersion` `0.9.0`, `chainId` `SN_SEPOLIA`, and `starknet_getStorageProof` returns a result with `global_roots`.
- At least one storage-proof-capable endpoint is reachable; the capability proxy can route `starknet_getStorageProof` to it and everything else to PublicNode.

**Fail criteria:**
- All endpoints return `Method not found` or error for `starknet_getStorageProof`.
- Every endpoint is unreachable.

## Test case 2 — Reproduction script reaches the prover and real-proof stage

**Command:**
```bash
BZ_POOL_ADDRESS=0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce \
  bash scripts/run-privacy-real-proof.sh > /home/ubuntu/bz-realproof-run-fresh.log 2>&1
```

A parallel prover log tail will be started as soon as the `bz-prover` container exists:
```bash
while ! docker inspect -f '{{.State.Running}}' bz-prover >/dev/null 2>&1; do sleep 1; done
docker logs -f bz-prover > /home/ubuntu/bz-prover-run-fresh.log 2>&1
```

**Relevant code:**
- Proxy start: `scripts/run-privacy-real-proof.sh` lines 56-60; `scripts/rpc-capability-proxy.py` lines 42-86.
- Prover pull/start: `scripts/run-privacy-real-proof.sh` lines 64-73.
- Prover readiness check: `scripts/run-privacy-real-proof.sh` lines 75-85.
- Sepolia test copy/run: `scripts/run-privacy-real-proof.sh` lines 87-108.
- Test entry: `poc/compute-and-invoke/e2e/bz-sepolia-real-proof.test.ts` lines 25-95.

**Pass criteria:**
- Script outputs `starting RPC capability proxy` and `Part C — real-prover privacy lifecycle on Sepolia`.
- `docker ps` or `docker inspect` shows `bz-prover` exists and is healthy long enough to log `JSON-RPC proving server is running`.
- `curl -s -X POST http://127.0.0.1:3000 ... starknet_specVersion` returns a version (e.g. `0.10.3-rc.2`).
- `docker logs bz-prover` shows a `prove_transaction` start with a real Sepolia `tx_hash` and `block_id`.

**Fail criteria:**
- Script fails before vitest starts (non-zero exit or missing `Part C` output).
- Prover exits before readiness with exit code `132` (SIGILL).
- Prover never receives `prove_transaction`.

## Test case 3 — `starknet_proveTransaction` returns a proof

**Relevant code:**
- Test builds and executes deposit with proving block: `bz-sepolia-real-proof.test.ts` lines 47-60.
- `RealProofScreeningProvider.prove` wraps the prover call: `bz-sepolia-harness.ts` lines 127-152.
- `ProvingServiceProofProvider` POSTs `starknet_proveTransaction` to the local prover: `node_modules/@starkware-libs/starknet-privacy-sdk` (used by harness).
- Proof assertions: `bz-sepolia-real-proof.test.ts` lines 71-73, 78.

**Pass criteria:**
- Prover container stays alive through `prove_transaction` and logs a successful proof result (no `UpstreamRpcError` or `RunnerError`).
- Vitest receives `callAndProof.proof.data` with `length > 0` and `proofFacts.length > 0`.

**Fail criteria / classification:**
- Prover container exits with code `132` during `prove_transaction` → **SIGILL (amd64)**.
- Prover logs show `starknet_getStorageProof` failing for the proving block, or a `Block not found` / `proof not available` / `UpstreamRpcError` mentioning storage proofs → **storage-proof timeout/window**.
- Any other `RunnerError`, `ProvingServiceError`, or container exit with a different code → capture exact error and exit code.

## Test case 4 — `executeFromOutside` settles on Sepolia and produces a discoverable note

**Relevant code:**
- `executeFromOutside` is called at `bz-sepolia-real-proof.test.ts` line 62.
- Implementation: `bz-sepolia-harness.ts` lines 306-331.
- Success assertions: `bz-sepolia-real-proof.test.ts` lines 79, 82-93.
- Evidence file path: `scripts/run-privacy-real-proof.sh` line 54.

**Pass criteria:**
- `receipt.isSuccess()` is `true` and `evidence.settlementTx` is a real Sepolia transaction hash.
- The indexer/discovery service returns `notes.notes.size > 0`.
- `poc/compute-and-invoke/e2e/evidence/sepolia-real-proof.json` is written with `discoveredNotes > 0`.

**Fail criteria:**
- `executeFromOutside` reverts (capture `revert_reason`).
- Settlement tx is never accepted or fails on-chain.
- Note discovery times out after 10 minutes with `discoveredNotes == 0`.

## Test case 5 — Do not run Part D unless Part C succeeds

**Rule:** If test case 3 fails, stop. Do not run `poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts` (Part D). Part D evidence already exists from devnet runs and is out of scope for this Sepolia real-proof reproduction.

## Evidence to collect

- `/home/ubuntu/rpc-probe-fresh.log`
- `/home/ubuntu/bz-realproof-run-fresh.log`
- `/home/ubuntu/bz-prover-run-fresh.log`
- `poc/compute-and-invoke/e2e/evidence/sepolia-real-proof.json` (if generated)
- `docker inspect bz-prover --format '{{.State.ExitCode}}'` after the run
