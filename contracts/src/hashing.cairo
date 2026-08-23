use core::poseidon::poseidon_hash_span;
use starknet::ContractAddress;

pub const HASH_DOMAIN_BACKERZERO_CAMPAIGN_V1: felt252 = 'BACKERZERO_CAMPAIGN_V1';
pub const HASH_DOMAIN_BACKERZERO_RECEIPT_V1: felt252 = 'BACKERZERO_RECEIPT_V1';
pub const HASH_DOMAIN_BACKERZERO_REFUND_ID_V1: felt252 = 'BACKERZERO_REFUND_ID_V1';
pub const HASH_DOMAIN_BACKERZERO_CLAIM_AUTH_V1: felt252 = 'BACKERZERO_CLAIM_AUTH_V1';

#[generate_trait]
pub impl BackerZeroHashingImpl of BackerZeroHashing {
    fn compute_campaign_id(
        chain_id: felt252,
        helper: ContractAddress,
        creator: ContractAddress,
        goal: u128,
        deadline: u64,
    ) -> u64 {
        let mut inputs: Array<felt252> = array![
            HASH_DOMAIN_BACKERZERO_CAMPAIGN_V1,
            chain_id,
            helper.into(),
            creator.into(),
            goal.into(),
            deadline.into(),
        ];
        let felt = poseidon_hash_span(inputs.span());
        let felt_u256: u256 = felt.into();
        let low: u64 = (felt_u256.low % 0x10000000000000000).try_into().unwrap();
        if low == 0 {
            1
        } else {
            low
        }
    }

    fn compute_receipt_commitment(
        chain_id: felt252,
        helper: ContractAddress,
        campaign_id: u64,
        receipt_secret: felt252,
    ) -> felt252 {
        let mut inputs: Array<felt252> = array![
            HASH_DOMAIN_BACKERZERO_RECEIPT_V1,
            chain_id,
            helper.into(),
            campaign_id.into(),
            receipt_secret,
        ];
        poseidon_hash_span(inputs.span())
    }

    fn compute_refund_id(
        chain_id: felt252,
        helper: ContractAddress,
        campaign_id: u64,
        token: ContractAddress,
        amount: u128,
        destination: ContractAddress,
        receipt_secret: felt252,
        identity_binding: felt252,
        context: felt252,
        seq_nonce: felt252,
    ) -> felt252 {
        let mut inputs: Array<felt252> = array![
            HASH_DOMAIN_BACKERZERO_REFUND_ID_V1,
            chain_id,
            helper.into(),
            campaign_id.into(),
            token.into(),
            amount.into(),
            destination.into(),
            receipt_secret,
            identity_binding,
            context,
            seq_nonce,
        ];
        poseidon_hash_span(inputs.span())
    }

    fn compute_creator_commitment(
        chain_id: felt252,
        helper: ContractAddress,
        campaign_id: u64,
        creator_secret: felt252,
    ) -> felt252 {
        let mut inputs: Array<felt252> = array![
            HASH_DOMAIN_BACKERZERO_CLAIM_AUTH_V1,
            chain_id,
            helper.into(),
            campaign_id.into(),
            creator_secret,
        ];
        poseidon_hash_span(inputs.span())
    }
}
