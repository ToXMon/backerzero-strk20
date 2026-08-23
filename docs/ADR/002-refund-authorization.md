# ADR-002: Refund authorization

- **Status:** `BLOCKED / PENDING REAL-PROOF EVIDENCE` (was `PENDING EXACT-WALLET-CONFORMANCE-POC`)
- **Decision:** Target identity-bound `ComputeAndInvoke` refund authorization.
- **Classification:** `BINDING_DEMONSTRATED_ON_DEVNET_PROOF_SOUNDNESS_UNVERIFIED`
- **Refund decision:** `DEFER_FAIL_CLOSED`
- **Scope:** Failed-campaign refunds that release an `OpenNoteDeposit` from the stateful BackerZero helper.

## 2026-08-23 POC update

The conformance POC was executed against the pinned upstream stack
(`poc/compute-and-invoke/e2e/bz-compute-invoke.test.ts`, reproduced by
`scripts/run-privacy-real-proof.sh`; full evidence in
`docs/TECHNICAL_VERIFICATION.md` §9):

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

**Why this does not unblock the ADR:** all of the above ran with the upstream
devnet mock proof provider, because a real proof cannot be produced against
`starknet-devnet` (it does not implement `starknet_getStorageProof`). The
evidence therefore covers the pool contract's binding and nullifier logic, not
proof soundness, and no BackerZero refund path was exercised. Refunds remain
`DEFER_FAIL_CLOSED` until the same tests pass with a real proof on a
storage-proof-capable network.

## Context

BackerZero must let a valid contribution recover funds after a campaign fails, without treating a public receipt preimage as sufficient recipient authorization. The helper retains the contribution, records a one-time liability, and later returns an `OpenNoteDeposit` for the privacy protocol to create the refund output.

The protocol-level shape and `OpenNoteDeposit` return mechanism are documented, but exact wallet/client support for identity-bound `ComputeAndInvoke`, including destination handling and calldata/conformance details, has not been proven. This is a client conformance question, not evidence of wallet readiness, deployment, or a completed audit.

## Options considered

| Option | Theft risk | Replay | Front-running | Destination hijacking | Privacy | Wallet support | Complexity | Hackathon implementation risk |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **A. Bearer secret** | High: copied preimage may authorize a refund | Not established; public calldata can expose the preimage | High when a copied preimage can be submitted first | Not established; a valid secret need not identify the intended note recipient | Can preserve the narrow wallet-link boundary only in the happy path; claim metadata remains observable | Mechanically simple, but exact safe semantics are unverified | Low apparent complexity, high security ambiguity | Unacceptable as an implicit production fallback; demo-only experimentation would need explicit limitation and tiny values |
| **B. Identity-bound `ComputeAndInvoke`** | Lower target risk: authorization is bound to the intended wallet/application context rather than only a bearer preimage | Target requires one-time nonce/state and context binding | Reduced target race surface; exact wallet/relayer ordering still needs proof | Target binds the invocation and resulting note destination to the authorized context | Preserves the narrow, explicitly limited STRK20 privacy claim; does not hide timing, amounts, or public campaign data | **Unverified exact-wallet conformance**; POC is mandatory | Moderate: wallet action, helper validation, bindings, fixtures, and failure handling | Best intended architecture, but blocked until the POC passes |
| **C. Necessary fallback** | Depends on construction; must be tightly bound and may still expose theft risk | Must be explicitly proven or not claimed | Must document remaining race behavior | Must bind destination or fail closed | No stronger privacy claim than the evidence supports | Use only if exact supported wallet behavior is demonstrated | Keep narrow; do not add anonymous recovery machinery | Defer/fail closed is safest; a capability fallback is allowed only with explicit limits and review |

## Decision

Choose **B, identity-bound `ComputeAndInvoke`, as the intended target architecture**. Its current status is **BLOCKED/PENDING EXACT-WALLET-CONFORMANCE-POC** and classified **PROTOCOL_SUPPORTED_BUT_CLIENT_UNVERIFIED**.

The POC must prove, using the selected wallet/client and official-compatible fixtures, that the refund invocation:

1. is authorized by the intended wallet/application identity;
2. binds the campaign, contribution, token, amount, chain, helper, capability type, and one-time nonce/state;
3. produces an `OpenNoteDeposit` whose token, amount, and note destination are the intended refund output;
4. cannot be replaced or replayed by a copied public preimage or a competing caller; and
5. fails closed on unsupported wallet behavior, ambiguous destination semantics, invalid bindings, proof failure, simulation failure, or mismatched return data.

A bearer-secret refund is **rejected** as the default design and must not be silently adopted if the POC fails.

## `OpenNoteDeposit` contract and validation

The helper's release path must return exactly the protocol's `Span<OpenNoteDeposit>` shape. Each returned deposit is validated as an application invariant before the release is accepted:

- `note_id: felt252` is the wallet/protocol-resolved open-note identifier; it is not treated as an arbitrary user-provided numeric destination.
- `token: ContractAddress` must equal the one configured and verified campaign token.
- `amount: u128` must equal the exact outstanding contribution liability being refunded, be positive, and be covered by the helper's accounting and available balance rules.
- The span must contain exactly the expected single refund output; malformed, empty-when-release-is-required, duplicated, or extra outputs fail closed.
- The output must be bound to the authorized `ComputeAndInvoke` context and the matching campaign/contribution state. A syntactically valid note ID alone is not authorization.

The final field encoding, calldata ordering, wallet-resolved placeholders, and exact client behavior remain POC evidence requirements, not verified constants.

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

If the exact-wallet conformance POC fails, is incomplete, or cannot establish destination binding:

1. **Preferred:** defer the refund feature and fail closed. Do not implement, demonstrate, or describe a refund path as ready.
2. **Permitted only after explicit review:** use a tightly bound capability fallback with documented theft, replay, front-running, destination, and privacy limitations. It must not be a secret-only bearer path unless the authorization and destination properties are independently established.
3. **Prohibited:** silently switching to A, claiming anonymous or replay-safe refunds, claiming wallet readiness, or using a public preimage as if it were identity authorization.

Any fallback remains experimental until its exact wallet/client behavior, helper bindings, tests, and security review are complete. No deployment, audit, mainnet transaction, or privacy guarantee is implied by this ADR.

## Authoritative pinned sources

- Starknet Privacy repository at the pinned revision: <https://github.com/starkware-libs/starknet-privacy/tree/b59d8a141e49a9d940fb14dfe935cbecb8202814>
- Pinned commit: <https://github.com/starkware-libs/starknet-privacy/commit/b59d8a141e49a9d940fb14dfe935cbecb8202814>

These sources establish the revision to inspect for protocol/client behavior. They do not, by themselves, establish BackerZero wallet conformance, deployment, audit status, or mainnet evidence.

## Exit criteria

ADR-002 is no longer blocked only when the tests above are re-run with a **real** proof on a storage-proof-capable network and the selected wallet/client POC and reviewed fixtures demonstrate the identity-bound flow, exact `OpenNoteDeposit` handling, destination binding, one-time replay resistance, failure behavior, and supported-version compatibility. Until then, implementation remains gated.
