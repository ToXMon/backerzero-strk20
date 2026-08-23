use starknet::ContractAddress;

pub const FIXTURE_CHAIN_ID: felt252 = 'SN_LOCAL';
pub const FIXTURE_HELPER_ADDR: felt252 = 0x1234567890abcdef1234567890abcdef1234567890abcdef;
pub const FIXTURE_CREATOR_ADDR: felt252 = 0x222;
pub const FIXTURE_TOKEN_ADDR: felt252 = 0xabcdef;
pub const FIXTURE_DESTINATION_ADDR: felt252 = 0x333;
pub const FIXTURE_GOAL: u128 = 1000;
pub const FIXTURE_DEADLINE: u64 = 2000;
pub const FIXTURE_AMOUNT: u128 = 500;
pub const FIXTURE_RECEIPT_SECRET: felt252 = 0x777;
pub const FIXTURE_CREATOR_SECRET: felt252 = 0xabc;
pub const FIXTURE_IDENTITY_BINDING: felt252 = 0x444;
pub const FIXTURE_CONTEXT: felt252 = 0x555;
pub const FIXTURE_SEQ_NONCE: felt252 = 0;

pub const EXPECTED_CAMPAIGN_ID: u64 = 0x9ba17e794f47b24d;
pub const EXPECTED_RECEIPT_COMMITMENT: felt252 =
    0x2d21c182dfecef69ca8d17934b8d94e2c69a46618e8a8b7a6234ff1c7f8084;
pub const EXPECTED_REFUND_ID: felt252 =
    0x2c8bf473729ae054f36af5da24f7547d1137e430237e629f0451756e928b8c;
pub const EXPECTED_CREATOR_COMMITMENT: felt252 =
    0xe95fa2b93c66386656d0cd9b6badfcc4cbb2bb485499fbf4e4343f4139c98f;

pub fn helper_address() -> ContractAddress {
    FIXTURE_HELPER_ADDR.try_into().unwrap()
}

pub fn creator_address() -> ContractAddress {
    FIXTURE_CREATOR_ADDR.try_into().unwrap()
}

pub fn token_address() -> ContractAddress {
    FIXTURE_TOKEN_ADDR.try_into().unwrap()
}

pub fn destination_address() -> ContractAddress {
    FIXTURE_DESTINATION_ADDR.try_into().unwrap()
}
