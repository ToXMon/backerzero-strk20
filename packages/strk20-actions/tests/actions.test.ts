import { CairoCustomEnum, shortString } from "starknet";
import { describe, expect, it } from "vitest";
import {
  buildBackOperation,
  buildClaimFundingOperation,
  buildClaimRefundOperation,
  buildCreateCampaign,
  buildOpenNoteDeposit,
  buildRefundComputeAndInvoke,
} from "../src/actions.js";

const CHAIN_ID = "SN_LOCAL";
const HELPER = "0x1234567890abcdef1234567890abcdef1234567890abcdef";
const TOKEN = "0xabcdef";
const BACKER = "0x333";
const CREATOR_SECRET = "0xabc";

describe("BackerZero action builders", () => {
  it("builds create-campaign calldata", () => {
    const result = buildCreateCampaign({
      chainId: CHAIN_ID,
      helper: HELPER,
      goal: 1000n,
      deadline: 2000n,
      creatorSecret: CREATOR_SECRET,
    });
    expect(result.campaignId).toBeGreaterThan(0n);
    expect(result.calldata.length).toBe(3);
    expect(result.calldata[0]).toBe(1000n);
    expect(result.calldata[1]).toBe(2000n);
    expect(result.calldata[2]).toBe(result.creatorClaimCommitment);
  });

  it("builds a back operation", () => {
    const { operation, receiptCommitment, contributionAuth } = buildBackOperation(
      CHAIN_ID,
      HELPER,
      {
        campaignId: 1n,
        token: TOKEN,
        amount: 500n,
        receiptSecret: "0x777",
        destination: BACKER,
        identityBinding: "0x444",
        context: "0x555",
        seqNonce: 0n,
      },
    );
    expect(operation.kind).toBe("Back");
    if (operation.kind === "Back") {
      expect(operation.back.amount).toBe(500n);
      expect(operation.back.receiptCommitment).toBe(receiptCommitment.toString());
      expect(operation.back.contributionAuth).toBe(contributionAuth.toString());
    }
  });

  it("builds a claim-funding operation", () => {
    const { operation } = buildClaimFundingOperation(CHAIN_ID, HELPER, {
      campaignId: 1n,
      token: TOKEN,
      amount: 1000n,
      noteId: "0x999",
      creatorSecret: CREATOR_SECRET,
    });
    expect(operation.kind).toBe("ClaimFunding");
    if (operation.kind === "ClaimFunding") {
      expect(operation.claimFunding.amount).toBe(1000n);
    }
  });

  it("builds a claim-refund operation", () => {
    const { operation } = buildClaimRefundOperation(CHAIN_ID, HELPER, {
      campaignId: 1n,
      token: TOKEN,
      amount: 500n,
      destination: BACKER,
      noteId: "0x999",
      receiptSecret: "0x777",
      identityBinding: "0x444",
      context: "0x555",
      seqNonce: 0n,
    });
    expect(operation.kind).toBe("ClaimRefund");
    if (operation.kind === "ClaimRefund") {
      expect(operation.claimRefund.destination).toBe(BACKER);
    }
  });

  it("builds an OpenNoteDeposit", () => {
    const note = buildOpenNoteDeposit("0x999", TOKEN, 500n);
    expect(note.noteId).toBe("0x999");
    expect(note.token).toBe(TOKEN);
    expect(note.amount).toBe(500n);
  });

  it("builds refund ComputeAndInvoke additional data", () => {
    const refundOp = {
      campaignId: 1n,
      token: TOKEN,
      amount: 500n,
      destination: BACKER,
      noteId: "0x999",
      receiptSecret: "0x777",
      identityBinding: "0x444",
      context: "0x555",
      seqNonce: 0n,
    };

    const payload = buildRefundComputeAndInvoke(
      HELPER,
      "DAPP",
      0n,
      {
        to: TOKEN,
        selector: "transfer_to_caller",
        calldata: [500n],
      },
      {
        noteId: "0x999",
        token: TOKEN,
        collectPolicy: new CairoCustomEnum({ All: {} }),
      },
    );

    expect(payload.contractAddress).toBe(HELPER);
    expect(payload.computeAdditionalData).toEqual([
      BigInt(shortString.encodeShortString("DAPP")),
      0n,
    ]);
    expect(payload.invokeAdditionalData.length).toBeGreaterThan(0);
    // The placeholder identity commitment is sliced off.
    expect(payload.invokeAdditionalData[0]).not.toBe(0n);
  });
});
