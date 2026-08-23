use backerzero::hashing::BackerZeroHashing;
use backerzero::interfaces::{IBackerZeroDispatcher, IBackerZeroDispatcherTrait};
use backerzero::types::{
    BackOperation, BackerZeroOperation, CampaignStatus, ClaimFundingOperation, ClaimRefundOperation,
};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_block_timestamp,
    start_cheat_caller_address, start_cheat_chain_id,
};
use starknet::ContractAddress;
use super::mock_erc20::{IMockERC20Dispatcher, IMockERC20DispatcherTrait};

const CHAIN_ID: felt252 = 'SN_LOCAL';
const BASE_TIME: u64 = 1000;

fn deploy_token() -> IMockERC20Dispatcher {
    let contract_class = declare("MockERC20").unwrap().contract_class();
    let (address, _) = contract_class.deploy(@array![]).unwrap();
    IMockERC20Dispatcher { contract_address: address }
}

fn deploy_helper(pool: ContractAddress, token: ContractAddress) -> IBackerZeroDispatcher {
    let contract_class = declare("BackerZero").unwrap().contract_class();
    let mut calldata = array![pool.into(), token.into()];
    let (address, _) = contract_class.deploy(@calldata).unwrap();
    let dispatcher = IBackerZeroDispatcher { contract_address: address };

    start_cheat_chain_id(address, CHAIN_ID);
    start_cheat_block_timestamp(address, BASE_TIME);

    dispatcher
}

fn make_addr(value: felt252) -> ContractAddress {
    value.try_into().unwrap()
}

fn create_success_campaign(
    helper: IBackerZeroDispatcher, creator: ContractAddress, creator_secret: felt252,
) -> (u64, felt252) {
    let goal = 1000_u128;
    let deadline = BASE_TIME + 1000;
    let campaign_id = BackerZeroHashing::compute_campaign_id(
        CHAIN_ID, helper.contract_address, creator, goal, deadline,
    );
    let creator_claim_commitment = BackerZeroHashing::compute_creator_commitment(
        CHAIN_ID, helper.contract_address, campaign_id, creator_secret,
    );

    start_cheat_caller_address(helper.contract_address, creator);
    let id = helper.create_campaign(goal, deadline, creator_claim_commitment);
    assert(id == campaign_id, 'DETERMINISTIC_ID_MISMATCH');
    (id, creator_claim_commitment)
}

fn create_failed_campaign(
    helper: IBackerZeroDispatcher, creator: ContractAddress, creator_secret: felt252,
) -> (u64, felt252) {
    let goal = 1000_u128;
    let deadline = BASE_TIME + 1000;
    let campaign_id = BackerZeroHashing::compute_campaign_id(
        CHAIN_ID, helper.contract_address, creator, goal, deadline,
    );
    let creator_claim_commitment = BackerZeroHashing::compute_creator_commitment(
        CHAIN_ID, helper.contract_address, campaign_id, creator_secret,
    );

    start_cheat_caller_address(helper.contract_address, creator);
    let id = helper.create_campaign(goal, deadline, creator_claim_commitment);
    assert(id == campaign_id, 'DETERMINISTIC_ID_MISMATCH');
    (id, creator_claim_commitment)
}

fn back_operation(
    helper: IBackerZeroDispatcher,
    pool: ContractAddress,
    token: ContractAddress,
    campaign_id: u64,
    amount: u128,
    receipt_secret: felt252,
    destination: ContractAddress,
    identity_binding: felt252,
    context: felt252,
    seq_nonce: felt252,
) -> (felt252, felt252) {
    let receipt_commitment = BackerZeroHashing::compute_receipt_commitment(
        CHAIN_ID, helper.contract_address, campaign_id, receipt_secret,
    );
    let contribution_auth = BackerZeroHashing::compute_refund_id(
        CHAIN_ID,
        helper.contract_address,
        campaign_id,
        token,
        amount,
        destination,
        receipt_secret,
        identity_binding,
        context,
        seq_nonce,
    );

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::Back(
        BackOperation { campaign_id, token, amount, receipt_commitment, contribution_auth },
    );
    let outputs = helper.privacy_invoke(op);
    assert(outputs.len() == 0, 'BACK_NOT_EMPTY');

    (receipt_commitment, contribution_auth)
}

#[test]
fn test_create_campaign_ok() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let helper = deploy_helper(pool, token.contract_address);

    let goal = 100_u128;
    let deadline = BASE_TIME + 500;
    let campaign_id = BackerZeroHashing::compute_campaign_id(
        CHAIN_ID, helper.contract_address, creator, goal, deadline,
    );
    let commitment = BackerZeroHashing::compute_creator_commitment(
        CHAIN_ID, helper.contract_address, campaign_id, 0x1234,
    );

    start_cheat_caller_address(helper.contract_address, creator);
    let id = helper.create_campaign(goal, deadline, commitment);
    assert(id == campaign_id, 'CAMPAIGN_ID_MISMATCH');

    let campaign = helper.get_campaign(id);
    assert(campaign.creator == creator, 'CREATOR_MISMATCH');
    assert(campaign.goal == goal, 'GOAL_MISMATCH');
    assert(campaign.deadline == deadline, 'DEADLINE_MISMATCH');
    assert(campaign.raised == 0, 'RAISED_NOT_ZERO');
    assert(!campaign.claimed, 'CLAIMED_AT_CREATE');

    assert(helper.campaign_status(id) == CampaignStatus::Active, 'NOT_ACTIVE');
}

#[test]
#[should_panic(expected: ('ZERO_GOAL',))]
fn test_create_campaign_zero_goal_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let helper = deploy_helper(pool, token.contract_address);

    start_cheat_caller_address(helper.contract_address, creator);
    helper.create_campaign(0, BASE_TIME + 500, 0x1234);
}

#[test]
#[should_panic(expected: ('DEADLINE_NOT_FUTURE',))]
fn test_create_campaign_past_deadline_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let helper = deploy_helper(pool, token.contract_address);

    start_cheat_caller_address(helper.contract_address, creator);
    helper.create_campaign(100, BASE_TIME - 1, 0x1234);
}

#[test]
#[should_panic(expected: ('CAMPAIGN_ID_COLLISION',))]
fn test_create_campaign_id_collision_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let helper = deploy_helper(pool, token.contract_address);

    let goal = 100_u128;
    let deadline = BASE_TIME + 500;
    let commitment = 0x1234;

    start_cheat_caller_address(helper.contract_address, creator);
    helper.create_campaign(goal, deadline, commitment);

    start_cheat_caller_address(helper.contract_address, creator);
    helper.create_campaign(goal, deadline, commitment);
}

#[test]
fn test_status_transitions() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    assert(helper.campaign_status(campaign_id) == CampaignStatus::Active, 'S1_NOT_ACTIVE');

    token.mint(helper.contract_address, 1000);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 1000, 0x777, backer, 0x444, 0x555, 0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 1000);
    assert(helper.campaign_status(campaign_id) == CampaignStatus::Successful, 'S2_NOT_SUCCESSFUL');

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);
    assert(helper.campaign_status(campaign_id) == CampaignStatus::Successful, 'S3_NOT_SUCCESSFUL');
}

#[test]
fn test_status_failed() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_failed_campaign(helper, creator, 0xabc);

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);
    assert(helper.campaign_status(campaign_id) == CampaignStatus::Failed, 'NOT_FAILED');
}

#[test]
fn test_back_and_accounting() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    let amount = 500_u128;
    token.mint(helper.contract_address, amount.into());

    let identity = 0x444_felt252;
    let context = 0x555_felt252;
    let seq_nonce = 0_felt252;

    back_operation(
        helper,
        pool,
        token.contract_address,
        campaign_id,
        amount,
        0x777,
        backer,
        identity,
        context,
        seq_nonce,
    );

    let campaign = helper.get_campaign(campaign_id);
    assert(campaign.raised == amount, 'RAISED_MISMATCH');
    assert(campaign.contribution_count == 1, 'COUNT_MISMATCH');
    assert(helper.get_total_escrow() == amount, 'ESCROW_MISMATCH');
}

#[test]
#[should_panic(expected: ('CALLER_NOT_POOL',))]
fn test_back_non_pool_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let not_pool = make_addr(0x444);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    token.mint(helper.contract_address, 500);

    start_cheat_caller_address(helper.contract_address, not_pool);
    let op = BackerZeroOperation::Back(
        BackOperation {
            campaign_id,
            token: token.contract_address,
            amount: 500,
            receipt_commitment: 0x1234,
            contribution_auth: 0x5678,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
#[should_panic(expected: ('CAMPAIGN_CLOSED',))]
fn test_back_after_deadline_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    token.mint(helper.contract_address, 500);

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 500, 0x777, backer, 0x444, 0x555, 0,
    );
}

#[test]
#[should_panic(expected: ('WRONG_TOKEN',))]
fn test_back_wrong_token_fails() {
    let token = deploy_token();
    let other_token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    token.mint(helper.contract_address, 500);

    back_operation(
        helper,
        pool,
        other_token.contract_address,
        campaign_id,
        500,
        0x777,
        backer,
        0x444,
        0x555,
        0,
    );
}

#[test]
#[should_panic(expected: ('ZERO_AMOUNT',))]
fn test_back_zero_amount_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    token.mint(helper.contract_address, 1);

    back_operation(
        helper, pool, token.contract_address, campaign_id, 0, 0x777, backer, 0x444, 0x555, 0,
    );
}

#[test]
#[should_panic(expected: ('NOT_FUNDED',))]
fn test_back_not_funded_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    // No tokens minted to helper.
    back_operation(
        helper, pool, token.contract_address, campaign_id, 500, 0x777, backer, 0x444, 0x555, 0,
    );
}

#[test]
fn test_claim_funding() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let creator_secret = 0xabc_felt252;
    let (campaign_id, _) = create_success_campaign(helper, creator, creator_secret);

    let goal = 1000_u128;
    token.mint(helper.contract_address, goal.into());
    back_operation(
        helper, pool, token.contract_address, campaign_id, goal, 0x777, backer, 0x444, 0x555, 0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 1000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimFunding(
        ClaimFundingOperation {
            campaign_id,
            token: token.contract_address,
            amount: goal,
            note_id: 0x999,
            creator_secret,
        },
    );
    let outputs = helper.privacy_invoke(op);
    assert(outputs.len() == 1, 'NO_OUTPUT');
    let note = *outputs.at(0);
    assert(note.amount == goal, 'CLAIM_AMOUNT_MISMATCH');
    assert(note.token == token.contract_address, 'CLAIM_TOKEN_MISMATCH');
    assert(note.note_id == 0x999, 'NOTE_ID_MISMATCH');

    let campaign = helper.get_campaign(campaign_id);
    assert(campaign.claimed, 'NOT_CLAIMED');
    assert(helper.get_total_escrow() == 0, 'ESCROW_NOT_ZERO');

    let allowance = token.allowance(helper.contract_address, pool);
    assert(allowance == goal.into(), 'ALLOWANCE_MISMATCH');

    assert(helper.campaign_status(campaign_id) == CampaignStatus::Claimed, 'NOT_CLAIMED_STATUS');
}

#[test]
#[should_panic(expected: ('NOT_FINISHED',))]
fn test_claim_funding_before_deadline_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let creator_secret = 0xabc_felt252;
    let (campaign_id, _) = create_success_campaign(helper, creator, creator_secret);

    token.mint(helper.contract_address, 1000);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 1000, 0x777, backer, 0x444, 0x555, 0,
    );

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimFunding(
        ClaimFundingOperation {
            campaign_id,
            token: token.contract_address,
            amount: 1000,
            note_id: 0x999,
            creator_secret,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
#[should_panic(expected: ('GOAL_NOT_REACHED',))]
fn test_claim_funding_failed_campaign_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let creator_secret = 0xabc_felt252;
    let (campaign_id, _) = create_failed_campaign(helper, creator, creator_secret);

    token.mint(helper.contract_address, 500);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 500, 0x777, backer, 0x444, 0x555, 0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimFunding(
        ClaimFundingOperation {
            campaign_id, token: token.contract_address, amount: 500, note_id: 0x999, creator_secret,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
#[should_panic(expected: ('BAD_CREATOR_CAPABILITY',))]
fn test_claim_funding_wrong_secret_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    token.mint(helper.contract_address, 1000);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 1000, 0x777, backer, 0x444, 0x555, 0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 1000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimFunding(
        ClaimFundingOperation {
            campaign_id,
            token: token.contract_address,
            amount: 1000,
            note_id: 0x999,
            creator_secret: 0xbad,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
fn test_claim_refund() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_failed_campaign(helper, creator, 0xabc);

    let amount = 500_u128;
    token.mint(helper.contract_address, amount.into());
    let receipt_secret = 0x777_felt252;
    let identity = 0x444_felt252;
    let context = 0x555_felt252;
    let seq_nonce = 0_felt252;
    let destination = backer;
    back_operation(
        helper,
        pool,
        token.contract_address,
        campaign_id,
        amount,
        receipt_secret,
        destination,
        identity,
        context,
        seq_nonce,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimRefund(
        ClaimRefundOperation {
            campaign_id,
            token: token.contract_address,
            amount,
            destination,
            note_id: 0x999,
            receipt_secret,
            identity_binding: identity,
            context,
            seq_nonce,
        },
    );
    let outputs = helper.privacy_invoke(op);
    assert(outputs.len() == 1, 'NO_REFUND_OUTPUT');
    let note = *outputs.at(0);
    assert(note.amount == amount, 'REFUND_AMOUNT_MISMATCH');
    assert(note.token == token.contract_address, 'REFUND_TOKEN_MISMATCH');
    assert(note.note_id == 0x999, 'REFUND_NOTE_ID_MISMATCH');

    assert(helper.get_total_escrow() == 0, 'ESCROW_NOT_ZERO_AFTER_REFUND');
    let allowance = token.allowance(helper.contract_address, pool);
    assert(allowance == amount.into(), 'REFUND_ALLOWANCE_MISMATCH');
}

#[test]
#[should_panic(expected: ('REFUND_ID_MISMATCH',))]
fn test_claim_refund_wrong_identity_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_failed_campaign(helper, creator, 0xabc);

    let amount = 500_u128;
    token.mint(helper.contract_address, amount.into());
    let receipt_secret = 0x777_felt252;
    back_operation(
        helper,
        pool,
        token.contract_address,
        campaign_id,
        amount,
        receipt_secret,
        backer,
        0x444,
        0x555,
        0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimRefund(
        ClaimRefundOperation {
            campaign_id,
            token: token.contract_address,
            amount,
            destination: backer,
            note_id: 0x999,
            receipt_secret,
            identity_binding: 0x999, // wrong
            context: 0x555,
            seq_nonce: 0,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
#[should_panic(expected: ('REFUND_ID_MISMATCH',))]
fn test_claim_refund_wrong_destination_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let other = make_addr(0x666);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_failed_campaign(helper, creator, 0xabc);

    let amount = 500_u128;
    token.mint(helper.contract_address, amount.into());
    let receipt_secret = 0x777_felt252;
    back_operation(
        helper,
        pool,
        token.contract_address,
        campaign_id,
        amount,
        receipt_secret,
        backer,
        0x444,
        0x555,
        0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimRefund(
        ClaimRefundOperation {
            campaign_id,
            token: token.contract_address,
            amount,
            destination: other, // wrong
            note_id: 0x999,
            receipt_secret,
            identity_binding: 0x444,
            context: 0x555,
            seq_nonce: 0,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
#[should_panic(expected: ('ALREADY_REFUNDED',))]
fn test_double_refund_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_failed_campaign(helper, creator, 0xabc);

    let amount = 500_u128;
    token.mint(helper.contract_address, amount.into());
    let receipt_secret = 0x777_felt252;
    back_operation(
        helper,
        pool,
        token.contract_address,
        campaign_id,
        amount,
        receipt_secret,
        backer,
        0x444,
        0x555,
        0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 2000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimRefund(
        ClaimRefundOperation {
            campaign_id,
            token: token.contract_address,
            amount,
            destination: backer,
            note_id: 0x999,
            receipt_secret,
            identity_binding: 0x444,
            context: 0x555,
            seq_nonce: 0,
        },
    );
    helper.privacy_invoke(op);
    helper.privacy_invoke(op);
}

#[test]
#[should_panic(expected: ('NOT_FINISHED',))]
fn test_refund_before_deadline_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_failed_campaign(helper, creator, 0xabc);

    let amount = 500_u128;
    token.mint(helper.contract_address, amount.into());
    let receipt_secret = 0x777_felt252;
    back_operation(
        helper,
        pool,
        token.contract_address,
        campaign_id,
        amount,
        receipt_secret,
        backer,
        0x444,
        0x555,
        0,
    );

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimRefund(
        ClaimRefundOperation {
            campaign_id,
            token: token.contract_address,
            amount,
            destination: backer,
            note_id: 0x999,
            receipt_secret,
            identity_binding: 0x444,
            context: 0x555,
            seq_nonce: 0,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
#[should_panic(expected: ('CAMPAIGN_SUCCEEDED',))]
fn test_refund_successful_campaign_fails() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    token.mint(helper.contract_address, 1000);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 1000, 0x777, backer, 0x444, 0x555, 0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 1000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimRefund(
        ClaimRefundOperation {
            campaign_id,
            token: token.contract_address,
            amount: 1000,
            destination: backer,
            note_id: 0x999,
            receipt_secret: 0x777,
            identity_binding: 0x444,
            context: 0x555,
            seq_nonce: 0,
        },
    );
    helper.privacy_invoke(op);
}

#[test]
fn test_multiple_backers_accounting() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer1 = make_addr(0x333);
    let backer2 = make_addr(0x444);
    let helper = deploy_helper(pool, token.contract_address);
    let (campaign_id, _) = create_success_campaign(helper, creator, 0xabc);

    token.mint(helper.contract_address, 1200);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 700, 0x1, backer1, 0x11, 0x21, 0,
    );
    back_operation(
        helper, pool, token.contract_address, campaign_id, 500, 0x2, backer2, 0x12, 0x22, 0,
    );

    let campaign = helper.get_campaign(campaign_id);
    assert(campaign.raised == 1200, 'TOTAL_MISMATCH');
    assert(campaign.contribution_count == 2, 'COUNT_MISMATCH2');
    assert(helper.get_total_escrow() == 1200, 'ESCROW_MISMATCH2');
}

#[test]
fn test_overfunding_claim() {
    let token = deploy_token();
    let pool = make_addr(0x111);
    let creator = make_addr(0x222);
    let backer = make_addr(0x333);
    let helper = deploy_helper(pool, token.contract_address);
    let creator_secret = 0xabc_felt252;
    let (campaign_id, _) = create_success_campaign(helper, creator, creator_secret);

    token.mint(helper.contract_address, 1200);
    back_operation(
        helper, pool, token.contract_address, campaign_id, 1200, 0x777, backer, 0x444, 0x555, 0,
    );

    start_cheat_block_timestamp(helper.contract_address, BASE_TIME + 1000);

    start_cheat_caller_address(helper.contract_address, pool);
    let op = BackerZeroOperation::ClaimFunding(
        ClaimFundingOperation {
            campaign_id,
            token: token.contract_address,
            amount: 1200,
            note_id: 0x999,
            creator_secret,
        },
    );
    let outputs = helper.privacy_invoke(op);
    assert(*outputs.at(0).amount == 1200, 'OVERFUND_CLAIM_MISMATCH');
    assert(helper.get_total_escrow() == 0, 'ESCROW_NOT_ZERO_OVERFUND');
}
