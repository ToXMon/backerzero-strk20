BackerZero: Winning Product Requirements,
Technical Specification, Competitive Analysis, and
Autonomous Build Packet
Executive summary
Recommendation: build BackerZero as a stateful STRK20-native crowdfunding protocol with exactly
four headline flows: Create Campaign → Back Privately → Claim Funding → Claim Refund. The strongest
positioning is:


       Public campaigns. Private backers. Trustless refunds.


The STRK20 Private Sprint closes August 31, 2026 at 23:59 UTC, which is 7:59 p.m. EDT in New York. The
judging rubric is unusually favorable to a small, technically deep product: 30% STRK20 integration depth,
30% working mainnet product, 25% innovation, and 15% documentation/open-source quality. The
official rules require a public/open-source repository, a live demo, a three-minute demo video, and at least
three successful Starknet mainnet transactions that touched the STRK20 pool. 1


BackerZero is a particularly good fit because STRK20 explicitly supports application-specific stateful
 privacy_invoke anonymizers. The pool can withdraw shielded funds into a helper, call its application
logic, let the helper retain funds by returning an empty Span<OpenNoteDeposit> , and later let the
helper approve the pool and return an OpenNoteDeposit so a claim or refund lands directly back in a
shielded note. STRK20's own documentation presents precisely this escrow architecture, while warning that
the example is unofficial and must be independently reviewed before production use. 2


That produces a much deeper STRK20 submission than simply exposing Shield/Send/Unshield buttons:



  Backer shielded balance
            ↓
       STRK20 pool
          ↓ withdraw
  BackerZero helper
          ↓ privacy_invoke(Back)
  Campaign escrow

  Campaign succeeds:
  BackerZero helper
           ↓ approve pool + OpenNoteDeposit
       STRK20 pool
            ↓



                                                      1
  Creator shielded balance

  Campaign fails:
  BackerZero helper
           ↓ approve pool + OpenNoteDeposit
       STRK20 pool
          ↓
  Backer shielded refund


The current field reinforces that strategy. The registry is already crowded with payroll, prediction markets,
auctions, trading, payments, wallets, OTC settlement, subscriptions, cross-chain privacy, governance, and
privacy tooling, while my current registry/pitch audit found no entry explicitly centered on all-or-nothing
crowdfunding or private campaign backing. That is a point-in-time finding, not a guarantee that another
team will not pivot before August 31.


The biggest competitive threats are not necessarily conceptually similar projects. They are teams already
demonstrating execution. Philoxenia already has three recorded mainnet STRK20 transactions, three
contract addresses, a live demo, and a demo video. Redpocket already has three recorded mainnet
transactions and implements the same broad class of stateful pool → escrow → OpenNoteDeposit
mechanics BackerZero needs. Aperture's manifest also currently records three mainnet transactions.


Therefore, BackerZero should try to win through rubric certainty rather than feature count:


 Winning
                       BackerZero target
 objective

 STRK20                Stateful custom anonymizer; shielded balance; privacy_invoke ; parked escrow;
 integration            OpenNoteDeposit ; private refunds; private creator claim

 Mainnet               One small hardened Cairo contract, deployed early; 5–7 verified pool
 execution             transactions, not merely the required three

                       Crowdfunding/capital formation with public campaign accountability but no public
 Innovation
                       backer-wallet graph

                        PRIVACY.md , THREAT_MODEL.md , ARCHITECTURE.md , mainnet evidence,
 Documentation
                       tests, diagrams, reproducible build

                       A contribution visibly changes $6 → $11 funded while the explorer never
 Demo
                       reveals the contributing user's wallet link

                       Feature freeze August 25; milestone mode only after the core mainnet lifecycle is
 Scope discipline
                       proven

The core strategic rule should be:




                                                       2
       Do not build Milestone Mode, AI features, cross-chain support, multi-token support, a
       backend, or any second product until Back → Creator Claim → Failed Refund all work
       against the live mainnet pool and five qualifying hashes have been recorded.


The STRK20 Wallet API should be the application integration route. STRK20 recommends it for most dapps
specifically because the dapp can request private actions without handling the user's viewing key or the
low-level privacy SDK itself. Current private-dapp documentation requires starknet@^10.4.0 and Wallet
API 0.10.3 .    3




The central privacy promise must also be deliberately narrow and truthful. BackerZero can claim that
the public chain does not receive the link between a contributing user's account and the campaign
contribution when the action is performed from already-shielded funds through STRK20. It cannot claim
that contribution amounts, contribution timing, campaign totals, shielding deposits, or open-note payout
amounts are secret. STRK20 explicitly states that helper actions and moved amounts are visible, open-note
amounts are plaintext, and deposits expose depositor address, token, and amount. 4


That distinction is actually an advantage for crowdfunding:


       The money raised should be public. The people backing it should not have to be.


That is a product proposition aligned with what STRK20 genuinely provides rather than a privacy claim
fighting against the protocol.


Hackathon landscape and competitive position
The sprint is an 18-day mainnet sprint rather than a concept competition. It opened August 14, closes
August 31 at 23:59 UTC, and awards $2,500 / $1,500 / $1,000 for first through third. The official judging
page weights implementation and mainnet delivery more heavily than novelty alone. 1


The repository rules make the operational bar explicit: the app must run against the live STRK20 mainnet
pool, the repository must be public and licensed, and strk20.json must contain at least three successful
mainnet transaction hashes that touched the STRK20 pool. A three-minute demo video and live demo are
required for scoring.


The hackathon's own Day-0 guide gives the verified mainnet pool as:



  CHAIN_ID = SN_MAIN
  POOL_ADDRESS =
  0x040337b1af3c663e86e333bab5a4b28da8d4652a15a69beee2b677776ffe812a


It explicitly advises teams to prove they can reach mainnet before writing the application, and notes that
shielding is a screened and public edge while subsequent note-based activity provides the privacy.


Current high-signal competitor audit. The following table focuses on the projects most relevant either
because they have significant execution already, attack adjacent privacy primitives, or demonstrate a design




                                                      3
standard BackerZero must match. Status reflects the repositories/manifests inspected on August 16, 2026
and can change throughout the sprint.


                                         Mainnet
                                          STRK20                                      Competitive risk to
 Project        Current status                          Distinguishing feature
                                              txs                                     BackerZero
                                        recorded

                                                        Private peer-to-peer          Very high —
                Live, mainnet
                                                        hospitality, escrow, social   currently one of the
 Philoxenia     contracts, demo                 3
                                                        trust, sealed messaging,      clearest execution
                URL and video
                                                        STRK20 payment path           leaders.

                Live mainnet demo;                                                    Very high — closest
                                                        Password red packets
                stateful anonymizer                                                   architecture analogue
                                                        with shielded claims/
 Redpocket      deployed; video                 3                                     and proof stateful
                                                        refunds, Merkle tickets,
                field currently                                                       escrow can ship
                                                        equal/lucky split
                empty                                                                 quickly.

                                                                                      High — already has
                Governance/
                                                                                      the minimum
                treasury build;
                                                        Sealed-ballot governance      qualifying transaction
 Aperture       manifest ahead of               3
                                                        plus shielded treasury        count, though direct
                some README
                                                                                      product overlap is
                status text
                                                                                      low.

                                                                                      Medium-high —
                Strong app/tests/                                                     excellent product/
                                                        Prediction market with
                live frontend;                                                        privacy
                                                        public odds/amounts but
 Veilcast       manifest currently              0                                     documentation and
                                                        unlinkable bettors and
                has no mainnet                                                        Cairo engineering;
                                                        bearer coupon keys
                deployment                                                            mainnet gap is the
                                                                                      opportunity.

                                                                                      Medium-high —
                Full lifecycle on                       Vickrey auction with          rigorous security
                Sepolia, extensive                      uniform collateral and        narrative; could
 Sealed                                         0
                tests, mainnet not                      separated identity/bid        become strong
                yet recorded                            privacy                       quickly after mainnet
                                                                                      migration.

                Settlement
                                                                                      Medium — related
                architecture
                                                                                      escrow/state-machine
                implemented;                            Private bilateral OTC with
                                                                                      mechanics, but
 Offbook        recorded contract is            0       shield→lock→claim/
                                                                                      competing in a
                currently non-                          reclaim flow
                                                                                      crowded RFP
                qualifying for
                                                                                      category.
                mainnet scoring




                                                    4
                                         Mainnet
                                          STRK20                                    Competitive risk to
 Project        Current status                          Distinguishing feature
                                              txs                                   BackerZero
                                        recorded

                Live interface and
                basic privacy                                                       Medium — polished
                primitives; fair                        Private launch/trading      demo potential but
 Veyl                                           0
                launch/execution                        terminal                    broader and riskier
                identity still being                                                scope.
                built

                SDK/component                                                       Medium — could
                architecture in                         Drop-in noncustodial        score highly on reuse/
 Tx404          progress; no                    0       shield/transfer/unshield/   open-source quality
                qualifying manifest                     invoke SDK                  even without direct
                entries yet                                                         product overlap.

                                                                                    Medium — another
                Live demo URL; no                       Encrypted deal room
                                                                                    privacy + escrow
 VINSS          qualifying txs/                 0       plus private escrow
                                                                                    application, but much
                contracts recorded                      settlement
                                                                                    larger surface area.

                                                                                    Low-medium —
                Early/current                           Private payroll with        crowded payroll lane
 Paybook                                        0
                manifest empty                          scoped disclosure           and current execution
                                                                                    gap.

                                                                                    Low-medium —
                                                                                    strong STRK20 fit but
                Early/current                           Private recurring
 Aegis                                          0                                   unrelated product
                manifest empty                          subscriptions
                                                                                    and current mainnet
                                                                                    gap.

                                                                                    Low-medium —
                Tooling build;
                                                        Privacy preflight/timing    differentiated tooling
                current submission
 VeilCheck                                      0       and amount-leakage          rather than
                manifest has no
                                                        detection                   transaction
                qualifying hashes
                                                                                    application.

This field shows why merely saying “private crowdfunding” will not be sufficient. Redpocket already
demonstrates the important stateful-anonymizer pattern: on create, funds are parked in its helper and
it returns an empty span; on claims/refunds it updates state, approves the privacy pool, and returns
 OpenNoteDeposit instructions. Its code also tracks locked liabilities and uses domain-separated
Poseidon commitments.


BackerZero therefore needs to differentiate at the mechanism and product level, not by pretending the
underlying primitive is unique:




                                                    5
  Redpocket                                      BackerZero

  Distribute a predefined pot among
                                                 Aggregate independent contributions toward a goal
  recipients

  Claim-link/payment ritual                      Capital-formation mechanism

  Creator funds the pot                          Many private users fund one public campaign

  Expiry refund returns leftovers                Failure creates individual contributor refund rights

  Claiming is the central product action         Funding success/failure is the state transition

  Present implementation identifies              BackerZero should avoid using a public account as the
  claimant transactions publicly                 contribution identity whenever possible

  No campaign goal                               Public goal + raised total are first-class protocol state

Redpocket's README explicitly acknowledges that its creator and current claimers are publicly visible
transaction accounts and that payout amounts are public. Its implementation is nevertheless an excellent
warning about what a well-documented competitor can ship in the same sprint.


Veilcast supplies another valuable design lesson. It uses fresh cryptographic position keys rather than a
user's public account as the position identity and checks that the helper's actual ERC-20 balance covers
aggregate escrow liabilities before crediting new stakes. Its claim path marks a position spent and
decrements liabilities before approving or transferring the payout. Those are security properties BackerZero
should independently implement rather than copying competitor source.


White-space assessment. The official idea set includes private payroll, subscriptions, OTC, prediction
markets, auctions, token launches, private yield, governance, treasury and related infrastructure. Its “capital
formation” section focuses on confidential token launches rather than ordinary goal-based crowdfunding.
The rules explicitly allow projects outside the published ideas.


That makes BackerZero's strongest strategic framing:


       STRK20-native capital formation for things that are not token sales.


Examples immediately understandable to judges include open-source software, independent media,
politically or commercially sensitive causes, founders backing another project without signaling strategy,
grants, community infrastructure, and pseudonymous creators. These are proposed product use cases
rather than claims about existing demand.


The direct win condition, in my assessment, is to beat current entrants along three axes simultaneously:


First, stronger rubric evidence. Record seven successful mainnet pool transactions when only three are
required. The rules explicitly verify qualifying hashes against chain state.




                                                       6
Second, stronger truthfulness. Put a “What is private?” table directly inside the product and README.
Several of the best competitors already document their leakage surfaces unusually well; judges evaluating
integration depth are likely to notice exaggerated privacy claims.


Third, a simpler demo story. A judge should understand the novel property in ten seconds:


        “Watch the campaign total rise. Then look for the backer's wallet. You can't.”


That is easier to demonstrate than a multivenue trading strategy, cross-chain route, complex auction
mechanism, or general privacy SDK.


Product requirements and demo experience
Product definition. BackerZero is an all-or-nothing crowdfunding application on Starknet where campaign
parameters and aggregate funding remain public while individual contributions are funded from shielded
STRK20 balances without exposing the initiating user's wallet link. When a campaign succeeds, the creator
can claim the campaign escrow into a shielded note; when it fails, each backer can reclaim their
contribution into a shielded note using a private refund capability generated at contribution time. This
privacy boundary follows STRK20's documented model: application action/amounts can remain public while
the identity link to the shielded user is hidden. 5


Primary persona — backer. The user wants to support a campaign without publishing “wallet X backed
campaign Y,” yet accepts that the amount and time of an application-level contribution may be observable.
STRK20's helper flows are designed specifically around that identity/amount distinction. 6


Primary persona — campaign creator. The creator wants public evidence that a goal was reached and
programmatic custody/refund rules, while optionally keeping later use of claimed funds inside their
shielded STRK20 balance. The creator's own Create Campaign transaction is public in the MVP; hiding
campaign ownership should not be claimed. Private Wallet-API sub-account support is not a dependency to
put on the critical path because the STRK20 build page still marks private subaccounts as coming soon for
this integration route. 7


MVP acceptance requirements:


 Flow              Product requirement                             Acceptance criterion

                                                                   Campaign exists on mainnet with
 Create            Creator enters title/metadata, target,
                                                                   deterministic ID, public goal/deadline/
 Campaign          deadline and chosen token configuration
                                                                   creator and Active status

                   Backer enters amount from shielded              Raised total increases exactly by amount;
 Back              balance; browser creates a refund receipt       escrow liabilities increase; no backer
 Privately         secret; pool funds the helper through           address is stored or emitted by
                    privacy_invoke                                 BackerZero




                                                       7
 Flow             Product requirement                            Acceptance criterion

                                                                 Exactly raised is released once via
 Claim            After deadline and raised >= goal ,
                                                                  OpenNoteDeposit ; status becomes
 Funding          creator presents creator capability
                                                                 Claimed

                                                                 Exactly that contribution is released once
 Claim            After deadline and raised < goal , a
                                                                 via OpenNoteDeposit ; duplicate
 Refund           backer imports/uses their receipt secret
                                                                 refund fails

The underlying all-or-nothing state machine is conventional crowdfunding logic—goal, expiry, success
claim, failure refund—while the privacy-specific contribution and payout paths are what STRK20 changes.
Starknet's own educational examples use similar crowdfunding state transitions, while STRK20 supplies the
anonymizer/open-note layer. 8


The campaign itself should support overfunding: if a campaign target is 10 USDC and contributions total
11 USDC before the deadline, the campaign succeeds with 11 USDC and the creator becomes entitled to the
complete 11 USDC. This is a recommended BackerZero product rule, not an STRK20 requirement.


The product should not require an explicit finalize() transaction. Status can be derived from
block_timestamp , goal, amount raised and whether the creator has claimed:



  if now < deadline:
      Active

  else if raised >= goal and !claimed:
      Successful

  else if raised >= goal and claimed:
      Claimed

  else:
      Failed


That reduces transaction count, contract surface and user confusion. Events can still make state transitions
easy to index.


A campaign should permit very short deadlines in the contract for testing and the live judging
demonstration, even if the production UI defaults to longer intervals. A 90–180 second demo campaign
makes it practical to demonstrate both success and failure without deploying a special “demo-only”
contract.


Token policy. The MVP should support one configured ERC-20 only. Native USDC is attractive for
crowdfunding semantics, but the release gate is not “USDC sounds good”; it is “the exact token works
reliably through the current mainnet Wallet API and live STRK20 pool.” If USDC causes any wallet/proving




                                                        8
friction during the first mainnet rehearsal, use STRK for the judging build instead. The sprint rules reward a
working mainnet application rather than token breadth.


Receipt design. Each private contribution should generate a cryptographically random secret locally and
derive a domain-separated commitment:



  receipt_commitment =
      Poseidon(
            "BACKERZERO_RECEIPT_V1",
            chain_id,
            contract_address,
            campaign_id,
            receipt_secret
       )


Only the commitment goes into BackerZero storage. The secret stays in the browser/user receipt until
needed for a failed-campaign refund. Domain-separated Poseidon commitments follow the same general
defensive pattern shown in STRK20's escrow documentation. 8


The UI should produce a downloadable receipt such as:



  {
      "version": 1,
      "network": "SN_MAIN",
      "contract": "0x...",
      "campaignId": "12",
      "token": "0x...",
      "amount": "5000000",
      "receiptCommitment": "0x...",
      "receiptSecret": "0x..."
  }


The receipt must be treated like a bearer capability in the first MVP design: never upload it to BackerZero
servers, never include it in analytics, and explicitly warn the user that losing it can destroy their
ability to recover funds from a failed campaign.


The creator should receive a parallel creator_claim_secret when creating the campaign, with only its
commitment stored on-chain. This avoids making the creator's eventual shielded claim authorization
depend solely on the same public account that created the campaign. Whether creator wallet signature
should additionally be required is an open security/product decision; the simplest sprint implementation
can use the creator capability, but the threat model must say exactly what possession of that capability
permits.


Recommended screen architecture:




                                                      9
 Screen                 Demo purpose

                        Immediately explains “Public campaigns. Private backers.” and presents one
 Landing / Explore
                        excellent demo campaign

                        Giant raised/goal progress, deadline, privacy boundary, shielded balance and one
 Campaign Detail
                        primary CTA

                        Amount, current shielded balance, “what observers see” disclosure, then one
 Back Sheet
                        transaction stepper

 Contribution
                        Celebratory state plus prominent “Download refund receipt” action
 Receipt

 Creator
                        Campaign status and shielded “Claim Funding” action
 Dashboard

 Failed Campaign        Receipt import/paste and “Claim Refund Privately”

                        Mainnet contract, transaction hash, STRK20 pool status and concise explorer
 Evidence Drawer
                        explanation

For demo impact, the Campaign Detail view should be extremely visual:



  OPEN PRIVACY TOOLING
  ██████████████████░░░░░░░

  $6.00 raised of $10.00

  [ Back Privately ]

  Visible:
  ✓ campaign
  ✓ contribution amount
  ✓ total raised

  Hidden by STRK20:
  ✓ link to your funding wallet


After the second contribution:



  $11.00 / $10.00

  FUNDED
  ██████████████████████████




                                                   10
  11 USDC publicly raised
  0 backer wallets stored by BackerZero


The important wording is “wallet link hidden”, not “the contribution is invisible,” because helper amounts
and activity remain observable under STRK20. 4


The Wallet API can read shielded balances without exposing a viewing key to the dapp, and
 strk20PrepareInvoke(actions, true) can build/prove/simulate a private action before submission.
Both should be first-class UX features: show the user's private balance and dry-run before broadcast instead
of discovering a calldata-shape failure after the user signs. 6


Transaction progress must look intentional rather than frozen. STRK20 private actions involve proof
preparation, so the interface should have explicit stages:



  Preparing private transaction
       ↓
  Generating privacy proof
       ↓
  Simulating execution
       ↓
  Confirm in Ready
       ↓
  Submitted by privacy relayer
       ↓
  Confirmed on Starknet


The exact proving latency is environment-dependent; competitors report noticeable proof-generation
times, so the UX should tolerate a long-running private action rather than show a generic spinner.


For visual design, align BackerZero with STRK20 instead of inventing generic neon cyberpunk crypto styling.
STRK20 publishes a Brand & UI Kit and machine-readable tokens specifically for builders and agents. The
official Build page points agents to /brand/tokens.json and /brand.md . 9


Recommended visual direction:



  near-black surfaces
  sharp 1px borders
  large white campaign numbers
  orange only for primary actions / privacy state
  monospace labels for protocol facts
  large display face for campaign titles
  very restrained glow




                                                    11
The UI team or autonomous agent should be skilled in five disciplines: Cairo state-machine/security
engineering, STRK20 Wallet API integration, strict TypeScript/Next.js engineering, high-polish
interaction/motion design, and release/demo QA. With unconstrained team size, those may be parallel
roles, but one engineer must own the Cairo invariants and one release owner must have authority to reject
new features after feature freeze.


Recommended frontend stack. Start from the official STRK20 starter kit rather than a blank app. It
currently demonstrates Next.js 16, React 19, TypeScript, starknet.js 10, Zustand, get-starknet wallet
discovery, shield/unshield/private transfer/balance paths and a deployable privacy_invoke helper.


A practical product stack is therefore:



  Next.js 16 / App Router
  React 19
  TypeScript strict
  starknet.js >= 10.4, pinned in lockfile
  get-starknet v6
  Zustand
  Tailwind CSS
  small component primitives
  Motion for critical transitions only
  Vitest
  Playwright
  Vercel
  Cairo + Scarb + Starknet Foundry


No database is needed for the financial MVP. Campaign metadata can either be kept compactly on-chain or
use a simple content URI; that choice should remain OPEN until contract-size/gas measurements are
available. Adding Postgres, authentication, indexing infrastructure, GraphQL or a custom privacy backend
before the four core flows work would be negative expected value for this sprint.


Optional Milestone Mode comes only after the mainnet MVP is frozen. A successful campaign could define
two or three tranches; creators request a tranche, and contribution capabilities authorize weighted
approvals before the next tranche unlocks.


However, be precise about terminology: STRK20 can hide which public wallet is behind a contribution,
but an ordinary privacy_invoke(VoteYes) call may still reveal the vote choice in application calldata. A
genuinely secret ballot requires an additional mechanism such as commit/reveal or a dedicated
cryptographic voting design. Therefore the stretch feature should initially be sold as “anonymous-backer
milestone approval”, not “fully private governance,” unless the choice itself is cryptographically concealed.


Technical architecture and prioritized specification
The recommended architecture is deliberately small: one stateful BackerZero helper contract bound to
one STRK20 pool and one ERC-20 token, plus a static/serverless web application. STRK20 itself owns note




                                                     12
discovery, viewing keys and proof generation through the wallet API; BackerZero should not implement
those systems. STRK20 explicitly recommends the Wallet API route for most private dapps so application
code does not handle the viewing key or low-level SDK. 3



                                                                               Privacy-capable Starknet    strk20InvokeTransaction
                                                                                        Wallet
                                                        strk20Balances
                                                                                                              approve pool +
       Backer Wallet    BackerZero Web App                                                                    OpenNoteDeposit                                 Creator Shielded Note


                                                     Create Campaign\npublic                                                           STRK20 Mainnet Pool
                                                     Starknet tx                                          approve pool +
                                                                                                          OpenNoteDeposit
                                                                                                              withdraw contribution                           Backer Shielded Refund
                          Creator Wallet
                                               read public campaign
                                               state                           BackerZeroCampaignHelp       privacy_invoke(Back)
                                                                                          er

                                                                                                           record liability\nreturn
                                                                                                           empty span

                                                                                                          successful campaign
                                                                                                                                      Campaign Escrow State
                                                                                                          failed campaign




This exactly uses STRK20's documented anonymizer lifecycle: the pool transfers input to the helper before
invocation, the helper may return an empty span to park funds, and later it approves the pool and returns
 Span<OpenNoteDeposit> for shielded output. Only the privacy pool should be permitted to enter the
private application path.                  2




Priority ordering:


  Priority             Technical requirement                                                                                 Rationale

                                                                                                                             No value in building against
                       Mainnet Wallet API capability + live pool sanity
  P0                                                                                                                         assumptions; hackathon scores
                       transaction
                                                                                                                             mainnet

  P0                   Campaign + contribution liability state machine                                                       Money-safety core

  P0                   privacy_invoke(Back) parking funds                                                                    Highest-value STRK20 integration

                       privacy_invoke(ClaimRefund) →
  P0                                                                                                                         Core failed-campaign promise
                       OpenNoteDeposit

                       privacy_invoke(ClaimFunding) →
  P0                                                                                                                         Core successful-campaign promise
                       OpenNoteDeposit

  P0                   Exact liability/solvency invariant                                                                    Prevents undercollateralization

  P0                   Wallet action builders + "OPEN" placeholders                                                          Makes the Cairo contract reachable

  P0                   Mainnet deployment + 5 qualifying hashes                                                              Competition eligibility and evidence

                       Receipt export/import and cross-language                                                              Prevent lost/refund-incompatible
  P1
                       Poseidon fixture                                                                                      capabilities

  P1                   Public privacy disclosure + tx evidence UI                                                            Judge comprehension

                                                                                                                             Needed because helper holds real
  P1                   Fuzz/stateful testing and independent review
                                                                                                                             assets




                                                                                             13
 Priority       Technical requirement                                  Rationale

                Reusable @backerzero/strk20-actions
 P2                                                                    Improves OSS score/reuse potential
                package

 P3             Milestone mode                                         Stretch only

 Not
                Cross-chain, private subaccounts, multi-token          High schedule risk, little rubric
 sprint
                campaigns, AI campaign creation                        leverage
 scope

The storage model should be explicit about liabilities rather than treating the ERC-20 contract balance as
application accounting:



  // Pseudocode / design sketch — not compile-ready.

  #[derive(Copy, Drop, Serde, starknet::Store)]
  struct Campaign {
      creator: ContractAddress,
      creator_claim_commitment: felt252,
      goal: u128,
      raised: u128,
      refunded_total: u128,
      deadline: u64,
      contribution_count: u32,
      claimed: bool,
  }

  #[derive(Copy, Drop, Serde, starknet::Store)]
  struct Contribution {
      amount: u128,
      refunded: bool,
  }

  #[storage]
  struct Storage {
      pool: ContractAddress,
      token: ContractAddress,
      next_campaign_id: u64,

       // Sum of assets the contract still owes.
       total_escrow: u128,

       campaigns: Map<u64, Campaign>,

       // campaign_id + receipt commitment => contribution




                                                     14
       contributions: Map<(u64, felt252), Contribution>,
  }


Keeping an explicit total_escrow is important because arbitrary users can send ERC-20 tokens directly
to any contract. A raw token balance is therefore not proof that a particular contribution legitimately arrived
through the expected pool action. The Back operation should require that the helper's balance covers
existing liabilities plus the newly claimed contribution before increasing application liabilities. This is a
recommended BackerZero invariant, consistent with the defensive escrow accounting visible in strong
current hackathon implementations.


The campaign state machine is:




                                               Create Campaign


                                                      Active


            deadline reached\nraised                                 deadline reached\nraised
            >= goal                                                  &lt; goal


                     Successful                                                 Failed


              Creator claims funding       Back privately


                      Claimed


                                                               Individual backer refund




No contribution should be refundable before the deadline merely because the goal has not yet been
reached. No creator claim should be possible before the deadline even if the goal is reached early, unless an
explicit “instant funding” campaign type is added later. Keeping one predictable campaign type reduces
both audit complexity and demo explanation.


A compact operation interface might be:



  #[derive(Serde, Drop)]
  enum BackerZeroOperation {
      Back,



                                                      15
       ClaimFunding,
       ClaimRefund,
  }

  #[starknet::interface]
  trait IBackerZero<TState> {
      fn create_campaign(
          ref self: TState,
          goal: u128,
           deadline: u64,
           creator_claim_commitment: felt252,
       ) -> u64;

       fn privacy_invoke(
           ref self: TState,
           operation: BackerZeroOperation,
           campaign_id: u64,
           amount: u128,
           commitment_or_secret: felt252,
           note_id: felt252,
       ) -> Span<OpenNoteDeposit>;
  }


STRK20 allows the helper to define its own calldata shape as long as the entry point returns exactly the
required Span<OpenNoteDeposit> shape. An empty span is explicitly valid for stateful flows that retain
funds, and output funds should be approved for the pool rather than directly transferred back.   10




Core Back flow pseudocode:



  fn back(
      ref self: ContractState,
      campaign_id: u64,
      amount: u128,
      receipt_commitment: felt252,
  ) -> Span<OpenNoteDeposit> {
      let mut campaign = self.campaigns.read(campaign_id);

       assert(get_block_timestamp() < campaign.deadline, 'CAMPAIGN_CLOSED');
       assert(amount > 0, 'ZERO_AMOUNT');
       assert(receipt_commitment != 0, 'ZERO_COMMITMENT');

       let old = self.contributions.read((campaign_id, receipt_commitment));
       assert(old.amount == 0, 'RECEIPT_EXISTS');

       let new_liability =
           self.total_escrow.read().checked_add(amount).expect('ESCROW_OVERFLOW');




                                                    16
       let balance =
           IERC20Dispatcher { contract_address: self.token.read() }
               .balance_of(get_contract_address());


       // The STRK20 pool must already have transferred this contribution.
       assert(balance >= new_liability.into(), 'NOT_FUNDED');

       campaign.raised =
           campaign.raised.checked_add(amount).expect('RAISED_OVERFLOW');
       campaign.contribution_count += 1;

       self.campaigns.write(campaign_id, campaign);
       self.contributions.write(
           (campaign_id, receipt_commitment),
           Contribution { amount, refunded: false }
       );
       self.total_escrow.write(new_liability);

       self.emit(Backed {
           campaign_id,
           amount,
           raised: campaign.raised,
       });

       // Money remains inside BackerZero escrow.
       [].span()
  }


The STRK20 escrow reference demonstrates exactly this general “pool transferred tokens → helper records
commitment → empty span” pattern.      8




Critically, Backed should not contain a backer address. There is no business reason to emit one, and
accepting a caller-supplied “backer” address would reintroduce the identity graph STRK20 is being used to
avoid.


Refund pseudocode:



  fn claim_refund(
      ref self: ContractState,
      campaign_id: u64,
      secret: felt252,
      note_id: felt252,
  ) -> Span<OpenNoteDeposit> {
      let mut campaign = self.campaigns.read(campaign_id);




                                                    17
       assert(get_block_timestamp() >= campaign.deadline, 'NOT_FINISHED');
       assert(campaign.raised < campaign.goal, 'CAMPAIGN_SUCCEEDED');

       let commitment = compute_receipt_commitment(
           campaign_id,
            secret
       );

       let mut contribution =
            self.contributions.read((campaign_id, commitment));

       assert(contribution.amount > 0, 'NO_CONTRIBUTION');
       assert(!contribution.refunded, 'ALREADY_REFUNDED');

       let amount = contribution.amount;

       // Effects first.
       contribution.refunded = true;
       campaign.refunded_total += amount;
       self.contributions.write((campaign_id, commitment), contribution);
       self.campaigns.write(campaign_id, campaign);
       self.total_escrow.write(self.total_escrow.read() - amount);

       // Interaction second.
       IERC20Dispatcher { contract_address: self.token.read() }
           .approve(self.pool.read(), amount.into());

       self.emit(Refunded { campaign_id, amount });

       [OpenNoteDeposit {
           note_id,
           token: self.token.read(),
           amount,
       }].span()
  }


That matches the documented STRK20 stateful-escrow output model: mark the capability spent, approve
the privacy contract, return the open-note instruction. 8


Successful funding claim pseudocode:



  fn claim_funding(
      ref self: ContractState,
      campaign_id: u64,
      creator_secret: felt252,
      note_id: felt252,




                                                  18
  ) -> Span<OpenNoteDeposit> {
      let mut campaign = self.campaigns.read(campaign_id);

       assert(get_block_timestamp() >= campaign.deadline, 'NOT_FINISHED');
       assert(campaign.raised >= campaign.goal, 'GOAL_NOT_REACHED');
       assert(!campaign.claimed, 'ALREADY_CLAIMED');

       assert(
           compute_creator_commitment(campaign_id, creator_secret)
                == campaign.creator_claim_commitment,
            'BAD_CREATOR_CAPABILITY'
       );

       let amount = campaign.raised;

       // State changes before external approve.
       campaign.claimed = true;
       self.campaigns.write(campaign_id, campaign);
       self.total_escrow.write(self.total_escrow.read() - amount);

       IERC20Dispatcher { contract_address: self.token.read() }
           .approve(self.pool.read(), amount.into());

       self.emit(FundingClaimed { campaign_id, amount });

       [OpenNoteDeposit {
           note_id,
           token: self.token.read(),
           amount,
       }].span()
  }


The entry point itself must begin with pool authorization:



  assert(
      get_caller_address() == self.pool.read(),
       'CALLER_NOT_POOL'
  );


STRK20's own escrow example describes this check as fundamental access control: users should not be able
to bypass the pool and directly drive a “private” helper path. 8


The frontend action for Back Privately should follow the starter-kit composition pattern:




                                                     19
  const actions: STRK20_ACTION[] = [
    {
      type: "withdraw",
      token,
            amount: num.toHex(amount),
            recipient: backerZeroAddress,
       },
       {
            type: "invoke",
            contract: backerZeroAddress,
            calldata: [
               OP_BACK,
               num.toHex(campaignId),
               num.toHex(amount),
               receiptCommitment,
               "0x0", // note_id unused for Back
            ],
       },
  ];

  await account.strk20PrepareInvoke(actions, true);
  const { transaction_hash } =
    await account.strk20InvokeTransaction(actions);


The official starter kit uses the same withdraw → helper invoke composition for a private helper
action.


Refund/creator-claim actions need an open note first:



  const actions: STRK20_ACTION[] = [
    {
      type: "transfer",
      token,
      amount: "OPEN",
      recipient: connectedAddress,
       },
       {
            type: "invoke",
            contract: backerZeroAddress,
            calldata: [
              OP_CLAIM_REFUND,
              num.toHex(campaignId),
              "0x0",
              receiptSecret,
              "${openNoteIds[0]}",




                                                   20
            ],
       },
  ];

  await account.strk20PrepareInvoke(actions, true);
  const { transaction_hash } =
    await account.strk20InvokeTransaction(actions);


"OPEN" and ${openNoteIds[0]} are not ordinary numeric values: the Wallet API resolves the open-
note placeholder while constructing the private transaction. The official Wallet API documentation and
starter kit explicitly demonstrate this pattern. 6


The MVP should use strk20Balances([token]) for the user's shielded balance rather than
implementing note discovery itself. That keeps viewing-key handling inside the privacy-enabled wallet.   6




Mainnet deployment sequence:



  # Web workspace
  corepack enable
  pnpm install --frozen-lockfile
  pnpm typecheck
  pnpm test
  pnpm build

  # Cairo
  cd contracts
  scarb fmt --check
  scarb build
  snforge test

  # Representative sncast flow.
  # Exact account/profile names remain operator-specific.
  sncast --profile mainnet declare \
    --contract-name BackerZeroCampaignHelper

  sncast --profile mainnet deploy \
    --class-hash <CLASS_HASH> \
    --constructor-calldata <STRK20_POOL> <TOKEN>


Declaration and deployment themselves are normal Starknet transactions, but they do not satisfy the
hackathon's pool-interaction evidence requirement unless the STRK20 pool is actually involved. Qualifying
evidence should therefore come from the real Shield/Back/Claim/Refund flows.


The recommended evidence matrix is:




                                                    21
  Evidence
                 Action                                       Why include it
  tx

  A              Shield demo funds                            Shows live pool onboarding

  B              Private Back #1 into success campaign        Core application-specific path

  C              Private Back #2, crossing goal               Visually proves aggregation

  D              Creator Claim Funding → open note            Demonstrates successful shielded output

  E              Private Back into failure campaign           Sets up refund path

  F              Claim Refund → open note                     Demonstrates failed-campaign guarantee

                 Private note-to-note transfer after claim/   Shows proceeds remain composable inside
  G
                 refund                                       STRK20

The rules require only three, but five should be the minimum internal acceptance criterion and seven
the target. Every hash should be checked for successful execution and actual STRK20-pool involvement
before it enters strk20.json .


The final manifest should look structurally like:



  {
      "transactions": [
         "0x...",
         "0x...",
         "0x...",
         "0x...",
         "0x..."
      ],
      "contracts": [
         "0x..."
      ],
      "demo_video": "https://...",
      "demo_url": "https://..."
  }


That is the schema the sprint repository instructs judges and automated tooling to read.


Security, privacy, testing, and cost model
The privacy model belongs in the product, README and threat model because BackerZero's strongest story
depends on not overclaiming STRK20.




                                                      22
  Fact                          Public or private?                      Explanation

  Campaign creator's MVP                                                 Create Campaign is a
                                Public
  creation account                                                      normal Starknet transaction

  Campaign title / goal /
                                Public                                  Product state
  deadline

                                                                        Product deliberately exposes
  Total raised                  Public
                                                                        accountability

                                                                        Anonymizer actions and
  Contribution amount           Public at helper/application layer
                                                                        moved amounts are visible

                                                                        Transaction timing remains
  Contribution time             Public
                                                                        observable

                                Hidden from ordinary public
  Backer's account →                                                    Pool/relayer breaks the direct
                                observers, subject to correlation
  contribution link                                                     sender link
                                limits

  Receipt secret before
                                Private to holder                       Only commitment stored
  refund

  Receipt secret during         Becomes visible in claim                Required by this basic
  simple preimage refund        transaction                             capability design

  Refund amount                 Public                                  Open-note amount is plaintext

  Owner of resulting open                                               STRK20 output ownership
                                Hidden from public observers
  note                                                                  remains private

  Initial shielding address +
                                Public                                  Deposits are public edges
  amount

  Later pure shielded                                                   Note-to-note movement is
                                Private
  transfer parties/amount                                               encrypted

  Information from lawful       Available to authorized auditor for     STRK20's viewing-key auditing
  selective disclosure          selected user                           model

These boundaries follow STRK20's own documentation: every deposit is screened and publishes depositor/
token/amount; open-note token and filled amount remain visible; helper actions and amounts are visible;
and selective lawful disclosure can recover an individual user's viewing key without granting spending
authority. 4


The UI should therefore say:


         BackerZero hides who backed the campaign, not how much the campaign received.


It should not say:




                                                     23
       “Anonymous transaction,” “hidden amount,” “untraceable,” “zero-knowledge crowdfunding
       hides everything,” or “nobody can ever discover the contributor.”


STRK20 itself warns that distinctive amounts and rapid deposit→activity patterns weaken anonymity. A user
who publicly shields exactly 7.381 USDC and immediately makes a 7.381 USDC campaign contribution has
created a strong timing-and-amount correlation even though the direct on-chain account link is removed.
 11




That yields the highest-priority UX privacy warning:



  For stronger privacy:
  Shield funds before you need to contribute.
  Avoid distinctive deposit → contribution timing.


Threat model:


 Threat                Impact                   MVP mitigation                      Residual risk

 Direct call           Attacker drives           privacy_invoke checks
 bypasses privacy      accounting outside        get_caller_address() ==            Low after tests
 pool                  intended flow            pool

                                                                                    Contract still needs
 Fake                                           Require ERC-20 balance ≥ existing
                       Artificially increases                                       careful multi-
 contribution                                   liabilities + contribution before
                       raised total                                                 campaign
 without funds                                  credit
                                                                                    accounting

 Duplicate receipt     Accounting collision/
                                                Reject existing contribution key    Low
 commitment            double entitlement

                                                Mark refund consumed before
 Double refund         Escrow drain                                                 Low after tests
                                                approve

 Double creator
                       Escrow drain              claimed flag before interaction    Low after tests
 claim

                       Corrupt goal/
 Integer overflow                               Checked arithmetic everywhere       Low
                       liabilities

 Wrong token                                    Bind MVP contract to one
                       Liability mismatch                                           Low
 injected                                       immutable token

                                                                                    Donated excess
 Direct ERC-20                                  Never treat surplus balance as      remains stranded
                       Distorts raw balance
 donation                                       entitlement                         unless recovery
                                                                                    policy exists




                                                       24
  Threat               Impact                    MVP mitigation                          Residual risk

                       Backer cannot                                                     Bearer-secret
  Lost receipt                                   Download/export receipt + local
                       refund failed                                                     usability risk
  secret                                         redundant storage
                       campaign                                                          remains

  Stolen receipt                                 Keep secret client-side only; never     Important MVP
                       Attacker may claim
  secret                                         backend/analytics                       limitation

                       Refund could be
                                                 Document; keep demo funds
  Preimage copied      raced if                                                          Material design
                                                 small; investigate signature/
  during claim         authorization is not                                              risk
                                                 destination binding as P1
                       destination-bound

                                                 Open source, CSP, no analytics,
  Malicious            Secret or amount                                                  Users still trust
                                                 reproducible build, display calldata
  frontend             manipulation                                                      served frontend
                                                 summary

  Timing/amount        Weakens contributor       Privacy warning; encourage prior        Protocol-level
  correlation          anonymity                 shielding                               residual risk

                                                                                         Privacy, not
  Compromised                                    STRK20 design does not grant
                       Confidentiality loss                                              custody, can be
  auditor key                                    spending rights to viewing key
                                                                                         affected

                                                                                         Creator
  Creator steals       Intended                  Publicly state all-or-nothing model;    performance
  successful funds     crowdfunding rule         no milestone restrictions in MVP        remains off-chain
                                                                                         risk

  Creator cannot
  claim due secret     Funds stuck               Creator capability backup UI            Operational risk
  loss

                                                 Tiny-value sprint deployment, fuzz/
                       Loss/lock of real                                                 No formal audit
  Contract bug                                   state-machine tests, independent
                       funds                                                             during sprint
                                                 review

The most important unresolved security issue is the bearer-secret refund. STRK20's educational stateful
escrow example verifies a secret preimage and returns funds into the open note. The page explicitly says
this is an unofficial, unaudited illustration. BackerZero should therefore treat the simple secret design as a
sprint pattern, not as a production-ready financial primitive. 8


In particular, once a plain preimage appears in transaction calldata, anybody able to reuse that
authorization before final settlement may have a race opportunity unless the claim is cryptographically
bound to the intended output or otherwise made non-stealable. The P1 hardening investigation should
evaluate a fresh one-time Stark key/signature or other destination-binding mechanism that remains
compatible with Wallet API-generated open-note identifiers. Do not invent novel cryptography under
deadline pressure merely to erase this line from the threat model.




                                                      25
For the hackathon demo, use deliberately small-value funds and mark the simple capability design as
experimental / unaudited if that hardening has not been completed.


Contract invariants are more important than UI tests. Minimum Starknet Foundry coverage should
include:


  Invariant/test                                                                              Required

  Only configured STRK20 pool can enter privacy_invoke                                        ✓

  Zero-value contribution rejected                                                            ✓

  Contribution after deadline rejected                                                        ✓

  Unknown campaign rejected                                                                   ✓

  Duplicate receipt commitment rejected                                                       ✓

  Contribution cannot be credited unless contract balance covers new liability                ✓

  Direct token donations do not create contribution rights                                    ✓

   raised uses checked arithmetic                                                             ✓

   total_escrow uses checked arithmetic                                                       ✓

  Refund before deadline rejected                                                             ✓

  Refund on successful campaign rejected                                                      ✓

  Wrong refund secret rejected                                                                ✓

  Refund exactly once                                                                         ✓

  Creator claim before deadline rejected                                                      ✓

  Creator claim below goal rejected                                                           ✓

  Wrong creator capability rejected                                                           ✓

  Creator claim exactly once                                                                  ✓

  Returned open note has exact token / note ID / amount                                       ✓

  Effects happen before external approval                                                     ✓

  Multiple campaigns cannot spend one another's liabilities                                   ✓

  Total escrow equals sum of outstanding protocol obligations across randomized sequences     ✓

  Timestamp exactly at deadline follows chosen boundary consistently                          ✓

Add fuzz testing across campaign goal, contribution amount, number of contributions, deadlines and
randomized sequences of back/refund/claim operations. A particularly valuable stateful property is:




                                                    26
  For all reachable states:

  token_balance(contract) >= total_escrow


  and

  total_escrow ==
      sum(unclaimed successful/active contributions
            + refundable failed contributions)


Surplus donated tokens mean strict balance equality need not hold; liabilities must never exceed
available balance.


Cross-language cryptographic parity must also have a fixed test vector:



  Cairo Poseidon(receipt fields)
      ==
  TypeScript poseidon(receipt fields)


Current high-quality competitors explicitly test Cairo/JavaScript cryptographic parity because a mismatch
otherwise causes every real claim to fail despite both sides independently appearing “correct.” Veilcast, for
example, documents a shared claim-hash fixture on both sides.


Frontend tests:



  pnpm typecheck
  pnpm lint
  pnpm test
  pnpm build
  pnpm playwright test


Vitest should cover amount conversion, receipt serialization/deserialization, status derivation, Poseidon
fixture parity, action ordering, literal "OPEN" preservation and exact ${openNoteIds[0]} placeholder
construction. STRK20 specifically warns through its starter implementation that these placeholders are
strings substituted by the wallet and must not be hex-normalized.


Playwright should test the user interface with a mocked Wallet API, while the production release checklist
separately performs a manual end-to-end run with the actual privacy-capable wallet and mainnet pool. A
mock test is not evidence that the hackathon requirement has been met.


CI/CD pipeline:




                                                      27
  Pull request
    ├── contracts
    │        ├── scarb fmt --check
    │        ├── scarb build
    │        └── snforge test
    │
    ├── web
    │        ├── pnpm typecheck
    │        ├── pnpm lint
    │        ├── pnpm test
    │        └── pnpm build
    │
    └── security
             ├── secret scan
             └── strk20.json schema check


  Merge main
    ↓
  Vercel production deployment

  Mainnet contract deployment
    ↓
  MANUAL HUMAN-APPROVED RUNBOOK ONLY


There should be no automated production-contract deployment or mainnet financial action in
ordinary CI. Mainnet scripts may exist, but execution should be a protected manual action. That protects
both funds and the project's credibility when autonomous coding agents are involved.


The repository must ignore .env , private keys, viewing keys, receipt files and production signer material.
The frontend should never need a viewing key because the Wallet API route is specifically designed to keep
it inside the wallet. 3


Gas/cost model. A precise STRK amount cannot responsibly be quoted before the contract is compiled and
the exact transaction is simulated. Starknet fees depend on computation, L2 data and L1 data; the official
interface for estimating a transaction is starknet_estimateFee , and transaction fee limits/charges are
STRK-denominated.    12




Therefore the proper sprint cost model is:


 Operation             Relative expectation                   How to budget

 Contract              Highest/large one-time                 Estimate compiled class immediately
 declaration           deployment-class operation             before declaration

 Contract
                       One-time medium operation              Estimate exact constructor deployment
 deployment




                                                     28
  Operation            Relative expectation                     How to budget

  Create Campaign      Ordinary application storage writes      Estimate from final calldata

                       STRK20 pool transaction + deposit        Execute tiny first transaction and record
  Shield
                       mechanics                                 actual_fee

                       Private pool work + helper state          strk20PrepareInvoke first; record
  Back Privately
                       writes                                   actual receipt fee

                       Private pool + open-note + helper
  Claim Funding                                                 Same
                       writes/approve

                       Private pool + open-note + helper
  Claim Refund                                                  Same
                       writes/approve


Starknet's fee system is dynamic, so the project should maintain a small spreadsheet or docs/COSTS.md
populated with actual mainnet receipts, not guessed USD figures. The protocol documentation explicitly
exposes fee estimation and defines fee components as computation and data resources. 12


A useful engineering budget rule after the first successful mainnet private transaction is:



  remaining STRK safety reserve
      >= 10 × highest observed private-action fee
         + estimated declaration/deployment contingency


That is a conservative project-management recommendation rather than a protocol fee estimate.


The crowdfunding principal itself should remain tiny. The hackathon's Day-0 guidance explicitly says real
money is involved and builders should start with an amount they would not mind losing; qualifying
evidence does not require economically large transactions.


Delivery plan and judging package
There are only about two weeks between the current date, August 16, and the August 31 submission cutoff.
The correct strategy is to move the risky dependency—mainnet STRK20 execution—to the front of the
schedule, not the end. The official sprint documentation similarly tells builders to make their first mainnet
transaction before writing substantial application code.


  Date        Gate                            Exit criterion

              Product/architecture            This PRD accepted internally; BackerZero registry/repo ready;
  Aug 16
              freeze                          pool/token/wallet choice made

  Aug 16      Mainnet Day-0 proof             Real shield/pool transaction succeeds; hash archived

  Aug 17–                                     Campaign, Back, funding claim, refund implemented;
              Cairo core
  18                                          invariant/unit suite green




                                                        29
 Date         Gate                          Exit criterion

                                            Receipt and creator commitments match TypeScript/Cairo
 Aug 18       Crypto parity
                                            fixtures

                                            Exact Back + OpenNote claim action builders simulate
 Aug 19       STRK20 integration
                                            successfully

              First end-to-end chain        Tiny live or staged lifecycle proves helper funding + output
 Aug 20
              rehearsal                     mechanics

 Aug 20–                                    Class declared/deployed; address recorded; first custom Back
              Mainnet helper v0
 21                                         transaction succeeds

 Aug 21–                                    Create, Back, Claim Funding, Claim Refund function through
              Four-flow UI
 22                                         real action builders

                                            Fuzz/stateful tests; second engineer/agent adversarial review;
 Aug 23       Security day
                                            threat model updated

                                            At least five successful mainnet STRK20 hashes recorded
 Aug 24       Judge-eligibility gate
                                            and verified

                                            No P0 defects; no contract feature additions without release-
 Aug 25       MVP feature freeze
                                            owner override

 Aug 26–                                    Mobile/Ready flow, motion, failure states, evidence panel,
              Demo polish
 27                                         accessibility

                                            Milestones only if all core gates are green; otherwise skip
 Aug 27       Stretch decision
                                            completely

                                            Fresh user can follow README/demo without developer
 Aug 28       Clean-browser rehearsal
                                            intervention

                                            README, architecture, privacy, threat model, evidence and
 Aug 29       Documentation freeze
                                            demo script complete

 Aug 30       Final mainnet rehearsal       Successful campaign and failed-campaign lifecycle repeated

                                            Demo deployed, video uploaded, manifest verified; internal
 Aug 31       Submission
                                            cutoff 6:00 p.m. EDT

 Aug 31       Official deadline             7:59 p.m. EDT / 23:59 UTC    1



The one-day gap between the internal and official cutoff is intentionally not used for new features.


Judge deliverables should exceed the formal minimum. The rules require live demo + three-minute video
+ three qualifying mainnet hashes; BackerZero should package far more evidence around them.


Final judge packet:




                                                      30
  ✓ Public GitHub repository
  ✓ OSI-style open-source license
  ✓ Live production URL
  ✓ Three-minute video
  ✓ One verified BackerZero mainnet contract
  ✓ 5–7 successful STRK20-pool transaction hashes
  ✓ root strk20.json
  ✓ README.md
  ✓ docs/PRD.md
  ✓ docs/ARCHITECTURE.md
  ✓ docs/PRIVACY.md
  ✓ docs/THREAT_MODEL.md
  ✓ docs/MAINNET_EVIDENCE.md
  ✓ docs/DEMO_SCRIPT.md
  ✓ docs/RUNBOOK.md
  ✓ contract test instructions
  ✓ web test instructions
  ✓ reproducible build
  ✓ explicit “what is public / what is private” matrix


The top-level README should map directly to the scoring rubric:



  ## Why BackerZero
  ## Live Demo
  ## STRK20 Integration
  ## Mainnet Evidence
  ## What Is Private
  ## Architecture
  ## Contract Security Model
  ## Build and Test
  ## Contract Addresses
  ## Transaction Evidence
  ## Demo Video
  ## License


Since documentation and open-source quality are worth 15%, the repository itself is part of the product.
The rules also explicitly state that other teams depending on something a project publishes counts in its
favor, making a small reusable action-builder library potentially valuable after the MVP is done.


A good reusable artifact would be:



  import {
    buildStatefulEscrowDeposit,




                                                     31
    buildOpenNoteClaim,
  } from "@backerzero/strk20-actions";


It need not expose campaign logic; it could simply document typed Wallet API patterns for parking
shielded assets in a stateful helper and later returning them into an open note. That gives BackerZero
an OSS angle without adding protocol risk.


Recommended three-minute demo script:


0:00–0:18 — Problem


Show a normal transparent crowdfunding transfer.


        “On-chain crowdfunding makes support permanent public metadata. Your wallet tells the
        world which projects you funded, how much you funded them with, and what else you own.”


Do not spend more than 18 seconds on setup.


0:18–0:35 — Product


Open:



  BackerZero
  Public campaigns.
  Private backers.
  Trustless refunds.


Campaign:



  Open-source Privacy Wallet
  Goal: 10 USDC
  Deadline: ...
  Raised: 0 USDC


0:35–1:08 — First private back


Show shielded balance.


Backer A enters 6 USDC.


The stepper moves:




                                                   32
  Preparing proof
  ✓ Simulation passed
  ✓ Confirmed


Campaign instantly becomes:



  6 / 10 USDC


Then open the explorer/evidence pane.


Narration:


       “The contribution happened publicly. The backer didn't.”


Immediately qualify the statement:


       “The amount and campaign are visible. STRK20 hides the wallet link.”


That matches the protocol's actual privacy model.   6




1:08–1:33 — Goal reached


Backer B adds 5 USDC.


Animate:



  6 → 11 USDC

  GOAL REACHED


Show two contributions in campaign history without wallet addresses.


1:33–1:56 — Successful private claim


Advance/use a preconfigured finished campaign.


Creator clicks:



  Claim 11 USDC privately


Show creator shielded balance rise through an OpenNoteDeposit .




                                                        33
Narration:


       “BackerZero never has to unshield the campaign proceeds.”


The open-note amount is public while ownership remains shielded, which is the documented STRK20
model. 5


1:56–2:25 — Trustless failure


Open a campaign that expired below goal.


Import saved contribution receipt.



  Campaign failed
  Your refund: 3 USDC
  [ Claim Refund Privately ]


Show the shielded balance recover.


       “The creator cannot take a failed campaign's funds. The backer does not need the creator's
       permission to refund.”


That second outcome is essential. Without it, judges may interpret BackerZero as merely “private payment
to a campaign address.”


2:25–2:48 — Technical depth


One architecture frame:



  Shielded note
   → STRK20
   → privacy_invoke
   → stateful campaign escrow
   → OpenNoteDeposit
   → shielded claim/refund


Show contract address and five-to-seven mainnet hashes.


2:48–3:00 — Closing


       “Crowdfunding should prove the campaign was funded without permanently exposing
       everyone who funded it. BackerZero: public campaigns, private backers, trustless refunds.”


End on the actual product, not a slide deck.



                                                    34
The most important release criterion is that this video can be recorded without pretending anything
works. If Milestone Mode is 80% finished and the four core paths are 100% live, leave Milestone Mode out
of the recording.


Autonomous coding-agent project packet
The project should be structured so Agent Zero, AdaL, Codex-style agents, or human contributors all receive
the same operating contract. Agent Zero's official project emphasizes shell/file/browser tooling, isolated
project environments and multi-agent operation; AdaL supports terminal-native coding workflows,
persistent project context and AGENTS.md -style instructions. 13


The recommended repository is:



  backerzero/
  ├── AGENTS.md
  ├── README.md
  ├── LICENSE
  ├── strk20.json
  ├── .env.example
  ├── .gitignore
  ├── pnpm-workspace.yaml
  ├── package.json
  │
  ├── apps/
  │    └── web/
  │         ├── package.json
  │         ├── src/
  │         │    ├── app/
  │         │    │    ├── page.tsx
  │         │    │    ├── create/page.tsx
  │         │    │    └── campaign/[id]/page.tsx
  │         │    ├── components/
  │         │    │    ├── CampaignCard.tsx
  │         │    │    ├── CampaignProgress.tsx
  │         │    │    ├── BackDialog.tsx
  │         │    │    ├── ClaimFundingDialog.tsx
  │         │    │    ├── ClaimRefundDialog.tsx
  │         │    │    ├── PrivacyDisclosure.tsx
  │         │    │    ├── ReceiptCard.tsx
  │         │    │    └── TxStepper.tsx
  │         │    └── lib/
  │         │         ├── config.ts
  │         │         ├── receipt.ts
  │         │         ├── campaigns.ts
  │         │         ├── contracts/




                                                    35
│       │        │     └── backerzero.ts
│       │        └── strk20/
│       │              ├── wallet.ts
│       │              ├── actions.ts
│       │              └── capability.ts
│       └── tests/
│
├── contracts/
│   ├── Scarb.toml
│   ├── snfoundry.toml
│   ├── src/
│   │   ├── lib.cairo
│   │   ├── interface.cairo
│   │   ├── backerzero.cairo
│   │   └── hashing.cairo
│   └── tests/
│       ├── campaign_test.cairo
│       ├── refund_test.cairo
│       ├── claim_test.cairo
│       ├── accounting_test.cairo
│       └── fuzz_test.cairo
│
├── packages/
│   └── strk20-actions/
│       ├── src/index.ts
│       └── tests/
│
├── scripts/
│   ├── deploy-mainnet.sh
│   ├── verify-contract.ts
│   ├── seed-demo.ts
│   ├── verify-mainnet.ts
│   └── record-tx.ts
│
├── docs/
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── PRIVACY.md
│   ├── THREAT_MODEL.md
│   ├── COSTS.md
│   ├── MAINNET_EVIDENCE.md
│   ├── DEMO_SCRIPT.md
│   ├── RUNBOOK.md
│   └── ADR/
│       ├── 001-wallet-api.md
│       ├── 002-single-token.md




                                           36
  │         └── 003-stateful-helper.md
  │
  └── .github/
       └── workflows/
            ├── ci.yml
            └── mainnet-manual.yml


The codebase should bootstrap from STRK20's starter patterns rather than reimplement Wallet API
integration. The official starter demonstrates both the Cairo OpenNoteDeposit shape and the web-side
wallet action syntax needed here.


Recommended AGENTS.md :



  # BackerZero Agent Contract

  ## Mission

  Build the strongest possible submission for the STRK20 Private Sprint.

  Product:
  Public campaigns. Private backers. Trustless refunds.

  The only P0 user flows are:
  1. Create Campaign
  2. Back Privately
  3. Claim Funding
  4. Claim Refund

  The MVP is not complete until all four work against the intended
  Starknet mainnet deployment and at least five verified STRK20 pool
  transaction hashes are recorded.

  ## Non-negotiable architecture

  - Starknet mainnet final target.
  - STRK20 Wallet API for private user flows.
  - One stateful Cairo helper.
  - One fixed ERC-20 token for MVP.
  - The helper is bound to the configured STRK20 pool.
  - `privacy_invoke` MUST reject callers other than the pool.
  - Back parks funds and returns an empty OpenNoteDeposit span.
  - Funding claim and refund return OpenNoteDeposit.
  - Contract accounting tracks liabilities explicitly.
  - No public backer address is stored by campaign accounting.
  - Every secret hash uses an explicit domain separator.
  - Effects happen before external approvals/interactions.




                                                 37
## Privacy claims

Never claim:
- contribution amounts are hidden;
- contribution timing is hidden;
- deposits are private;
- creator campaign creation is anonymous;
- STRK20 prevents timing/amount correlation;
- the application is audited unless an actual audit occurred.

Approved wording:
"BackerZero hides the public link between the backer's wallet and
the contribution when funding from an already-shielded STRK20
balance. Campaign activity and amounts remain public."

## Safety

NEVER:
- commit a seed phrase, private key, viewing key, receipt secret,
  RPC secret, API secret, or deployer secret;
- expose secrets in logs/screenshots/test fixtures;
- broadcast a Starknet mainnet transaction autonomously;
- deploy a mainnet contract autonomously;
- spend user/project funds autonomously;
- place an unverified hash into strk20.json;
- copy competitor source code;
- disable a failing security test to make CI green.

Any mainnet broadcast or monetary operation is a HUMAN APPROVAL GATE.

The agent may:
- compile;
- test;
- simulate;
- run local mocks;
- prepare calldata;
- inspect mainnet read-only state;
- prepare deployment commands;
- prepare unsigned/approval-gated actions.

## Scope rule

Before five verified mainnet STRK20 hashes:
NO milestone mode.
NO cross-chain.
NO multi-token.
NO AI.



                                       38
  NO database unless proven essential.
  NO private subaccount dependency.
  NO visual redesign that delays protocol work.

  ## Definition of done for every task


  A task is complete only when:
  1. code is implemented;
  2. tests exist;
  3. relevant tests pass;
  4. typecheck/build pass where applicable;
  5. docs are updated;
  6. security/privacy implications are recorded;
  7. expected artifact exists at the documented path.

  "Works with a mock" is not equivalent to "works on mainnet."

  ## Source hierarchy

  When technical sources conflict, use:
  1. strk20.starknet.io
  2. strk20-by-example.org
  3. Starknet official docs
  4. starkware-libs repositories
  5. hackathon starter/registry repos
  6. other sources only when required

  Record important protocol decisions in docs/ADR.

  ## Release gates

  G0: repository builds
  G1: mainnet pool sanity action
  G2: contract invariant suite green
  G3: Wallet API actions simulate
  G4: complete tiny-value lifecycle
  G5: >=5 successful mainnet pool txs
  G6: production demo
  G7: 3-minute video + final strk20.json


That source hierarchy is appropriate because STRK20's Build documentation explicitly points developers and
AI agents at its main docs, agent-readable documentation and starter kit. 7


Autonomous task queue:




                                                   39
Task            Agent action                              Commands/tests      Expected artifact

                                                          pnpm
                Create monorepo, pin runtimes/
BZ-001                                                    install ;           lockfile, CI baseline,
                dependencies, install starter
Bootstrap                                                 pnpm build ;         .env.example
                Wallet API primitives
                                                          scarb build

BZ-002
                Record pool, chain, wallet API            read-only           docs/ADR/001-wallet-
Protocol
                version, chosen token                     validation          api.md
snapshot

                                                          pnpm test ;
BZ-003 Day-0    Build shield/balance UI; prepare
                                                          human-approved      first evidence entry
readiness       tiny mainnet sanity flow
                                                          live action

                Implement Campaign,
BZ-004 Cairo                                              scarb build ;
                Contribution, ops, events and                                 contracts/src/*
types                                                     snforge test
                storage

BZ-005 Back     Implement pool-only private
                                                          unit + fuzz tests   passing Back tests
accounting      contribution + liability invariant

                Implement secret commitment               wrong-secret/
BZ-006
                verification + one-time OpenNote          double-refund       refund suite green
Refund
                refund                                    tests

                                                          early/failed/
BZ-007          Implement successful campaign
                                                          double-claim        claim suite green
Creator claim   claim capability
                                                          tests

BZ-008
                Random campaign/action
Accounting                                                snforge test        invariant suite
                sequences
fuzz

BZ-009 Hash     Implement TS receipt hashing              Vitest + Cairo
                                                                              shared vector
parity          matching Cairo                            known fixture

BZ-010                                                    Vitest exact
                Build Back / Refund / Funding                                 packages/strk20-
STRK20                                                    calldata
                action arrays                                                 actions
actions                                                   assertions

BZ-011 Dry-     Exercise                                  read/simulate
run              strk20PrepareInvoke                      only until          simulation evidence
integration     against deployed helper                   approval

BZ-012 Core                                               component +
                Implement four user flows                                     usable Vercel preview
UI                                                        Playwright tests

BZ-013          Generate/download/import
                                                          browser tests       receipt workflow
Receipt UX      capability safely




                                                     40
 Task             Agent action                           Commands/tests      Expected artifact

 BZ-014           Add disclosure cards and timing        snapshot/
                                                                             accurate product copy
 Privacy UX       warning                                manual review

 BZ-015           Generate declaration/deploy
                                                         scarb build ;
 Mainnet          commands and constructor                                   docs/RUNBOOK.md
                                                         class hash check
 deploy prep      values

 BZ-016           Stop and request human
                                                         operator
 Mainnet          approval; execute only after                               contract address
                                                         runbook
 deploy           approval

 BZ-017           Prepare campaign lifecycle;            verify receipt/
                                                                             ≥5 valid hashes
 Evidence run     human approves each broadcast          status/pool

 BZ-018
                  Check all manifest txs and             read-only RPC
 Evidence                                                                    MAINNET_EVIDENCE.md
                  contract                               checks
 verifier

 BZ-019
                  Separate agent attempts                full CI +           THREAT_MODEL.md
 Security
                  invariant/capability breakage          adversarial tests   changes
 review

 BZ-020 Judge     Create rubric-mapped README            docs lint/link
                                                                             complete repo
 docs             and diagrams                           check

 BZ-021 Demo      Run clean-browser three-minute
                                                         timed rehearsal     DEMO_SCRIPT.md
 rehearsal        script

 BZ-022
                  Validate URL/video/hashes/             CI + manual
 Submission                                                                  final strk20.json
                  license/build                          checklist
 gate

The first commands an autonomous coding environment should execute are:



  git status
  node --version
  pnpm --version
  scarb --version
  snforge --version

  corepack enable
  pnpm install

  pnpm typecheck
  pnpm test
  pnpm build

  cd contracts




                                                    41
  scarb fmt --check
  scarb build
  snforge test


If the repository is bootstrapped directly from the current STRK20 starter kit, it should preserve the tested
Wallet API action behavior while replacing the demonstration echo helper with BackerZero's application-
specific contract. The starter kit itself says its echo helper is deliberately a no-op and meant to be replaced
by the builder's real action.


For Agent Zero specifically, run the project in an isolated workspace/container and expose only the
BackerZero project directory rather than broad home-directory access. Agent Zero's own project
emphasizes isolation and cautions around shell-capable autonomous operation. 14


For AdaL, put the mission and non-negotiables in AGENTS.md so every coding session inherits the same
constraints and does not rediscover product scope from chat history. AdaL's documentation supports
project-context/agent-oriented coding workflows. 15


With unconstrained parallelism, the ideal agent/human split is:


             Worker                    Ownership

             Cairo Security            Contract state, invariants, fuzzing, accounting

             STRK20 Integration        Wallet API, action arrays, mainnet simulation

             Product/UI                Campaign surfaces, transaction stepper, receipt UX

             Adversarial QA            Independent attempts to steal/double-spend/lock escrow

             Release                   Mainnet evidence, Vercel, manifest, video

             Documentation             README, privacy, architecture and judge-facing material

Parallel work should converge through one release owner. Autonomous agents should never independently
“fix” a failing integration by changing a security invariant or privacy promise.


The final strategic instruction for every agent should remain visible at the top of its task queue:


       Winning is not “most code.” Winning is a stateful STRK20 application that a judge can
       use on mainnet, understand in ten seconds, verify in three minutes, and inspect
       without finding a dishonest privacy claim.


BackerZero is unusually well positioned for that standard. STRK20's documented stateful escrow
mechanism already gives it the correct technical primitive; the current registry leaves meaningful
crowdfunding white space; and the four-flow lifecycle exercises substantially more STRK20 functionality
than a generic private-transfer interface. 2


The winning build should therefore remain uncompromisingly narrow through August 25:




                                                       42
one helper, one token, four flows, five-to-seven mainnet proofs, zero ambiguous privacy claims, and
one excellent three-minute story.



 1   https://strk20.starknet.io/hackathon
https://strk20.starknet.io/hackathon

 2    8   https://strk20-by-example.org/helpers/escrow
https://strk20-by-example.org/helpers/escrow

 3    7    9   https://strk20.starknet.io/build
https://strk20.starknet.io/build

 4    6   https://strk20-by-example.org/starknet-wallet-api/private-defi
https://strk20-by-example.org/starknet-wallet-api/private-defi

 5   10   https://strk20-by-example.org/helpers/privacy-invoke
https://strk20-by-example.org/helpers/privacy-invoke

11   https://strk20-by-example.org/compliance
https://strk20-by-example.org/compliance

12   https://docs.starknet.io/learn/protocol/fees
https://docs.starknet.io/learn/protocol/fees

13   14   https://github.com/agent0ai/agent-zero
https://github.com/agent0ai/agent-zero

15   https://docs.sylph.ai/
https://docs.sylph.ai/




                                                                 43
