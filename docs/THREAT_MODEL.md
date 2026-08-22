# BackerZero Threat Model

This is a conservative design threat model, not a security audit. It covers the initial MVP using one stateful Cairo helper, one STRK20 pool, one fixed ERC-20, browser-held capability secrets, and Wallet API private actions. No privacy guarantee is implied beyond the documented narrow boundary.

## Double refund

**assets**

Contribution liability, the associated receipt commitment, escrowed token amount, and the one-time refund state.

**attack path**

A user or observer submits the same valid receipt secret more than once, races two refund calls, or exploits a state-update/order bug so both calls release the same contribution.

**impact**

The helper can become insolvent, aggregate accounting can be overstated, and another campaign's liabilities or direct token balance could be consumed.

**mitigation**

Key each contribution by a unique commitment; reject duplicates; check failed-campaign and deadline guards; mark the contribution spent before approval/output; decrement liabilities exactly once; use checked arithmetic and invariant tests.

**residual risk**

The final Cairo implementation, pool interaction, reentrancy/callback behavior, and exact state ordering are not implemented or independently reviewed.

**evidence needed**

Cairo unit, fuzz, stateful, and invariant tests; reviewed source showing checks-effects-interactions ordering; simulated and human-approved tiny-value failed-campaign lifecycle with independently verified pool evidence.

## Replay

**assets**

Receipt preimages, creator capability preimages, commitment uniqueness, and release authorization.

**attack path**

A preimage exposed in public calldata, logs, browser state, or copied user material is replayed by another party before the intended claim settles.

**impact**

An unauthorized party may consume the one-time refund or claim capability, potentially directing value away from the intended user.

**mitigation**

Keep secrets client-local; never log or emit them; use one-time commitment state; bind commitments to version/domain, chain ID, helper, campaign, and capability type; evaluate destination binding or one-time signature authorization before release.

**residual risk**

A plain bearer-secret refund is explicitly unresolved and unaudited. Public claim calldata may reveal a preimage, and commitment binding alone does not prove recipient authorization.

**evidence needed**

A formal authorization decision; adversarial race/replay tests; exact transaction visibility analysis; proof that the chosen open-note destination is bound to the intended shielded recipient; independent security review.

## Secret theft

**assets**

Receipt secrets, creator capability secrets, wallet state, and the ability to recover funds.

**attack path**

Malware, malicious browser extensions, screenshots, clipboard history, browser storage exposure, shared devices, phishing, or accidental analytics/logging captures a secret.

**impact**

The thief may attempt a refund or creator claim; the legitimate user may permanently lose the capability because secrets are unrecoverable.

**mitigation**

Generate cryptographically random secrets in the browser; keep them local; avoid server upload, analytics, logs, screenshots, and test fixtures; provide encrypted/local export only if implemented; display loss warnings; use tiny demo amounts while bearer authorization remains unresolved.

**residual risk**

BackerZero cannot protect a secret after compromise and cannot promise recovery. Browser and wallet security are outside the helper's control.

**evidence needed**

Frontend data-flow review; tests proving secrets do not enter network requests, logs, telemetry, or DOM-visible diagnostics; documented recovery/loss behavior; independent client-side security review.

## Unauthorized creator claim

**assets**

Creator capability, campaign raised amount, creator identity/authorization, and successful-campaign release.

**attack path**

An attacker guesses, steals, replays, or front-runs the creator capability, or exploits missing creator-wallet authorization or campaign binding to claim another campaign.

**impact**

The full raised amount can be released to an unauthorized destination and the campaign becomes permanently claimed.

**mitigation**

Store a domain-separated creator capability commitment bound to chain, helper, campaign, and capability type; enforce deadline, goal, one-time claim, campaign binding, and checks before release; decide whether creator-wallet authorization is additionally required.

**residual risk**

The required creator authorization model and open-note destination binding are unresolved. A bearer capability may be insufficient for production use.

**evidence needed**

Approved creator authorization specification; wrong-secret, wrong-campaign, replay, race, and duplicate-claim tests; exact destination fixture; independent review of the claim path.

## Accounting

**assets**

Raised totals, per-contribution liabilities, total escrow, token balance, campaign isolation, and release amounts.

**attack path**

An attacker uses overflow, an arbitrary token, direct donations, duplicate credits, cross-campaign identifiers, insufficient balance coverage, or inconsistent claim/refund updates to make accounting diverge from held value.

**impact**

The helper may promise more than it holds, release another campaign's value, lock funds, or report false campaign status.

**mitigation**

Bind one verified pool/token; track explicit liabilities separately from raw balance; require balance coverage before crediting; use checked arithmetic; bind token, amount, campaign, and commitment; isolate campaign records; update accounting before release; test conservation and solvency invariants.

**residual risk**

Pool/token constants and final ABI are unverified, and no implementation or tests exist. ERC-20 behavioral edge cases remain to be validated against the selected token.

**evidence needed**

Verified read-only pool/token/decimals data; Cairo tests and invariants; malicious-token behavior analysis; exact amount/token fixtures; reviewed source and tiny-value live rehearsal.

## Front-running

**assets**

Pending creator claims, refunds, contribution state, capability preimages, open-note destinations, and campaign timing.

**attack path**

An observer monitors public transaction calldata or mempool/relayer-visible data and submits a competing claim/refund, copies a preimage, or exploits ordering at the deadline.

**impact**

The observer may consume a one-time capability, cause a legitimate call to fail, or influence which release settles first.

**mitigation**

Use one-time state transitions; bind every operation to campaign and capability; define exact deadline semantics; prepare and simulate through the Wallet API; avoid revealing secrets before a safe authorization design exists; require state changes before external release.

**residual risk**

Public claim calldata and relayer ordering may still expose bearer preimages. Starknet ordering, wallet privacy, and open-note destination semantics have not been validated for this design.

**evidence needed**

Mempool/relayer visibility analysis; deadline-boundary and concurrent-call tests; adversarial transaction-order tests; documented destination authorization; independent review.

## Timing correlation

**assets**

The intended unlinkability between a backer's wallet and a campaign contribution.

**attack path**

An observer correlates shielding deposits, private withdrawal timing, helper invocation, campaign activity, and later open-note payout timing.

**impact**

The observer may infer or narrow the likely contributor set despite the hidden direct wallet link.

**mitigation**

State the narrow privacy promise; disclose timing visibility; warn against shielding immediately before a distinctive contribution; avoid claims of anonymity or untraceability; use STRK20 shielded balances and Wallet API flows as documented.

**residual risk**

Timing correlation remains possible and is not eliminated by BackerZero. No anonymity set, delay, batching, or timing-hiding mechanism is provided by the MVP.

**evidence needed**

Observed transaction-flow analysis on the verified pool; privacy disclosure review; usability testing that confirms users understand timing limitations; no unsupported privacy benchmark.

## Amount correlation

**assets**

Contribution amounts, aggregate raised values, shielding deposits, and open-note payout amounts.

**attack path**

An observer matches a distinctive shielded deposit or payout amount to a public contribution or campaign total.

**impact**

The observer may infer a contributor or associate a wallet activity pattern with a campaign.

**mitigation**

Disclose that amounts remain visible at application/helper and note layers; do not claim hidden amounts; encourage conservative demo values and avoid presenting amount matching as private.

**residual risk**

The MVP does not hide contribution, deposit, or payout amounts and provides no denomination standardization or batching.

**evidence needed**

Exact action and note amount inspection against the verified pool; public/private disclosure matrix; review confirming all UI copy matches observed behavior.

## Privacy leakage

**assets**

Backer-wallet unlinkability, receipt/capability secrecy, campaign records, browser telemetry, and user expectations.

**attack path**

Backer addresses are accepted or emitted; secrets enter logs/analytics; viewing keys are handled by the app; public metadata or event fields reveal more than intended; UI copy overstates privacy.

**impact**

Users may be deanonymized, lose control of funds, or make decisions based on a false privacy guarantee.

**mitigation**

Never accept, store, or emit a backer address in helper accounting; keep secrets and viewing keys out of BackerZero; use Wallet API balance/action routes; maintain a public/private disclosure matrix; prohibit uploads, logs, screenshots, and fixtures containing secrets; use conservative approved wording.

**residual risk**

Campaign activity, amounts, timing, helper actions, deposits, open-note data, and correlation signals may remain visible. Browser, wallet, RPC, and relayer metadata are not fully controlled.

**evidence needed**

ABI/event and network-payload review; browser telemetry inspection; privacy-copy review; source review proving no viewing-key or secret handling; independent privacy/security assessment.

## Malicious tokens

**assets**

Escrowed token value, accounting assumptions, approvals, transfer semantics, and user funds.

**attack path**

A wrong or malicious token is configured, or a token has fee-on-transfer, rebasing, callback, nonstandard return, blacklist, pause, or deceptive-decimal behavior that breaks amount assumptions.

**impact**

The helper can become insolvent, misaccount balances, lock funds, over-approve, or release an amount different from the recorded liability.

**mitigation**

Use exactly one token only after address/decimals and live pool compatibility are verified; bind the token in the helper; validate actual supported ERC-20 behavior; use exact amount fixtures; minimize approvals; reject unexpected token configuration.

**residual risk**

The current token and decimals are unverified, and no malicious-token test or live compatibility check has occurred. The MVP does not support arbitrary campaign tokens.

**evidence needed**

Official token and pool verification; ERC-20 behavior tests including adversarial mocks; approval/amount accounting review; read-only chain evidence and tiny-value rehearsal.

## Admin/upgrade risk

**assets**

Helper code, configured pool/token, campaign state, escrow liabilities, and user confidence in immutability/authority.

**attack path**

An administrator, upgrade authority, deployment operator, compromised key, or hidden privileged path changes pool/token configuration, code, accounting, or release behavior.

**impact**

Funds can be redirected, liabilities invalidated, privacy boundaries changed, or the application can become unavailable.

**mitigation**

Keep the helper architecture simple and explicitly document all privileged paths; bind one pool/token; review constructor and upgrade configuration; do not deploy until human-approved; publish class hash/address and constructor values only after verification; avoid claiming trustlessness where an authority remains.

**residual risk**

Deployment has not occurred, upgrade/admin design is not finalized, and no audit has been performed. Operational key compromise and protocol/pool governance risk remain outside the helper.

**evidence needed**

Final Cairo source and deployment profile; authority/upgrade inventory; class hash and constructor verification; independent security review; human-approved deployment record and documented rollback/incident procedure.
