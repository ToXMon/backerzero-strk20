use starknet::ContractAddress;

/// Status is always derived from storage; no explicit finalize() is required.
#[derive(Copy, Drop, Serde, PartialEq, Debug)]
pub enum CampaignStatus {
    Active,
    Successful,
    Failed,
    Claimed,
}

#[derive(Copy, Drop, Serde, starknet::Store, Debug)]
pub struct Campaign {
    pub creator: ContractAddress,
    pub creator_claim_commitment: felt252,
    pub goal: u128,
    pub raised: u128,
    pub refunded_total: u128,
    pub deadline: u64,
    pub contribution_count: u32,
    pub claimed: bool,
}

/// Contribution state. The `refund_id` is bound at back time to the
/// intended refund identity, context, destination, amount and token so that
/// the refund path is not secret-only.
#[derive(Copy, Drop, Serde, starknet::Store, Debug)]
pub struct Contribution {
    pub amount: u128,
    pub refunded: bool,
    pub refund_id: felt252,
}

/// Returned from `privacy_invoke` to instruct the STRK20 pool how to
/// create the resulting shielded note. Matches the BUILD_PACKET shape.
#[derive(Copy, Drop, Serde, Debug)]
pub struct OpenNoteDeposit {
    pub note_id: felt252,
    pub token: ContractAddress,
    pub amount: u128,
}

/// Operations the helper recognizes inside `privacy_invoke`.
#[derive(Copy, Drop, Serde, Debug)]
pub enum BackerZeroOperation {
    Back: BackOperation,
    ClaimFunding: ClaimFundingOperation,
    ClaimRefund: ClaimRefundOperation,
}

#[derive(Copy, Drop, Serde, Debug)]
pub struct BackOperation {
    pub campaign_id: u64,
    pub token: ContractAddress,
    pub amount: u128,
    pub receipt_commitment: felt252,
    pub contribution_auth: felt252,
}

#[derive(Copy, Drop, Serde, Debug)]
pub struct ClaimFundingOperation {
    pub campaign_id: u64,
    pub token: ContractAddress,
    pub amount: u128,
    pub note_id: felt252,
    pub creator_secret: felt252,
}

#[derive(Copy, Drop, Serde, Debug)]
pub struct ClaimRefundOperation {
    pub campaign_id: u64,
    pub token: ContractAddress,
    pub amount: u128,
    pub destination: ContractAddress,
    pub note_id: felt252,
    pub receipt_secret: felt252,
    pub identity_binding: felt252,
    pub context: felt252,
    pub seq_nonce: felt252,
}
