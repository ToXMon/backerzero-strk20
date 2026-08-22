import { Account, RpcProvider, Contract } from "starknet";

function stringify(value: unknown): string {
  return JSON.stringify(value, (_, item) => (typeof item === "bigint" ? item.toString() : item), 2);
}

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is required; no bearer-secret or default fallback is permitted`);
  return value;
}

const rpcUrl = required("RPC_URL");
const contractAddress = required("CONTRACT_ADDRESS");
const accountAddress = required("ACCOUNT_ADDRESS");
const privateKey = required("ACCOUNT_PRIVATE_KEY");

const provider = new RpcProvider({ nodeUrl: rpcUrl });
const account = new Account({ provider, address: accountAddress, signer: privateKey });

const abi = [
  {
    name: "get_balance",
    type: "function",
    inputs: [],
    outputs: [{ name: "balance", type: "felt252" }],
    state_mutability: "view",
  },
  {
    name: "increase_balance",
    type: "function",
    inputs: [{ name: "amount", type: "felt252" }],
    outputs: [],
    state_mutability: "external",
  },
];

const contract = new Contract({ abi, address: contractAddress, providerOrAccount: account });
const before = await contract.get_balance();
console.log(
  stringify({
    rpcUrl,
    chainId: await provider.getChainId(),
    accountAddress,
    contractAddress,
    balanceBefore: before,
  }),
);

if (process.env.INCREASE_AMOUNT) {
  const amount = process.env.INCREASE_AMOUNT;
  const invocation = await account.execute({ contractAddress, entrypoint: "increase_balance", calldata: [amount] });
  const receipt = await provider.waitForTransaction(invocation.transaction_hash);
  const after = await contract.get_balance();
  console.log(
    stringify({
      transactionHash: invocation.transaction_hash,
      receipt,
      balanceAfter: after,
    }),
  );
}
