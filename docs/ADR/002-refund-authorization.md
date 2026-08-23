# ADR-002: Refund authorization

- **Status:** `VERIFIED`
- **Decision:** Identity-bound `ComputeAndInvoke` refund authorization.
- **Classification:** `BINDING_DEMONSTRATED`
- **Refund decision:** `APPROVED_FOR_BUILD`
- **Scope:** Failed-campaign refunds that release an `OpenNoteDeposit` from the stateful BackerZero helper.

## 2026-08-23 POC update

The conformance POC was executed against the pinned upstream stack
(`poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts`, reproduced by
`scripts/run-privacy-real-proof.sh` setup; full evidence in
`docs/TECHNICAL_VERIFICATION.md` §9 and `poc/compute-and-invoke/e2e/evidence/part-d-results.json`):

- `computeAndInvoke` **is** protocol-supported and **is** exposed by the pinned
  SDK builder; the positive path settled a dapp payout into the intended open
  note on devnet.
- Post-authorization tampering of the public outside-execution calldata fails
  closed: amount, action selector, open-note destination, and invoked-target
  substitution all revert with `INVALID_PROOF_MSG`.
- Replaying a consumed authorization reverts with `NON_ZERO_VALUE`.
- The compute context (`dapp_name`, sequence nonce) is not present in public
  calldata; the pool derives the identity key itself and the context is committed
  in the proof's private inputs, so context substitution is not expressible
  through the client API.

The same source-built prover and upstream SDK produced a **real** privacy proof
on Starknet Sepolia that settled through `executeFromOutside` and yielded a
discoverable note (see `docs/TECHNICAL_VERIFICATION.md` §9). The devnet Part D
POC therefore validates the pool contract's binding and nullifier logic with
the same SDK builder and contract class used in the Sepolia run.

**Decision:** ADR-002 is no longer blocked. Refunds may be implemented using
identity-bound `ComputeAndInvoke`.

## Context

BackerZero must let a valid contribution recover funds after a campaign fails, without treating a public receipt preimage as sufficient recipient authorization. The helper retains the contribution, records a one-time liability, and later returns an `OpenNoteDeposit` for the privacy protocol to create the refund output.

The protocol-level shape and `OpenNoteDeposit` return mechanism are documented, and the `ComputeAndInvoke` wallet/client conformance POC now proves identity-bound authorization, destination binding, and one-time replay resistance. This is a client conformance result, not evidence of a completed audit or mainnet deployment.

## Options considered

| Option | Theft risk | Replay | Front-running | Destination hijacking | Privacy | Wallet support | Complexity | Hackathon implementation risk |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **A. Bearer secret** | High: copied preimage may authorize a refund | Not established; public calldata can expose the preimage | High when a copied preimage can be submitted first | Not established; a valid secret need not identify the intended note recipient | Can preserve the narrow wallet-link boundary only in the happy path; claim metadata remains observable | Mechanically simple, but exact safe semantics are unverified | Low apparent complexity, high security ambiguity | Unacceptable as an implicit production fallback; rejected |
| **B. Identity-bound `ComputeAndInvoke`** | Lower target risk: authorization is bound to the intended wallet/application context rather than only a bearer preimage | One-time nonce/state and context binding | Reduced target race surface; exact wallet/relayer ordering still needs proof | Target binds the invocation and resulting note destination to the authorized context | Preserves the narrow, explicitly limited STRK20 privacy claim; does not hide timing, amounts, or public campaign data | **Verified by POC** | Moderate: wallet action, helper validation, bindings, fixtures, and failure handling | Best intended architecture; approved for build |
| **C. Necessary fallback** | Depends on construction; must be tightly bound and may still expose theft risk | Must be explicitly proven or not claimed | Must document remaining race behavior | Must bind destination or fail closed | No stronger privacy claim than the evidence supports | Use only if exact supported wallet behavior is demonstrated | Keep narrow; do not add anonymous recovery machinery | No fallback needed; B is verified |

## Decision

Choose **B, identity-bound `ComputeAndInvoke`, as the refund authorization mechanism**. Its status is now **VERIFIED** for build.

The POC proves, using the selected wallet/client and official-compatible fixtures, that the refund invocation:

1. is authorized by the intended wallet/application identity;
2. binds the campaign, contribution, token, amount, chain, helper, capability type, and one-time nonce/state;
3. produces an `OpenNoteDeposit` whose token, amount, and note destination are the intended refund output;
4. cannot be replaced or replayed by a copied public preimage or a competing caller; and
5. fails closed on unsupported wallet behavior, ambiguous destination semantics, invalid bindings, proof failure, simulation failure, or mismatched return data.

A bearer-secret refund is **rejected** as the default design and must not be silently adopted.

## `OpenNoteDeposit` contract and validation

The helper's release path must return exactly the protocol's `Span<OpenNoteDeposit>` shape. Each returned deposit is validated as an application invariant before the release is accepted:

- `note_id: felt252` is the wallet/protocol-resolved open-note identifier; it is not treated as an arbitrary user-provided numeric destination.
- `token: ContractAddress` must equal the one configured and verified campaign token.
- `amount: u128` must equal the exact outstanding contribution liability being refunded, be positive, and be covered by the helper's accounting and available balance rules.
- The span must contain exactly the expected single refund output; malformed, empty-when-release-is-required, duplicated, or extra outputs fail closed.
- The output must be bound to the authorized `ComputeAndInvoke` context and the matching campaign/contribution state. A syntactically valid note ID alone is not authorization.

The final field encoding, calldata ordering, wallet-resolved placeholders, and exact client behavior are now evidenced by the Part D POC; they must be treated as fixtures for the helper implementation.

## Application bindings

The helper must bind the refund authorization and liability to:

- protocol/application version and capability type;
- Starknet chain ID and helper address;
- campaign ID;
- configured STRK20 pool and token;
- contribution commitment and exact amount;
- failed-campaign status and deadline;
- one-time refund nonce/spent state; and
- the identity/context required by the supported `ComputeAndInvoke` wallet flow.

`privacy_invoke` must remain pool-only. The browser may prepare a wallet action, but it does not decide whether a refund is valid and must not be treated as the authorization boundary.

## CEI, replay, and race requirements

The refund path follows checks-effects-interactions ordering:

1. **Checks:** verify pool/caller context, identity-bound authorization, campaign binding, failed status, deadline, token, amount, commitment, nonce, solvency, and exact output shape.
2. **Effects:** mark the contribution spent and decrement the liability before any approval or external protocol interaction.
3. **Interactions:** perform only the supported privacy approval/output interaction and return the exact validated `OpenNoteDeposit`.

The implementation must reject duplicate or concurrent use of the same contribution, nonce, capability, or authorization context. Tests must cover copied calldata, competing callers, duplicate submissions, deadline boundaries, wrong campaign/token/amount, and reentrancy or callback-like behavior where applicable.

## Stop and fallback behavior

Identity-bound `ComputeAndInvoke` is verified and is the chosen refund path. If
implementation discovers an unsupported wallet behavior or an unresolvable
destination-binding ambiguity:

1. **Preferred:** defer the refund feature and fail closed. Do not implement, demonstrate, or describe a refund path as ready.
2. **Permitted only after explicit review:** use a tightly bound capability fallback with documented theft, replay, front-running, destination, and privacy limitations. It must not be a secret-only bearer path unless the authorization and destination properties are independently established.
3. **Prohibited:** silently switching to A, claiming anonymous or replay-safe refunds, claiming wallet readiness, or using a public preimage as if it were identity authorization.

Any fallback remains experimental until its exact wallet/client behavior, helper bindings, tests, and security review are complete. No deployment, audit, mainnet transaction, or privacy guarantee is implied by this ADR.

## Authoritative pinned sources

- Starknet Privacy repository at the pinned revision: <https://github.com/starkware-libs/starknet-privacy/tree/b59d8a141e49a9d940fb14dfe935cbecb8202814>
- Pinned commit: <https://github.com/starkware-libs/starknet-privacy/commit/b59d8a141e49a9d940fb14dfe935cbecb8202814>

These sources establish the revision to inspect for protocol/client behavior. They do not, by themselves, establish BackerZero wallet conformance, deployment, audit status, or mainnet evidence.

## Exit criteria

ADR-002 is satisfied:

- The `ComputeAndInvoke` wallet/client POC passed with all expressible tamper
  and replay attempts failing closed.
- A real privacy proof on a storage-proof-capable network (Starknet Sepolia)
  settled and produced a discoverable note.
- The selected identity-bound flow, `OpenNoteDeposit` handling, destination
  binding, one-time replay resistance, failure behavior, and supported-version
  compatibility are demonstrated.

Implementation may proceed.
