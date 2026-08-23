use backerzero::hashing::BackerZeroHashing;
use super::fixtures::{
    EXPECTED_CAMPAIGN_ID, EXPECTED_CREATOR_COMMITMENT, EXPECTED_RECEIPT_COMMITMENT, EXPECTED_REFUND_ID,
    FIXTURE_AMOUNT, FIXTURE_CHAIN_ID, FIXTURE_CONTEXT, FIXTURE_CREATOR_SECRET, FIXTURE_DEADLINE,
    FIXTURE_GOAL, FIXTURE_IDENTITY_BINDING, FIXTURE_RECEIPT_SECRET, FIXTURE_SEQ_NONCE,
    creator_address, destination_address, helper_address, token_address,
};

#[test]
fn test_fixture_campaign_id() {
    let id = BackerZeroHashing::compute_campaign_id(
        FIXTURE_CHAIN_ID,
        helper_address(),
        creator_address(),
        FIXTURE_GOAL,
        FIXTURE_DEADLINE,
    );
    assert(id == EXPECTED_CAMPAIGN_ID, 'CAMPAIGN_ID_FIXTURE_MISMATCH');
}

#[test]
fn test_fixture_receipt_commitment() {
    let c = BackerZeroHashing::compute_receipt_commitment(
        FIXTURE_CHAIN_ID, helper_address(), EXPECTED_CAMPAIGN_ID, FIXTURE_RECEIPT_SECRET,
    );
    assert(c == EXPECTED_RECEIPT_COMMITMENT, 'RECEIPT_FIXTURE_MISMATCH');
}

#[test]
fn test_fixture_refund_id() {
    let r = BackerZeroHashing::compute_refund_id(
        FIXTURE_CHAIN_ID,
        helper_address(),
        EXPECTED_CAMPAIGN_ID,
        token_address(),
        FIXTURE_AMOUNT,
        destination_address(),
        FIXTURE_RECEIPT_SECRET,
        FIXTURE_IDENTITY_BINDING,
        FIXTURE_CONTEXT,
        FIXTURE_SEQ_NONCE,
    );
    assert(r == EXPECTED_REFUND_ID, 'REFUND_ID_FIXTURE_MISMATCH');
}

#[test]
fn test_fixture_creator_commitment() {
    let c = BackerZeroHashing::compute_creator_commitment(
        FIXTURE_CHAIN_ID, helper_address(), EXPECTED_CAMPAIGN_ID, FIXTURE_CREATOR_SECRET,
    );
    assert(c == EXPECTED_CREATOR_COMMITMENT, 'CREATOR_COMMIT_FIXTURE_MISMATCH');
}
