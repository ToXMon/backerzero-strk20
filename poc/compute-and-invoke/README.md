# ComputeAndInvoke isolated POC

This directory is an isolated, local-only baseline for the pinned Starknet privacy source at commit `b59d8a141e49a9d940fb14dfe935cbecb8202814`.

## Pinned references

- Cairo/Scarb reference: `starknet = 2.17.0`, `snforge_std = 0.63.0`, Cairo edition `2024_07` (from the pinned repository manifest).
- Privacy SDK reference: `@starkware-libs/starknet-privacy-sdk` `0.14.3-rc.5`.
- Privacy client reference: `@starkware-libs/starknet-privacy-client` `0.1.0`.
- SDK Starknet client dependency: `starknet` `10.5.0`.

## Scope

The Cairo helper is intentionally non-private. The TypeScript client only provides a local/devnet provider-account harness and helper read/invoke functions. It does not implement refunds, bearer-secret fallback, ComputeAndInvoke settlement, UI, campaigns, mainnet deployment, or real-fund operations.

## Local-only execution

Use a deterministic local devnet and a local-only account. Never place private keys in source, package files, logs, or committed documentation.

```bash
# In one shell with the acquired toolchain explicitly prefixed:
scarb build
snforge test
npm install
npm run build
RPC_URL=http://127.0.0.1:5050/rpc \
  CONTRACT_ADDRESS=0x... \
  ACCOUNT_ADDRESS=0x... \
  ACCOUNT_PRIVATE_KEY=0x... \
  npm run client
```

The client refuses to run unless all runtime values are supplied through environment variables. It does not contain a fallback secret or a default signer.

## ComputeAndInvoke status

The pinned SDK source defines the builder and `ComputeAndInvokeDetails` encoding contract. SDK unit tests use a mock environment. A real privacy proof/prover, simulation, submission, and settlement are required before claiming an end-to-end ComputeAndInvoke result; this isolated POC does not claim those properties.

The executable conformance and negative tests live in [`e2e/`](e2e/README.md): they run the real
`computeAndInvoke` action shape against the pinned upstream devnet harness and record which tampering
and replay attempts fail closed. They still run with the upstream mock proof provider, because a real
proof is not obtainable on `starknet-devnet` — see `docs/TECHNICAL_VERIFICATION.md` §9.

A hosted Sepolia real-proof attempt is also in `e2e/bz-sepolia-*.ts`. It reaches the prover, but the
official prover image cannot complete a real proof in the current VM (amd64 SIGILL on Intel, arm64
`qemu-user` too slow for the public storage-proof window). See `docs/TECHNICAL_VERIFICATION.md` §10.
