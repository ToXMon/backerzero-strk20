import { describe, expect, it } from "vitest";
import {
  computeCampaignId,
  computeCreatorCommitment,
  computeReceiptCommitment,
  computeRefundId,
} from "../src/hash.js";
import {
  EXPECTED_CAMPAIGN_ID,
  EXPECTED_CREATOR_COMMITMENT,
  EXPECTED_RECEIPT_COMMITMENT,
  EXPECTED_REFUND_ID,
  FIXTURE_AMOUNT,
  FIXTURE_CHAIN_ID,
  FIXTURE_CONTEXT,
  FIXTURE_CREATOR,
  FIXTURE_CREATOR_SECRET,
  FIXTURE_DEADLINE,
  FIXTURE_DESTINATION,
  FIXTURE_GOAL,
  FIXTURE_HELPER,
  FIXTURE_IDENTITY_BINDING,
  FIXTURE_RECEIPT_SECRET,
  FIXTURE_SEQ_NONCE,
  FIXTURE_TOKEN,
} from "../src/fixtures.js";

describe("shared fixtures agree with hashing", () => {
  it("campaign id fixture", () => {
    const id = computeCampaignId(
      FIXTURE_CHAIN_ID,
      FIXTURE_HELPER,
      FIXTURE_CREATOR,
      FIXTURE_GOAL,
      FIXTURE_DEADLINE,
    );
    expect(id).toBe(EXPECTED_CAMPAIGN_ID);
  });

  it("receipt commitment fixture", () => {
    const c = computeReceiptCommitment(
      FIXTURE_CHAIN_ID,
      FIXTURE_HELPER,
      EXPECTED_CAMPAIGN_ID,
      FIXTURE_RECEIPT_SECRET,
    );
    expect("0x" + c.toString(16)).toBe(EXPECTED_RECEIPT_COMMITMENT);
  });

  it("refund id fixture", () => {
    const r = computeRefundId(
      FIXTURE_CHAIN_ID,
      FIXTURE_HELPER,
      EXPECTED_CAMPAIGN_ID,
      FIXTURE_TOKEN,
      FIXTURE_AMOUNT,
      FIXTURE_DESTINATION,
      FIXTURE_RECEIPT_SECRET,
      FIXTURE_IDENTITY_BINDING,
      FIXTURE_CONTEXT,
      FIXTURE_SEQ_NONCE,
    );
    expect("0x" + r.toString(16)).toBe(EXPECTED_REFUND_ID);
  });

  it("creator commitment fixture", () => {
    const c = computeCreatorCommitment(
      FIXTURE_CHAIN_ID,
      FIXTURE_HELPER,
      EXPECTED_CAMPAIGN_ID,
      FIXTURE_CREATOR_SECRET,
    );
    expect("0x" + c.toString(16)).toBe(EXPECTED_CREATOR_COMMITMENT);
  });
});
