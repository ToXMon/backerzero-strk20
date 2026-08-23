# BackerZero Open Questions

Only questions that genuinely require verification before architecture or implementation are listed here.

1. **Protocol constants:** Is the target chain `SN_MAIN`, and is the documented STRK20 mainnet pool address still current?
2. **Wallet API compatibility:** What are the current supported versions and exact APIs for `starknet.js`, `strk20Balances`, `strk20PrepareInvoke`, and `strk20InvokeTransaction`? Do the current starter-kit action shapes remain valid?
3. **Token selection:** Which one ERC-20 reliably works through the verified mainnet pool, wallet, proving, simulation, and open-note flows: USDC or STRK? What are its exact address and decimals?
4. **Helper ABI:** What exact Cairo interface, calldata ordering, `OpenNoteDeposit` serialization, empty-span encoding, and pool authorization behavior does the live STRK20 pool require?
5. **Open-note semantics:** How must literal `OPEN` and wallet-resolved open-note IDs be represented, and how is the output bound to the intended shielded recipient?
6. **~~Real-proof environment~~** — **RESOLVED**: a storage-proof-capable hosted Sepolia path (`scripts/rpc-capability-proxy.py` routing `starknet_getStorageProof` to ZAN and block headers/broadcast to PublicNode), a local source-built prover, and a disposable funded Sepolia pool produced a real proof and settlement. See `docs/TECHNICAL_VERIFICATION.md` §9.
7. **~~Refund authorization~~** — **RESOLVED**: identity-bound `ComputeAndInvoke` is demonstrated; the bearer-secret path is rejected. See `docs/ADR/002-refund-authorization.md`.
8. **Creator authorization:** Is the creator claim secret alone sufficient, or is an additional creator-wallet authorization required? What recovery behavior is acceptable if the secret is lost?
9. **Poseidon parity:** What exact domain separator, field order, felt encoding, chain-ID encoding, campaign-ID encoding, and Cairo/TypeScript implementation must be shared in a fixed fixture?
10. **Campaign metadata:** Can the required metadata fit safely on-chain, or should the MVP use a content URI? Verify size, gas, mutability, and availability constraints.
11. **Deadline boundary:** What should happen exactly at `block_timestamp == deadline`, and what minimum deadline is practical for the live demo environment?
12. **Mainnet operations:** What human-approval procedure, funded account, fee reserve, deployment profile, RPC/relayer configuration, and read-only verification commands will be used? No credentials belong in the repository.
13. **Submission rules:** Re-verify the live deadline, qualifying transaction definition, `strk20.json` schema, repository/license rules, demo URL, and video requirements before release.
