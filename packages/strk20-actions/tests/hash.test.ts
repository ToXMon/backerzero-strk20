import { describe, expect, it } from "vitest";
import {
  computeCampaignId,
  computeCreatorCommitment,
  computeReceiptCommitment,
  computeRefundId,
  toFelt,
} from "../src/hash.js";

const CHAIN_ID = "SN_LOCAL";
const HELPER = "0x1234567890abcdef1234567890abcdef1234567890abcdef";
const CREATOR = "0x222";
const TOKEN = "0xabcdef";
const BACKER = "0x333";

describe("BackerZero hashing", () => {
  it("computes deterministic campaign ids", () => {
    const id1 = computeCampaignId(CHAIN_ID, HELPER, CREATOR, 1000n, 2000n);
    const id2 = computeCampaignId(CHAIN_ID, HELPER, CREATOR, 1000n, 2000n);
    expect(id1).toBe(id2);
    expect(id1 > 0n).toBe(true);
    expect(id1 < 1n << 64n).toBe(true);
  });

  it("produces distinct campaign ids for distinct inputs", () => {
    const id1 = computeCampaignId(CHAIN_ID, HELPER, CREATOR, 1000n, 2000n);
    const id2 = computeCampaignId(CHAIN_ID, HELPER, CREATOR, 1001n, 2000n);
    expect(id1).not.toBe(id2);
  });

  it("computes receipt commitments deterministically", () => {
    const c1 = computeReceiptCommitment(CHAIN_ID, HELPER, 1n, "0x777");
    const c2 = computeReceiptCommitment(CHAIN_ID, HELPER, 1n, "0x777");
    expect(c1).toBe(c2);
  });

  it("computes refund ids that bind amount, destination, identity and context", () => {
    const base = {
      chainId: CHAIN_ID,
      helper: HELPER,
      campaignId: 1n,
      token: TOKEN,
      amount: 500n,
      destination: BACKER,
      receiptSecret: "0x777",
      identityBinding: "0x444",
      context: "0x555",
      seqNonce: 0n,
    };
    const id1 = computeRefundId(
      base.chainId,
      base.helper,
      base.campaignId,
      base.token,
      base.amount,
      base.destination,
      base.receiptSecret,
      base.identityBinding,
      base.context,
      base.seqNonce,
    );
    const id2 = computeRefundId(
      base.chainId,
      base.helper,
      base.campaignId,
      base.token,
      base.amount,
      base.destination,
      base.receiptSecret,
      base.identityBinding,
      base.context,
      base.seqNonce,
    );
    expect(id1).toBe(id2);

    const idTampered = computeRefundId(
      base.chainId,
      base.helper,
      base.campaignId,
      base.token,
      base.amount,
      base.destination,
      base.receiptSecret,
      "0x999", // different identity
      base.context,
      base.seqNonce,
    );
    expect(idTampered).not.toBe(id1);
  });

  it("computes creator claim commitments", () => {
    const c1 = computeCreatorCommitment(CHAIN_ID, HELPER, 1n, "0xabc");
    const c2 = computeCreatorCommitment(CHAIN_ID, HELPER, 1n, "0xabc");
    expect(c1).toBe(c2);
  });

  it("converts string felts", () => {
    expect(toFelt("0x10")).toBe(16n);
    expect(toFelt("10")).toBe(10n);
    expect(toFelt(16n)).toBe(16n);
  });
});
