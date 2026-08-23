export type Felt = string | bigint;
export type Address = string;

export enum CampaignStatus {
  Active = "Active",
  Successful = "Successful",
  Failed = "Failed",
  Claimed = "Claimed",
}

export interface Campaign {
  creator: Address;
  creatorClaimCommitment: Felt;
  goal: bigint;
  raised: bigint;
  refundedTotal: bigint;
  deadline: bigint;
  contributionCount: number;
  claimed: boolean;
}

export interface Contribution {
  amount: bigint;
  refunded: boolean;
  refundId: Felt;
}

export interface OpenNoteDeposit {
  noteId: Felt;
  token: Address;
  amount: bigint;
}

export interface BackOperation {
  campaignId: bigint;
  token: Address;
  amount: bigint;
  receiptCommitment: Felt;
  contributionAuth: Felt;
}

export interface ClaimFundingOperation {
  campaignId: bigint;
  token: Address;
  amount: bigint;
  noteId: Felt;
  creatorSecret: Felt;
}

export interface ClaimRefundOperation {
  campaignId: bigint;
  token: Address;
  amount: bigint;
  destination: Address;
  noteId: Felt;
  receiptSecret: Felt;
  identityBinding: Felt;
  context: Felt;
  seqNonce: Felt;
}

export type BackerZeroOperation =
  | { kind: "Back"; back: BackOperation }
  | { kind: "ClaimFunding"; claimFunding: ClaimFundingOperation }
  | { kind: "ClaimRefund"; claimRefund: ClaimRefundOperation };

export interface BackOptions {
  campaignId: bigint;
  token: Address;
  amount: bigint;
  receiptSecret: Felt;
  destination: Address;
  identityBinding: Felt;
  context: Felt;
  seqNonce: Felt;
}

export interface ClaimFundingOptions {
  campaignId: bigint;
  token: Address;
  amount: bigint;
  noteId: Felt;
  creatorSecret: Felt;
}

export interface ClaimRefundOptions {
  campaignId: bigint;
  token: Address;
  amount: bigint;
  destination: Address;
  noteId: Felt;
  receiptSecret: Felt;
  identityBinding: Felt;
  context: Felt;
  seqNonce: Felt;
}
