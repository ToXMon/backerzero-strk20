/**
 * Shared BackerZero fixtures.
 *
 * These values are used by both the Cairo and TypeScript test suites so the
 * domain-separated Poseidon commitments produced by both implementations are
 * guaranteed to agree.
 */
export const FIXTURE_CHAIN_ID = "SN_LOCAL";
export const FIXTURE_HELPER =
  "0x1234567890abcdef1234567890abcdef1234567890abcdef";
export const FIXTURE_CREATOR = "0x222";
export const FIXTURE_TOKEN = "0xabcdef";
export const FIXTURE_DESTINATION = "0x333";

export const FIXTURE_GOAL = 1000n;
export const FIXTURE_DEADLINE = 2000n;
export const FIXTURE_AMOUNT = 500n;
export const FIXTURE_RECEIPT_SECRET = "0x777";
export const FIXTURE_CREATOR_SECRET = "0xabc";
export const FIXTURE_IDENTITY_BINDING = "0x444";
export const FIXTURE_CONTEXT = "0x555";
export const FIXTURE_SEQ_NONCE = 0n;

// Pre-computed commitments (must match the Cairo fixture test).
export const EXPECTED_CAMPAIGN_ID = 11214383606615487053n;
export const EXPECTED_RECEIPT_COMMITMENT =
  "0x2d21c182dfecef69ca8d17934b8d94e2c69a46618e8a8b7a6234ff1c7f8084";
export const EXPECTED_REFUND_ID =
  "0x2c8bf473729ae054f36af5da24f7547d1137e430237e629f0451756e928b8c";
export const EXPECTED_CREATOR_COMMITMENT =
  "0xe95fa2b93c66386656d0cd9b6badfcc4cbb2bb485499fbf4e4343f4139c98f";
