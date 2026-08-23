import {
  computeCampaignId,
  computeReceiptCommitment,
  computeRefundId,
  computeCreatorCommitment,
} from "../src/hash.js";

const chainId = "SN_LOCAL";
const helper = "0x1234567890abcdef1234567890abcdef1234567890abcdef";
const creator = "0x222";
const token = "0xabcdef";
const destination = "0x333";
const goal = 1000n;
const deadline = 2000n;
const receiptSecret = "0x777";
const creatorSecret = "0xabc";
const identityBinding = "0x444";
const context = "0x555";
const seqNonce = 0n;

const campaignId = computeCampaignId(chainId, helper, creator, goal, deadline);
const receiptCommitment = computeReceiptCommitment(chainId, helper, campaignId, receiptSecret);
const refundId = computeRefundId(
  chainId,
  helper,
  campaignId,
  token,
  500n,
  destination,
  receiptSecret,
  identityBinding,
  context,
  seqNonce,
);
const creatorCommitment = computeCreatorCommitment(chainId, helper, campaignId, creatorSecret);

console.log(JSON.stringify({
  chainId,
  helper,
  creator,
  token,
  destination,
  goal: goal.toString(),
  deadline: deadline.toString(),
  receiptSecret,
  creatorSecret,
  identityBinding,
  context,
  seqNonce: seqNonce.toString(),
  campaignId: campaignId.toString(),
  receiptCommitment: "0x" + receiptCommitment.toString(16),
  refundId: "0x" + refundId.toString(16),
  creatorCommitment: "0x" + creatorCommitment.toString(16),
}, null, 2));
