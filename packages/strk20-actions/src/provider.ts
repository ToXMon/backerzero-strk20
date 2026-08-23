import { Account, RpcProvider } from "starknet";

export interface PrivacyWallet {
  id: string;
  address: string;
  isPrivacyWallet: true;
}

export interface ProviderOptions {
  rpcUrl: string;
}

export function createRpcProvider(options: ProviderOptions): RpcProvider {
  return new RpcProvider({ nodeUrl: options.rpcUrl });
}

export function createAccount(
  provider: RpcProvider,
  address: string,
  privateKey: string,
): Account {
  return new Account({ provider, address, signer: privateKey });
}

/**
 * Detect a STRK20-capable privacy wallet in the browser environment.
 * Returns `null` when running in Node or when no wallet is available.
 */
export function detectPrivacyWallet(): PrivacyWallet | null {
  if (typeof window === "undefined") return null;
  const wallet = (window as any).starknet_privacy ?? (window as any).starknet;
  if (!wallet) return null;
  return {
    id: wallet.id ?? "starknet",
    address: wallet.selectedAddress ?? "",
    isPrivacyWallet: true,
  };
}

/**
 * Placeholder for querying a shielded balance. Real implementation should
 * call the privacy SDK discovery provider.
 */
export async function getShieldedBalance(
  _provider: RpcProvider,
  _poolAddress: string,
  _token: string,
  _viewingKey: string,
): Promise<bigint> {
  // This is intentionally left as a stub for clients to fill in with the
  // STRK20 privacy SDK discovery provider.
  return 0n;
}
