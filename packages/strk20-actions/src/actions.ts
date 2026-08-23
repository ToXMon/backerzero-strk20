import { CallData, CairoCustomEnum, hash } from "starknet";
import type {
  Address,
  BackerZeroOperation,
  BackOperation,
  BackOptions,
  ClaimFundingOperation,
  ClaimFundingOptions,
  ClaimRefundOperation,
  ClaimRefundOptions,
  Felt,
  OpenNoteDeposit,
} from "./types.js";
import {
  computeCampaignId,
  computeCreatorCommitment,
  computeReceiptCommitment,
  computeRefundId,
  toAddress,
  toFelt,
} from "./hash.js";

export interface CreateCampaignInput {
  chainId: Felt;
  helper: Address;
  goal: bigint;
  deadline: bigint;
  creatorSecret: Felt;
}

export interface CreateCampaignResult {
  campaignId: bigint;
  creatorClaimCommitment: bigint;
  calldata: bigint[];
}

export function buildCreateCampaign(
  input: CreateCampaignInput,
): CreateCampaignResult {
  const campaignId = computeCampaignId(
    input.chainId,
    input.helper,
    input.helper, // creator address placeholder; caller supplies on-chain
    input.goal,
    input.deadline,
  );
  const creatorClaimCommitment = computeCreatorCommitment(
    input.chainId,
    input.helper,
    campaignId,
    input.creatorSecret,
  );
  const calldata = [
    input.goal,
    input.deadline,
    creatorClaimCommitment,
  ];
  return { campaignId, creatorClaimCommitment, calldata };
}

export interface BuildBackResult {
  campaignId: bigint;
  receiptCommitment: bigint;
  contributionAuth: bigint;
  operation: BackerZeroOperation;
}

export function buildBackOperation(
  chainId: Felt,
  helper: Address,
  options: BackOptions,
): BuildBackResult {
  const {
    campaignId,
    token,
    amount,
    destination,
    receiptSecret,
    identityBinding,
    context,
    seqNonce,
  } = options;

  const receiptCommitment = computeReceiptCommitment(
    chainId,
    helper,
    campaignId,
    receiptSecret,
  );
  const contributionAuth = computeRefundId(
    chainId,
    helper,
    campaignId,
    token,
    amount,
    destination,
    receiptSecret,
    identityBinding,
    context,
    seqNonce,
  );

  const back: BackOperation = {
    campaignId,
    token,
    amount,
    receiptCommitment: receiptCommitment.toString(),
    contributionAuth: contributionAuth.toString(),
  };

  return {
    campaignId,
    receiptCommitment,
    contributionAuth,
    operation: { kind: "Back", back },
  };
}

export interface BuildClaimFundingResult {
  campaignId: bigint;
  operation: BackerZeroOperation;
}

export function buildClaimFundingOperation(
  _chainId: Felt,
  _helper: Address,
  options: ClaimFundingOptions,
): BuildClaimFundingResult {
  const op: ClaimFundingOperation = {
    campaignId: options.campaignId,
    token: options.token,
    amount: options.amount,
    noteId: options.noteId,
    creatorSecret: options.creatorSecret,
  };
  return {
    campaignId: options.campaignId,
    operation: { kind: "ClaimFunding", claimFunding: op },
  };
}

export interface BuildClaimRefundResult {
  campaignId: bigint;
  operation: BackerZeroOperation;
}

export function buildClaimRefundOperation(
  _chainId: Felt,
  _helper: Address,
  options: ClaimRefundOptions,
): BuildClaimRefundResult {
  const op: ClaimRefundOperation = {
    campaignId: options.campaignId,
    token: options.token,
    amount: options.amount,
    destination: options.destination,
    noteId: options.noteId,
    receiptSecret: options.receiptSecret,
    identityBinding: options.identityBinding,
    context: options.context,
    seqNonce: options.seqNonce,
  };
  return {
    campaignId: options.campaignId,
    operation: { kind: "ClaimRefund", claimRefund: op },
  };
}

export function buildOpenNoteDeposit(
  noteId: Felt,
  token: Address,
  amount: bigint,
): OpenNoteDeposit {
  return { noteId: noteId.toString(), token, amount };
}

export interface Call {
  to: Address;
  selector: Felt;
  calldata: bigint[];
}

export interface NoteCollect {
  noteId: Felt;
  token: Address;
  collectPolicy: CairoCustomEnum;
}

export interface ComputeAndInvokePayload {
  contractAddress: Address;
  computeAdditionalData: bigint[];
  invokeAdditionalData: bigint[];
}

/**
 * Builds the additional data for a STRK20 `ComputeAndInvoke` refund.
 *
 * The pool invokes the `anonymizer` contract, which in turn calls
 * `privacy_invoke_with_computation(identity, calls, notes)`. The leading
 * identity commitment is omitted from the returned `invokeAdditionalData`
 * because the privacy pool prepends the derived identity key.
 *
 * `computeAdditionalData` is `[dappName, seqNonce]` and commits the context in
 * the SNARK proof; `invokeAdditionalData` is the ABI-encoded `[calls, notes]`.
 */
export function buildRefundComputeAndInvoke(
  anonymizerAddress: Address,
  dappName: Felt,
  seqNonce: Felt,
  call: Call,
  note: NoteCollect,
): ComputeAndInvokePayload {
  const noteWithEnum = {
    noteId: note.noteId,
    token: note.token,
    collectPolicy: note.collectPolicy,
  };

  const callWithBigintCalldata = {
    to: toAddress(call.to),
    selector: toFelt(call.selector),
    calldata: call.calldata,
  };

  // Prepend a zero identity commitment placeholder; it is sliced off because
  // the privacy pool supplies the real identity-bound commitment at execution time.
  const compiled = CallData.compile([
    0n,
    [callWithBigintCalldata],
    [noteWithEnum],
  ]);

  return {
    contractAddress: anonymizerAddress,
    computeAdditionalData: [toFelt(dappName), toFelt(seqNonce)],
    invokeAdditionalData: compiled
      .slice(1)
      .map((felt) => BigInt(felt.toString())),
  };
}

export function getSelector(name: string): bigint {
  return BigInt(hash.getSelectorFromName(name));
}

export {
  computeCampaignId,
  computeCreatorCommitment,
  computeReceiptCommitment,
  computeRefundId,
};
