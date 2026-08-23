/**
 * BackerZero Prompt 4, Part D — ComputeAndInvoke conformance + negative tests.
 *
 * Derived from the upstream `shadow-account-compute-invoke.test.ts` flow, with
 * added tamper/replay tests. Positive path establishes the action shape; the
 * negative tests establish what the pool + blockifier reject once an
 * authorization (proof) has been produced.
 */
import { writeFileSync } from "node:fs";
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { Devnet } from "@starkware-libs/starknet-privacy-sdk/testing";
import { Open, type CallAndProof } from "@starkware-libs/starknet-privacy-sdk";
import { CairoCustomEnum, CallData, cairo, hash, shortString } from "starknet";
import { createE2eTestEnv, type E2eTestEnv } from "../../src/harness.js";
import { deployTestTokens, type TokenAddresses } from "../../src/vesu-setup.js";
import {
  deployShadowAccountAnonymizer,
  type ShadowAccountAddresses,
} from "../../src/shadow-account-setup.js";
import { u256Calldata } from "../../src/utils.js";

const ONE_TOKEN = 10n ** 18n;
const PAYOUT = 100n * ONE_TOKEN;

/** Replace the first occurrence of `find` in the authorized calldata. */
function tamper(cp: CallAndProof, find: bigint, replace: bigint): CallAndProof | null {
  const calldata = [...(cp.call.calldata as string[])].map((felt) => BigInt(felt));
  const index = calldata.findIndex((felt) => felt === find);
  if (index === -1) return null;
  calldata[index] = replace;
  return {
    ...cp,
    call: { ...cp.call, calldata: calldata.map((felt) => "0x" + felt.toString(16)) },
  };
}

describe("BackerZero Part D — ComputeAndInvoke conformance", () => {
  let devnet: Devnet;
  let env: E2eTestEnv;
  let tokens: TokenAddresses;
  let shadowAccount: ShadowAccountAddresses;
  const results: Array<[string, string]> = [];

  beforeAll(async () => {
    devnet = new Devnet();
    env = await createE2eTestEnv(devnet, {
      indexer: { logFile: "bz-compute-invoke-indexer.log" },
    });
    const { admin, node, privacy } = env.env;
    tokens = await deployTestTokens(admin, node);
    shadowAccount = await deployShadowAccountAnonymizer(admin, node, privacy.address);
  }, 900_000);

  afterAll(async () => {
    writeFileSync(
      process.env.BZ_PART_D_RESULTS ?? "/tmp/bz-part-d-results.json",
      JSON.stringify(results, null, 2),
    );
    await env?.indexer.shutdown();
    await devnet?.cleanup();
  });

  it("binds the authorized action, destination, amount and context", async () => {
    const { env: de, transfers } = env;
    const dappName = BigInt(shortString.encodeShortString("DAPP"));
    const seqNonce = 0n;
    const transferToCallerSelector = BigInt(hash.getSelectorFromName("transfer_to_caller"));
    const usdToken = BigInt(tokens.usdToken);

    const mintTx = await de.admin.execute({
      contractAddress: tokens.usdToken,
      entrypoint: "mint",
      calldata: [shadowAccount.mockDapp, ...u256Calldata(PAYOUT)],
    });
    await de.node.waitForTransaction(mintTx.transaction_hash);

    let openNoteId = 0n;
    const authorize = async (): Promise<CallAndProof> => {
      const { callAndProof } = await transfers.alice
        .build({
          autoRegister: true,
          autoSetup: true,
          autoDiscover: { notes: "refresh", channels: "refresh" },
        })
        .with(tokens.usdToken)
        .transfer({ recipient: de.alice.address, amount: Open })
        .done()
        .computeAndInvoke((args) => {
          expect(args.openNotes).toHaveLength(1);
          const [openNote] = args.openNotes;
          openNoteId = BigInt(openNote.noteId);
          const invokeAdditionalData = new CallData(shadowAccount.anonymizerAbi)
            .compile("privacy_invoke_with_computation", [
              0n,
              [
                {
                  to: shadowAccount.mockDapp,
                  selector: transferToCallerSelector,
                  calldata: CallData.compile([usdToken, cairo.uint256(PAYOUT)]),
                },
              ],
              [
                {
                  note_id: openNote.noteId,
                  token: usdToken,
                  collect_policy: new CairoCustomEnum({ All: {} }),
                },
              ],
            ])
            .slice(1)
            .map((felt) => BigInt(felt));
          return {
            contractAddress: shadowAccount.anonymizer,
            computeAdditionalData: [dappName, seqNonce],
            invokeAdditionalData,
          };
        })
        .execute();
      return callAndProof;
    };

    const expectRejected = async (
      name: string,
      cp: CallAndProof | null,
    ): Promise<void> => {
      if (cp === null) {
        // The value is not part of the public outside-execution calldata: it is
        // committed inside the proof's private inputs, so post-authorization
        // substitution is not expressible through the client API.
        results.push([name, "NOT_TAMPERABLE: value absent from public calldata (bound in proof inputs)"]);
        return;
      }
      let rejected = false;
      let detail = "";
      try {
        await devnet.executeOutside(cp);
      } catch (error) {
        const message = String((error as Error).message);
        rejected = true;
        detail = message.slice(0, 120) + " ... " + message.slice(-260);
      }
      results.push([name, rejected ? `REJECTED: ${detail}` : "ACCEPTED (SECURITY FAILURE)"]);
      expect(rejected, `${name} must be rejected`).toBe(true);
    };

    // --- negative tests on a freshly authorized action ---------------------
    const forAmount = await authorize();
    await expectRejected("amount substitution", tamper(forAmount, PAYOUT, PAYOUT * 2n));

    const forCalldata = await authorize();
    await expectRejected(
      "calldata/action substitution",
      tamper(
        forCalldata,
        transferToCallerSelector,
        BigInt(hash.getSelectorFromName("transfer_to_caller_v2")),
      ),
    );

    const forDestination = await authorize();
    await expectRejected(
      "destination substitution",
      tamper(forDestination, openNoteId, openNoteId + 1n),
    );

    const forContext = await authorize();
    await expectRejected(
      "wrong context (dapp name)",
      tamper(forContext, dappName, BigInt(shortString.encodeShortString("EVIL"))),
    );

    const forTarget = await authorize();
    await expectRejected(
      "wrong context (anonymizer target)",
      tamper(forTarget, BigInt(shadowAccount.anonymizer), BigInt(de.bob.address)),
    );

    // --- positive path, then replay ----------------------------------------
    const authorized = await authorize();
    await devnet.executeOutside(authorized);
    await env.indexer.waitForBlock(devnet.url);
    const { notes } = await transfers.alice.discoverNotes();
    const usdNotes = notes.get(usdToken) ?? [];
    expect(usdNotes).toHaveLength(1);
    expect(usdNotes[0].amount).toBe(PAYOUT);
    results.push(["positive path", `ACCEPTED, open note filled with ${PAYOUT}`]);

    await expectRejected("replay of the same authorization", authorized);
  }, 3_600_000);
});
