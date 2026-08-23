/**
 * BackerZero Prompt-4 Part C — smallest *real* privacy lifecycle on public
 * Starknet Sepolia, using the official transaction prover (no mocks).
 *
 * Copy into the pinned upstream checkout at
 * `e2e/tests/integration/bz-sepolia-real-proof.test.ts` (see ./README.md).
 *
 * Evidence produced: storage-proof retrieval (inside the prover), action
 * preparation, real proof generation, testnet submission, settlement, and
 * note observation through the supported discovery path.
 */
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { writeFileSync } from "fs";
import {
  createBzSepoliaEnv,
  sendWithEstimate,
  STRK,
  type BzSepoliaEnv,
} from "./bz-sepolia-harness.js";

const DEPOSIT_AMOUNT = BigInt(process.env.BZ_DEPOSIT_AMOUNT ?? "1000000000000000"); // 0.001 STRK
const EVIDENCE_FILE =
  process.env.BZ_EVIDENCE_FILE ?? "/tmp/bz-sepolia-real-proof.json";

describe("BackerZero real-proof lifecycle (Sepolia)", () => {
  let env: BzSepoliaEnv;

  beforeAll(async () => {
    env = await createBzSepoliaEnv();
  }, 3_600_000);

  afterAll(async () => {
    await env?.shutdown();
  });

  it("generates a real proof, settles on Sepolia, and yields a discoverable note", async () => {
    const aliceAddress = BigInt(env.alice.address);
    const viewingKey = BigInt(process.env.BZ_VIEWING_KEY ?? "0xA11CE");

    const approve = await sendWithEstimate(env.alice, {
      contractAddress: STRK,
      entrypoint: "approve",
      calldata: [env.poolAddress, DEPOSIT_AMOUNT.toString(), "0"],
    });
    await env.node.waitForTransaction(approve.transaction_hash);

    const provingBlockId = await env.provingBlockId();
    env.screenDepositor.value = env.alice.address;

    const startedAt = Date.now();
    const { callAndProof } = await env.transfers
      .build({
        autoRegister: true,
        autoSetup: true,
        autoDiscover: { notes: "refresh", channels: "refresh" },
      })
      .with(STRK, (t) => t.deposit({ amount: DEPOSIT_AMOUNT }))
      .surplusTo(env.alice.address)
      .execute({ provingBlockId });
    const provingMs = Date.now() - startedAt;

    const receipt = await env.executeOutside(callAndProof);

    const evidence = {
      rpcUrl: process.env.BZ_RPC_URL,
      txRpcUrl: process.env.BZ_TX_RPC_URL,
      poolAddress: env.poolAddress,
      approveTx: approve.transaction_hash,
      provingBlockId,
      provingMs,
      proofFactsLength: callAndProof.proof.proofFacts.length,
      proofDataLength: callAndProof.proof.data.length,
      callContract: callAndProof.call.contractAddress,
      callEntrypoint: callAndProof.call.entrypoint,
      settlementTx: (receipt as { transaction_hash?: string }).transaction_hash,
    };

    expect(evidence.proofDataLength).toBeGreaterThan(0);
    expect(receipt.isSuccess()).toBe(true);

    const deadline = Date.now() + 600_000;
    let notes = await env.discovery.discoverNotes(aliceAddress, viewingKey);
    while (notes.notes.size === 0) {
      if (Date.now() > deadline) throw new Error("indexer discovery timeout");
      await new Promise((r) => setTimeout(r, 5000));
      notes = await env.discovery.discoverNotes(aliceAddress, viewingKey);
    }

    writeFileSync(
      EVIDENCE_FILE,
      JSON.stringify({ ...evidence, discoveredNotes: notes.notes.size }, null, 2),
    );
    expect(notes.notes.size).toBeGreaterThan(0);
  }, 7_200_000);
});
