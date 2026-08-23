import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createBzEnv, STRK, type BzEnv } from "./bz-harness.js";

describe("BackerZero Part C — real-proof privacy lifecycle", () => {
  let env: BzEnv;

  beforeAll(async () => {
    env = await createBzEnv();
  }, 600_000);

  afterAll(async () => {
    await env?.shutdown();
  });

  it("deposit + private transfer proven by the real prover", async () => {
    const { alice, bob, poolAddress, transfers, screenDepositor } = env;

    await alice.execute({
      contractAddress: STRK,
      entrypoint: "approve",
      calldata: [poolAddress, 100n, 0n],
    });

    const { callAndProof: bobReg } = await transfers.bob.build().register().execute();
    expect(bobReg.proof.data.length).toBeGreaterThan(0);
    await env.executeOutside(bobReg);

    screenDepositor.value = alice.address;
    const { callAndProof } = await transfers.alice
      .build({
        autoRegister: true,
        autoSetup: true,
        autoDiscover: { notes: "refresh", channels: "refresh" },
      })
      .with(STRK)
      .deposit({ amount: 100n })
      .transfer({ recipient: bob.address, amount: 50n })
      .surplusTo(alice.address)
      .execute();
    screenDepositor.value = undefined;

    // Real proof: non-empty proof bytes and proof facts from the prover service.
    expect(callAndProof.proof.data.length).toBeGreaterThan(1000);
    expect(callAndProof.proof.proofFacts.length).toBeGreaterThan(0);
    console.log(
      "[bz] proof bytes(base64 len):",
      callAndProof.proof.data.length,
      "proofFacts:",
      JSON.stringify(callAndProof.proof.proofFacts),
    );

    const receipt = await env.executeOutside(callAndProof);
    console.log("[bz] settled tx:", receipt.value.transaction_hash);

    await env.indexer.waitForBlock("http://127.0.0.1:5050");

    const { notes: bobNotes } = await transfers.bob.discoverNotes();
    const bobStrk = bobNotes.get(BigInt(STRK));
    expect(bobStrk).toBeDefined();
    expect(bobStrk!.length).toBe(1);
    expect(bobStrk![0].amount).toBe(50n);
  }, 1_800_000);
});
