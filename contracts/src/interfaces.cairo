use starknet::ContractAddress;

#[starknet::interface]
pub trait IBackerZero<TContractState> {
    fn create_campaign(
        ref self: TContractState,
        goal: u128,
        deadline: u64,
        creator_claim_commitment: felt252,
    ) -> u64;

    fn privacy_invoke(ref self: TContractState, operation: super::BackerZeroOperation) -> Span<super::OpenNoteDeposit>;

    fn get_campaign(self: @TContractState, campaign_id: u64) -> super::Campaign;
    fn get_contribution(self: @TContractState, campaign_id: u64, receipt_commitment: felt252) -> super::Contribution;
    fn get_total_escrow(self: @TContractState) -> u128;
    fn get_pool(self: @TContractState) -> ContractAddress;
    fn get_token(self: @TContractState) -> ContractAddress;
    fn campaign_status(self: @TContractState, campaign_id: u64) -> super::CampaignStatus;
}

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
}
