/**
 * BackerZero Prompt-4 verification harness.
 *
 * Unlike the upstream devnet harness (which uses ScreeningCallMockProofProvider),
 * this harness wires the SDK to the REAL upstream transaction prover
 * (starknet_proveTransaction) running as a container against a local devnet.
 *
 * Screening attestations are orthogonal to proving: in production the proving
 * service relays the off-chain screener's signature. Locally the pool is
 * deployed with the canonical *test* screener public key and the attestation is
 * signed with the matching disposable test key, while the STARK proof itself
 * comes from the real prover.
 */
import { readFileSync } from "fs";
import { join } from "path";
import {
  Account,
  Contract,
  ec,
  EDataAvailabilityMode,
  ETransactionVersion,
  RpcProvider,
  UniversalDetails,
  constants,
  hash,
  waitForTransactionOptions,
  OutsideExecutionVersion,
  type BlockIdentifier,
  type GetTransactionReceiptResponse,
  type OutsideExecutionOptions,
} from "starknet";
import {
  ProvingServiceProofProvider,
  IndexerDiscoveryProvider,
  createPrivateTransfers,
  type PrivateTransfersInterface,
  type CallAndProof,
  type Proof,
  type ProofInvocation,
} from "@starkware-libs/starknet-privacy-sdk";
import { IndexerClient } from "../../src/indexer-client.js";
import { repoRoot } from "../../src/utils.js";

const DEVNET_URL = process.env.BZ_DEVNET_URL ?? "http://127.0.0.1:5050";
const PROVER_URL = process.env.BZ_PROVER_URL ?? "http://127.0.0.1:3000";
const CHAIN_ID = constants.StarknetChainId.SN_SEPOLIA;

const CONTRACT_CLASS_PATH = join(
  repoRoot(),
  "target/dev/privacy_Privacy.contract_class.json",
);
const COMPILED_CONTRACT_PATH = join(
  repoRoot(),
  "target/dev/privacy_Privacy.compiled_contract_class.json",
);

const DEVNET_RESOURCE_BOUNDS = {
  l1_gas: { max_amount: 10_000_000_000n, max_price_per_unit: 1n },
  l2_gas: { max_amount: 10_000_000_000n, max_price_per_unit: 1n },
  l1_data_gas: { max_amount: 10_000_000_000n, max_price_per_unit: 1n },
};

// Canonical test screening keypair (upstream fixtures/screening-vectors.json).
// Disposable test material only — never used for anything with value.
const SCREENING_SIGNER_PRIVATE_KEY = "0xCAFEBABE";

// SNIP-12 (revision 1) screening attestation, matching
// packages/privacy/src/snip12.cairo and sdk/src/testing/screening-signer.ts.
const STARKNET_MESSAGE = shortStringToFelt("StarkNet Message");
const STARKNET_DOMAIN_TYPE_HASH =
  0x1ff2f602e42168014d405a94f75e8a93d640751d71d16311266e140d8b0a210n;
const DEPOSITOR_VALIDATION_TYPE_HASH =
  0x32d43b7372c9ea8a35daf12b02c5f6f74837910ecbaf2a3ecfe71fec901913dn;
const DOMAIN_NAME = shortStringToFelt("Screening");
const DOMAIN_VERSION = 2n;
const DOMAIN_REVISION = 1n;

function shortStringToFelt(text: string): bigint {
  return BigInt("0x" + Buffer.from(text, "ascii").toString("hex"));
}

export const SCREENING_SIGNER_PUBLIC_KEY = BigInt(
  ec.starkCurve.getStarkKey(SCREENING_SIGNER_PRIVATE_KEY),
);

export function signScreeningAttestation(
  chainId: bigint,
  depositor: bigint,
  issuedAt: number,
): { issued_at: number; sig_r: string; sig_s: string } {
  const domainHash = ec.starkCurve.poseidonHashMany([
    STARKNET_DOMAIN_TYPE_HASH,
    DOMAIN_NAME,
    DOMAIN_VERSION,
    chainId,
    DOMAIN_REVISION,
  ]);
  const messageStructHash = ec.starkCurve.poseidonHashMany([
    DEPOSITOR_VALIDATION_TYPE_HASH,
    depositor,
    BigInt(issuedAt),
  ]);
  const messageHash = ec.starkCurve.poseidonHashMany([
    STARKNET_MESSAGE,
    domainHash,
    SCREENING_SIGNER_PUBLIC_KEY,
    messageStructHash,
  ]);
  const signature = ec.starkCurve.sign(
    "0x" + messageHash.toString(16),
    SCREENING_SIGNER_PRIVATE_KEY,
  );
  return {
    issued_at: issuedAt,
    sig_r: "0x" + signature.r.toString(16),
    sig_s: "0x" + signature.s.toString(16),
  };
}

export const STRK = "0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d";

async function rpc<T>(method: string, params: unknown = []): Promise<T> {
  const resp = await fetch(DEVNET_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
  });
  const body = (await resp.json()) as { result?: T; error?: unknown };
  if (body.error) throw new Error(`${method}: ${JSON.stringify(body.error)}`);
  return body.result as T;
}

export async function createBlocks(count: number): Promise<void> {
  for (let i = 0; i < count; i++) await rpc("devnet_createBlock");
}

/**
 * Real proving provider + screening attestation for deposits.
 *
 * The proof comes from the real prover service; only the screener signature is
 * produced locally (that service is not part of the released runtime row).
 */
export class RealProofScreeningProvider extends ProvingServiceProofProvider {
  constructor(
    private readonly node: RpcProvider,
    private readonly depositorProvider: () => string | undefined,
    url: string = PROVER_URL,
    options: Record<string, unknown> = {},
  ) {
    super(url, CHAIN_ID, options);
  }

  async prove(
    invocation: ProofInvocation,
    blockIdentifier?: BlockIdentifier,
  ): Promise<Proof> {
    const proof = await super.prove(
      invocation,
      blockIdentifier as never,
    );
    const depositor = this.depositorProvider();
    if (depositor === undefined) return proof;
    const chainId = await this.node.getChainId();
    const block = await this.node.getBlock("latest");
    const signature = signScreeningAttestation(
      BigInt(chainId),
      BigInt(depositor),
      Number(block.timestamp),
    );
    return { ...proof, additionalData: { signature } };
  }
}

export interface BzEnv {
  node: RpcProvider;
  alice: Account;
  bob: Account;
  admin: Account;
  poolAddress: string;
  indexer: IndexerClient;
  transfers: { alice: PrivateTransfersInterface; bob: PrivateTransfersInterface };
  /** Set to an address to attach a screening attestation to the next proof. */
  screenDepositor: { value: string | undefined };
  executeOutside: (cp: CallAndProof) => Promise<GetTransactionReceiptResponse>;
  shutdown: () => Promise<void>;
}

function wrapAccount(account: Account, nonces: Map<string, number>): Account {
  const address = account.address;
  return new Proxy(account, {
    get: (target, prop, receiver) => {
      const value = Reflect.get(target, prop, receiver);
      if (
        prop === "declare" ||
        prop === "deploy" ||
        prop === "deployContract" ||
        prop === "execute"
      ) {
        return async (
          payload: unknown,
          detail?: UniversalDetails & waitForTransactionOptions,
        ) => {
          const nonce = nonces.get(address) ?? 0;
          nonces.set(address, nonce + 1);
          return (value as (...args: unknown[]) => unknown).call(target, payload, {
            nonce,
            resourceBounds: DEVNET_RESOURCE_BOUNDS,
            tip: 0,
            skipValidate: true,
            retryInterval: 50,
            feeDataAvailabilityMode: EDataAvailabilityMode.L2,
            nonceDataAvailabilityMode: EDataAvailabilityMode.L2,
            version: ETransactionVersion.V3,
            ...detail,
          });
        };
      }
      return value;
    },
  });
}

export async function createBzEnv(): Promise<BzEnv> {
  const node = new RpcProvider({
    nodeUrl: DEVNET_URL,
    transactionRetryIntervalFallback: 50,
    batch: 0,
    chainId: CHAIN_ID,
  });

  const raw = await rpc<
    Array<{ address: string; private_key: string; public_key: string }>
  >("devnet_getPredeployedAccounts");
  const nonces = new Map<string, number>();
  const toAccount = (entry: { address: string; private_key: string }) =>
    wrapAccount(
      new Account({
        provider: node,
        address: entry.address,
        signer: new Uint8Array(
          entry.private_key
            .replace("0x", "")
            .match(/.{1,2}/g)!
            .map((byte) => parseInt(byte, 16)),
        ),
        cairoVersion: "1",
      }),
      nonces,
    );
  const alice = toAccount(raw[0]);
  const bob = toAccount(raw[1]);
  const admin = toAccount(raw[2]);

  const contractClass = JSON.parse(readFileSync(CONTRACT_CLASS_PATH, "utf8"));
  const compiledContract = JSON.parse(readFileSync(COMPILED_CONTRACT_PATH, "utf8"));
  const declareResponse = await admin.declare({
    contract: contractClass,
    casm: compiledContract,
    compiledClassHash: hash.computeCompiledClassHash(compiledContract),
  });
  const classHash = declareResponse.class_hash;
  const deployResponse = await admin.deployContract(
    {
      classHash,
      constructorCalldata: [
        admin.address, // governance_admin
        "0x1", // auditor_public_key (dummy)
        "0x" + SCREENING_SIGNER_PUBLIC_KEY.toString(16), // screener_public_key
        "450", // proof_validity_blocks
      ],
      salt: "0x0",
    },
    { retryInterval: 100 },
  );
  const poolAddress = deployResponse.contract_address;
  await createBlocks(10);

  const indexer = await IndexerClient.spawn({
    wsUrl: DEVNET_URL.replace(/^http/, "ws") + "/ws",
    rpcUrl: DEVNET_URL,
  });
  await indexer.waitUntilReady(DEVNET_URL);

  const screenDepositor: { value: string | undefined } = { value: undefined };
  const provider = (account: Account, viewingKey: string) =>
    createPrivateTransfers({
      account,
      viewingKeyProvider: { getViewingKey: async () => BigInt(viewingKey) },
      provingProvider: new RealProofScreeningProvider(
        node,
        () => screenDepositor.value,
        PROVER_URL,
        {
          nodeUrl: DEVNET_URL,
          poolAddress,
          // The prover runs under QEMU emulation here, so proving is slow.
          requestTimeoutMs: Number(process.env.BZ_PROVE_TIMEOUT_MS ?? 7_200_000),
          retry: { maxRetries: 0 },
        },
      ),
      discoveryProvider: new IndexerDiscoveryProvider(indexer.apiUrl, poolAddress),
      poolContractAddress: poolAddress,
    });

  const transfers = {
    alice: provider(alice, "0xA11CE"),
    bob: provider(bob, "0xB0B"),
  };

  const executeOutside = async (
    cp: CallAndProof,
  ): Promise<GetTransactionReceiptResponse> => {
    const nowSeconds = Math.floor(Date.now() / 1000);
    const callOptions: OutsideExecutionOptions = {
      caller: admin.address,
      execute_after: nowSeconds - 3600,
      execute_before: nowSeconds + 3600,
    };
    // The proof embeds a base block; the blockifier requires
    // proof_block <= current_block - STORED_BLOCK_HASH_BUFFER (10).
    await createBlocks(10);
    const outsideTransaction = await admin.getOutsideTransaction(
      callOptions,
      cp.call,
      OutsideExecutionVersion.V2,
    );
    const response = await admin.executeFromOutside(outsideTransaction, {
      proofFacts: cp.proof.proofFacts,
      proof: cp.proof.data,
    });
    const receipt = await node.waitForTransaction(response.transaction_hash);
    if (!receipt.isSuccess()) {
      const reason = (receipt as { revert_reason?: string }).revert_reason ?? "unknown";
      throw new Error(`executeOutside reverted: ${reason}`);
    }
    return receipt;
  };

  return {
    node,
    alice,
    bob,
    admin,
    poolAddress,
    indexer,
    transfers,
    screenDepositor,
    executeOutside,
    shutdown: async () => {
      await indexer.shutdown();
    },
  };
}

export { SCREENING_SIGNER_PRIVATE_KEY, Contract };
