---
name: Prompt 4 Sepolia real-proof reproduction
description: How to run the `scripts/run-privacy-real-proof.sh` reproduction for the PRIVACY-0.14.3-RC.2 prover on Sepolia, common failure modes, and required pre-flight checks.
---

# Prompt 4 Sepolia real-proof reproduction

## Goal
Run the smallest real-privacy lifecycle on Sepolia with the official `ghcr.io/starkware-libs/starknet-privacy/transaction-prover` image and classify why it fails (SIGILL on amd64, storage-proof window on arm64/qemu, or other).

## Devin Secrets Needed
None. The run needs a funded disposable-accounts file at `~/.bz-sepolia/accounts.json` (never commit this file or its contents). No API keys are required for the default PublicNode/Cartridge RPC endpoints.

## Preconditions
- Docker is installed and the host is x86_64.
- `qemu-user-static` is installed so Docker can run `linux/arm64` images.
- The pinned upstream checkout exists at `/home/ubuntu/starknet-privacy` (commit `b59d8a141e49a9d940fb14dfe935cbecb8202814`) and its `e2e/` dependencies are installed.
- `~/.bz-sepolia/accounts.json` contains `bzsepolia` and `bzalice` entries with enough Sepolia STRK for approve + deposit + fees.
- Port `8547` is free. The reproduction script starts `scripts/rpc-capability-proxy.py` on that port and it will **silently fail to start** if the port is already in use, causing a downstream `Failed to read from state: error sending request for url (http://127.0.0.1:8547/)` prover failure. Always run `pgrep -f 'rpc-capability-proxy.py' | xargs -r kill` and verify `127.0.0.1:8547` is free first.

## Run
```bash
export BZ_POOL_ADDRESS=0x02967c66092142d39c6918d632694054224d1419fa65f591fb049b464ee856ce
bash scripts/run-privacy-real-proof.sh 2>&1 | tee /tmp/bz-realproof-run.log
```

The script:
1. Starts the RPC capability proxy (`scripts/rpc-capability-proxy.py`).
2. Pulls and runs the `linux/arm64` prover image by default (digest `sha256:9882d27692b420a9edae9b50bf8075103044230de0f83ee6bed3db19cace105f`).
3. Waits for `starknet_specVersion` on `http://127.0.0.1:3000`.
4. Copies `poc/compute-and-invoke/e2e/bz-sepolia-*.ts` into the upstream checkout.
5. Runs `npx vitest run tests/integration/bz-sepolia-real-proof.test.ts`.

## Capture prover logs
The script removes the `bz-prover` container on exit, so tail its logs while the run is in progress:
```bash
while ! docker ps --format '{{.Names}}' | grep -qx 'bz-prover'; do sleep 1; done
docker logs -f bz-prover > /tmp/bz-prover-run.log 2>&1
```

## Expected outcomes
- `starknet_specVersion` should return `0.10.3-rc.2`.
- Prover logs should show `Starting transaction proving` with a Sepolia `tx_hash` and `block_id`.
- The most common observed failure on this VM is **not SIGILL** when using the arm64 image, but a storage-proof window error:
  ```text
  prove_transaction failed: RunnerError(ProofProvider(UpstreamRpcError { code: 42,
    message: "The node doesn't support storage proofs for blocks that are too far in the past" }))
  ```
  This means the emulated prover took longer than the ~16-block storage-proof retention of the public RPC.
- If you force the `linux/amd64` image (`PROVER_PLATFORM=amd64`), the prover will crash with **SIGILL (exit code 132)** because the binary contains AMD-only SSE4a (`EXTRQ`/`INSERTQ`) instructions.

## RPC capability probe
Run `scripts/probe-storage-proof-rpc.sh` first to confirm endpoint capabilities. PublicNode has full v0.10 headers but only `latest` storage proofs; Cartridge/Alchemy have the ~16-block storage-proof window but older block headers, so the capability proxy splits calls between them.

## Cleanup
After the run, confirm no `rpc-capability-proxy.py` process or `bz-prover` container remains, and verify port `8547` is free.
