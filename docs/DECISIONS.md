# Decisions

- 2026-08-17: Use the MIT license unless a later project requirement gives a strong reason to change it.
- 2026-08-17: Keep this initial scaffold dependency-free and avoid implementation or architecture decisions before the specification.

## ADR-002 — Refund authorization

- **Status:** `BLOCKED / PENDING EXACT-WALLET-CONFORMANCE-POC`.
- **Decision:** The intended refund architecture is identity-bound `ComputeAndInvoke`, classified `PROTOCOL_SUPPORTED_BUT_CLIENT_UNVERIFIED`. The exact-wallet conformance proof-of-concept is a blocker before implementation or any privacy/readiness claim.
- **Rejected:** A bearer-secret refund is not an approved architecture and must not be silently adopted as a fallback. A receipt preimage alone does not establish recipient authorization, replay resistance, or safe destination binding.
- **Fallback policy:** If the conformance POC fails, either defer/fail closed, or use only a tightly bound capability fallback whose authorization, destination, replay, and theft limits are explicitly documented. No fallback may claim anonymous refunds or replay safety without evidence.
- **Rationale:** The design must bind the refund authorization and resulting `OpenNoteDeposit` to the intended wallet/application context while preserving one-time state transitions and CEI ordering. See `docs/ADR/002-refund-authorization.md`.
