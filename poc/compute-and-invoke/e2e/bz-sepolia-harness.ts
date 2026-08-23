/**
 * BackerZero Prompt-4 verification harness — public Starknet Sepolia.
 *
 * Copy into the pinned upstream checkout at
 * `e2e/tests/integration/bz-sepolia-harness.ts` (see ./README.md).
 *
 * Differences from the devnet harness:
 *  - RPC is a hosted, storage-proof-capable Sepolia node (starknet_getStorageProof).
 *  - Transactions go through a second Sepolia endpoint, because the
 *    storage-proof endpoint rejects large request bodies (DECLARE payloads).
 *  - Accounts are disposable Sepolia accounts read at runtime from a file
 *    outside the repository (never committed, never logged).
 *  - No devnet_createBlock: the proving block is `latest - 10`, matching the
 *    blockifier's STORED_BLOCK_HASH_BUFFER requirement.
 *  - Fees are estimated on-chain instead of using devnet resource bounds.
 */
import { readFileSync } from "fs";
import { join } from "path";
import {
  Account,
  RpcProvider,
  constants,
  ec,
  hash,
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

export const RPC_URL =
  process.env.BZ_RPC_URL ?? "https://starknet-sepolia-rpc.publicnode.com";
export const WS_URL =
  process.env.BZ_WS_URL ?? "wss://starknet-sepolia-rpc.publicnode.com";
/**
 * Transaction RPC. The storage-proof endpoint used for proving rejects large
 * request bodies (DECLARE payloads), so transactions go through a second
 * endpoint on the same chain.
 */
export const TX_RPC_URL =
  process.env.BZ_TX_RPC_URL ?? "https://api.cartridge.gg/x/starknet/sepolia";
const PROVER_URL = process.env.BZ_PROVER_URL ?? "http://127.0.0.1:3000";
const CHAIN_ID = constants.StarknetChainId.SN_SEPOLIA;
const ACCOUNTS_FILE =
  process.env.BZ_ACCOUNTS_FILE ??
  join(process.env.HOME ?? "/root", ".bz-sepolia/accounts.json");

export const STRK =
  "0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d";

const CONTRACT_CLASS_PATH = join(
  repoRoot(),
  process.env.BZ_SIERRA_PATH ??
    "target/release/privacy_Privacy.contract_class.json",
);
const COMPILED_CONTRACT_PATH = join(
  repoRoot(),
  process.env.BZ_CASM_PATH ??
    "target/release/privacy_Privacy.compiled_contract_class.json",
);

// Canonical upstream *test* screening keypair. Disposable test material only.
const SCREENING_SIGNER_PRIVATE_KEY = "0xCAFEBABE";
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

/** Real prover + locally signed screening attestation (the screener is not part of the runtime row). */
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
    const proof = await super.prove(invocation, blockIdentifier as never);
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

interface SncastAccountEntry {
  address: string;
  private_key: string;
  public_key: string;
  class_hash?: string;
  deployed?: boolean;
  type?: string;
}

function loadAccounts(node: RpcProvider): { admin: Account; alice: Account } {
  const file = JSON.parse(readFileSync(ACCOUNTS_FILE, "utf8")) as Record<
    string,
    Record<string, SncastAccountEntry>
  >;
  const sepolia = file["alpha-sepolia"] ?? file["sepolia"];
  if (!sepolia) throw new Error("no sepolia accounts in accounts file");
  const pick = (name: string) => {
    const entry = sepolia[name];
    if (!entry) throw new Error(`account ${name} missing`);
    return new Account({
      provider: node,
      address: entry.address,
      signer: entry.private_key,
      cairoVersion: "1",
    });
  };
  return {
    admin: pick(process.env.BZ_ADMIN_ACCOUNT ?? "bzsepolia"),
    alice: pick(process.env.BZ_ALICE_ACCOUNT ?? "bzalice"),
  };
}

export interface BzSepoliaEnv {
  node: RpcProvider;
  admin: Account;
  alice: Account;
  poolAddress: string;
  indexer: IndexerClient;
  discovery: IndexerDiscoveryProvider;
  transfers: PrivateTransfersInterface;
  screenDepositor: { value: string | undefined };
  provingBlockId: () => Promise<number>;
  executeOutside: (cp: CallAndProof) => Promise<GetTransactionReceiptResponse>;
  shutdown: () => Promise<void>;
}

export async function sendWithEstimate(
  account: Account,
  call: { contractAddress: string; entrypoint: string; calldata: string[] },
) {
  const fee = await account.estimateInvokeFee(call);
  return account.execute(call, { tip: 0n, resourceBounds: fee.resourceBounds });
}

export async function createBzSepoliaEnv(options?: {
  poolAddress?: string;
}): Promise<BzSepoliaEnv> {
  const node = new RpcProvider({ nodeUrl: TX_RPC_URL, chainId: CHAIN_ID });
  const { admin, alice } = loadAccounts(node);

  let poolAddress = options?.poolAddress ?? process.env.BZ_POOL_ADDRESS ?? "";
  if (!poolAddress) {
    const contractClass = JSON.parse(readFileSync(CONTRACT_CLASS_PATH, "utf8"));
    const compiledContract = JSON.parse(
      readFileSync(COMPILED_CONTRACT_PATH, "utf8"),
    );
    const classHash = hash.computeContractClassHash(contractClass);
    let declared = true;
    try {
      await node.getClass(classHash);
    } catch {
      declared = false;
    }
    console.log(`[bz] pool class ${classHash} declared=${declared}`);
    if (!declared) {
      const payload = {
        contract: contractClass,
        casm: compiledContract,
        compiledClassHash: hash.computeCompiledClassHash(compiledContract),
      };
      const fee = await admin.estimateDeclareFee(payload);
      console.log("[bz] declare fee (overall):", fee.overall_fee.toString());
      const declareTx = await admin.declare(payload, {
        tip: 0n,
        resourceBounds: fee.resourceBounds,
      });
      console.log("[bz] declare tx:", declareTx.transaction_hash);
      await node.waitForTransaction(declareTx.transaction_hash);
    }

    const salt = `0x${Date.now().toString(16)}`;
    const constructorCalldata = [
      admin.address,
      "0x1",
      "0x" + SCREENING_SIGNER_PUBLIC_KEY.toString(16),
      "450",
    ];
    const deployFee = await admin.estimateDeployFee({
      classHash,
      constructorCalldata,
      salt,
    });
    const deployResult = await admin.deployContract(
      { classHash, constructorCalldata, salt },
      { tip: 0n, resourceBounds: deployFee.resourceBounds },
    );
    console.log("[bz] pool deploy tx:", deployResult.transaction_hash);
    const receipt = await node.waitForTransaction(
      deployResult.transaction_hash,
    );
    if (!receipt.isSuccess()) throw new Error("pool deployment failed");
    poolAddress = deployResult.contract_address;
  }
  console.log("[bz] pool address:", poolAddress);

  const indexer = await IndexerClient.spawn({
    wsUrl: WS_URL,
    rpcUrl: RPC_URL,
    logFile: process.env.BZ_INDEXER_LOG,
    env: { POOL_ADDRESS: poolAddress },
  });

  const screenDepositor: { value: string | undefined } = { value: undefined };
  const discovery = new IndexerDiscoveryProvider(indexer.apiUrl, poolAddress);
  const transfers = createPrivateTransfers({
    account: alice,
    viewingKeyProvider: {
      getViewingKey: async () =>
        BigInt(process.env.BZ_VIEWING_KEY ?? "0xA11CE"),
    },
    provingProvider: new RealProofScreeningProvider(
      node,
      () => screenDepositor.value,
      PROVER_URL,
      {
        nodeUrl: RPC_URL,
        poolAddress,
        requestTimeoutMs: Number(process.env.BZ_PROVE_TIMEOUT_MS ?? 7_200_000),
        retry: { maxRetries: 0 },
      },
    ),
    discoveryProvider: discovery,
    poolContractAddress: poolAddress,
  });

  // Two-sided constraint: the blockifier's STORED_BLOCK_HASH_BUFFER requires a
  // block at least 10 back, while hosted nodes only retain storage proofs for a
  // short window (~16 blocks on the endpoint used here).
  const provingBlockId = async () =>
    (await node.getBlockNumber()) - Number(process.env.BZ_PROVING_BLOCK_LAG ?? 11);

  const executeOutside = async (cp: CallAndProof) => {
    const nowSeconds = Math.floor(Date.now() / 1000);
    const callOptions: OutsideExecutionOptions = {
      caller: admin.address,
      execute_after: nowSeconds - 3600,
      execute_before: nowSeconds + 3600,
    };
    const outsideTransaction = await alice.getOutsideTransaction(
      callOptions,
      cp.call,
      OutsideExecutionVersion.V2,
    );
    const response = await admin.executeFromOutside(outsideTransaction, {
      tip: 0n,
      proofFacts: cp.proof.proofFacts,
      proof: cp.proof.data,
    });
    console.log("[bz] executeFromOutside tx:", response.transaction_hash);
    const receipt = await node.waitForTransaction(response.transaction_hash);
    if (!receipt.isSuccess()) {
      const reason =
        (receipt as { revert_reason?: string }).revert_reason ?? "unknown";
      throw new Error(`executeOutside reverted: ${reason}`);
    }
    return receipt;
  };

  return {
    node,
    admin,
    alice,
    poolAddress,
    indexer,
    discovery,
    transfers,
    screenDepositor,
    provingBlockId,
    executeOutside,
    shutdown: async () => {
      await indexer.shutdown();
    },
  };
}
