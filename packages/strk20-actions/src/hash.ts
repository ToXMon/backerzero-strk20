import { ec, shortString } from "starknet";
import type { Address, Felt } from "./types.js";

export const HASH_DOMAIN_BACKERZERO_CAMPAIGN_V1 = BigInt(
  shortString.encodeShortString("BACKERZERO_CAMPAIGN_V1"),
);
export const HASH_DOMAIN_BACKERZERO_RECEIPT_V1 = BigInt(
  shortString.encodeShortString("BACKERZERO_RECEIPT_V1"),
);
export const HASH_DOMAIN_BACKERZERO_REFUND_ID_V1 = BigInt(
  shortString.encodeShortString("BACKERZERO_REFUND_ID_V1"),
);
export const HASH_DOMAIN_BACKERZERO_CLAIM_AUTH_V1 = BigInt(
  shortString.encodeShortString("BACKERZERO_CLAIM_AUTH_V1"),
);

const U64_MASK = (1n << 64n) - 1n;

export function toFelt(value: Felt): bigint {
  if (typeof value === "bigint") return value;
  if (value.startsWith("0x")) return BigInt(value);
  if (/^\d+$/.test(value)) return BigInt(value);
  return BigInt(shortString.encodeShortString(value));
}

export function toAddress(value: Address): bigint {
  return toFelt(value);
}

function poseidon(inputs: bigint[]): bigint {
  return ec.starkCurve.poseidonHashMany(inputs);
}

export function computeCampaignId(
  chainId: Felt,
  helper: Address,
  creator: Address,
  goal: bigint,
  deadline: bigint,
): bigint {
  const felt = poseidon([
    HASH_DOMAIN_BACKERZERO_CAMPAIGN_V1,
    toFelt(chainId),
    toAddress(helper),
    toAddress(creator),
    goal,
    deadline,
  ]);
  let low = felt & U64_MASK;
  if (low === 0n) low = 1n;
  return low;
}

export function computeReceiptCommitment(
  chainId: Felt,
  helper: Address,
  campaignId: bigint,
  receiptSecret: Felt,
): bigint {
  return poseidon([
    HASH_DOMAIN_BACKERZERO_RECEIPT_V1,
    toFelt(chainId),
    toAddress(helper),
    campaignId,
    toFelt(receiptSecret),
  ]);
}

export function computeRefundId(
  chainId: Felt,
  helper: Address,
  campaignId: bigint,
  token: Address,
  amount: bigint,
  destination: Address,
  receiptSecret: Felt,
  identityBinding: Felt,
  context: Felt,
  seqNonce: Felt,
): bigint {
  return poseidon([
    HASH_DOMAIN_BACKERZERO_REFUND_ID_V1,
    toFelt(chainId),
    toAddress(helper),
    campaignId,
    toAddress(token),
    amount,
    toAddress(destination),
    toFelt(receiptSecret),
    toFelt(identityBinding),
    toFelt(context),
    toFelt(seqNonce),
  ]);
}

export function computeCreatorCommitment(
  chainId: Felt,
  helper: Address,
  campaignId: bigint,
  creatorSecret: Felt,
): bigint {
  return poseidon([
    HASH_DOMAIN_BACKERZERO_CLAIM_AUTH_V1,
    toFelt(chainId),
    toAddress(helper),
    campaignId,
    toFelt(creatorSecret),
  ]);
}
