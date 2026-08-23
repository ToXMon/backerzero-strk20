#[starknet::contract]
pub mod BackerZero {
    use core::num::traits::{CheckedAdd, CheckedSub};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, get_contract_address, get_tx_info,
    };
    use super::super::hashing::BackerZeroHashing;
    use super::super::interfaces::{IBackerZero, IERC20Dispatcher, IERC20DispatcherTrait};
    use super::super::types::{
        BackOperation, BackerZeroOperation, Campaign, CampaignStatus, ClaimFundingOperation,
        ClaimRefundOperation, Contribution, OpenNoteDeposit,
    };

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CampaignCreated: CampaignCreated,
        Backed: Backed,
        FundingClaimed: FundingClaimed,
        Refunded: Refunded,
    }

    #[derive(Drop, starknet::Event)]
    struct CampaignCreated {
        campaign_id: u64,
        creator: ContractAddress,
        goal: u128,
        deadline: u64,
        token: ContractAddress,
        creator_claim_commitment: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Backed {
        campaign_id: u64,
        amount: u128,
        raised: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct FundingClaimed {
        campaign_id: u64,
        amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct Refunded {
        campaign_id: u64,
        amount: u128,
    }

    #[storage]
    struct Storage {
        pool: ContractAddress,
        token: ContractAddress,
        total_escrow: u128,
        campaigns: Map<u64, Campaign>,
        contributions: Map<(u64, felt252), Contribution>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, pool: ContractAddress, token: ContractAddress) {
        assert(pool.into() != 0, 'ZERO_POOL');
        assert(token.into() != 0, 'ZERO_TOKEN');
        self.pool.write(pool);
        self.token.write(token);
        self.total_escrow.write(0);
    }

    #[abi(embed_v0)]
    impl IBackerZeroImpl of IBackerZero<ContractState> {
        fn create_campaign(
            ref self: ContractState, goal: u128, deadline: u64, creator_claim_commitment: felt252,
        ) -> u64 {
            assert(goal > 0, 'ZERO_GOAL');
            assert(deadline > get_block_timestamp(), 'DEADLINE_NOT_FUTURE');
            assert(creator_claim_commitment != 0, 'ZERO_CLAIM_COMMIT');

            let creator = get_caller_address();
            let campaign_id = BackerZeroHashing::compute_campaign_id(
                get_tx_info().chain_id, get_contract_address(), creator, goal, deadline,
            );

            let existing = self.campaigns.read(campaign_id);
            assert(existing.creator.into() == 0, 'CAMPAIGN_ID_COLLISION');

            let campaign = Campaign {
                creator,
                creator_claim_commitment,
                goal,
                raised: 0,
                refunded_total: 0,
                deadline,
                contribution_count: 0,
                claimed: false,
            };

            self.campaigns.write(campaign_id, campaign);

            self
                .emit(
                    CampaignCreated {
                        campaign_id,
                        creator,
                        goal,
                        deadline,
                        token: self.token.read(),
                        creator_claim_commitment,
                    },
                );

            campaign_id
        }

        fn privacy_invoke(
            ref self: ContractState, operation: BackerZeroOperation,
        ) -> Span<OpenNoteDeposit> {
            assert(get_caller_address() == self.pool.read(), 'CALLER_NOT_POOL');

            match operation {
                BackerZeroOperation::Back(op) => self.back(op),
                BackerZeroOperation::ClaimFunding(op) => self.claim_funding(op),
                BackerZeroOperation::ClaimRefund(op) => self.claim_refund(op),
            }
        }

        fn get_campaign(self: @ContractState, campaign_id: u64) -> Campaign {
            self.campaigns.read(campaign_id)
        }

        fn get_contribution(
            self: @ContractState, campaign_id: u64, receipt_commitment: felt252,
        ) -> Contribution {
            self.contributions.read((campaign_id, receipt_commitment))
        }

        fn get_total_escrow(self: @ContractState) -> u128 {
            self.total_escrow.read()
        }

        fn get_pool(self: @ContractState) -> ContractAddress {
            self.pool.read()
        }

        fn get_token(self: @ContractState) -> ContractAddress {
            self.token.read()
        }

        fn campaign_status(self: @ContractState, campaign_id: u64) -> CampaignStatus {
            let campaign = self.campaigns.read(campaign_id);
            let now = get_block_timestamp();
            if now < campaign.deadline {
                CampaignStatus::Active
            } else if campaign.raised >= campaign.goal {
                if campaign.claimed {
                    CampaignStatus::Claimed
                } else {
                    CampaignStatus::Successful
                }
            } else {
                CampaignStatus::Failed
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn back(ref self: ContractState, op: BackOperation) -> Span<OpenNoteDeposit> {
            let mut campaign = self.campaigns.read(op.campaign_id);
            assert(campaign.creator.into() != 0, 'CAMPAIGN_NOT_FOUND');
            assert(get_block_timestamp() < campaign.deadline, 'CAMPAIGN_CLOSED');
            assert(op.token == self.token.read(), 'WRONG_TOKEN');
            assert(op.amount > 0, 'ZERO_AMOUNT');
            assert(op.receipt_commitment != 0, 'ZERO_COMMITMENT');
            assert(op.contribution_auth != 0, 'ZERO_CONTRIBUTION_AUTH');

            let existing = self.contributions.read((op.campaign_id, op.receipt_commitment));
            assert(existing.amount == 0, 'RECEIPT_EXISTS');

            let new_liability = self
                .total_escrow
                .read()
                .checked_add(op.amount)
                .expect('ESCROW_OVERFLOW');

            let helper_balance = IERC20Dispatcher { contract_address: self.token.read() }
                .balance_of(get_contract_address());
            let required: u256 = new_liability.into();
            assert(helper_balance >= required, 'NOT_FUNDED');

            let new_raised = campaign.raised.checked_add(op.amount).expect('RAISED_OVERFLOW');
            campaign.raised = new_raised;
            campaign.contribution_count += 1;
            self.campaigns.write(op.campaign_id, campaign);

            self
                .contributions
                .write(
                    (op.campaign_id, op.receipt_commitment),
                    Contribution {
                        amount: op.amount, refunded: false, refund_id: op.contribution_auth,
                    },
                );
            self.total_escrow.write(new_liability);

            self
                .emit(
                    Backed {
                        campaign_id: op.campaign_id, amount: op.amount, raised: campaign.raised,
                    },
                );

            array![].span()
        }

        fn claim_funding(
            ref self: ContractState, op: ClaimFundingOperation,
        ) -> Span<OpenNoteDeposit> {
            let mut campaign = self.campaigns.read(op.campaign_id);
            assert(campaign.creator.into() != 0, 'CAMPAIGN_NOT_FOUND');
            assert(get_block_timestamp() >= campaign.deadline, 'NOT_FINISHED');
            assert(campaign.raised >= campaign.goal, 'GOAL_NOT_REACHED');
            assert(!campaign.claimed, 'ALREADY_CLAIMED');
            assert(op.token == self.token.read(), 'WRONG_TOKEN');
            assert(op.amount == campaign.raised, 'WRONG_CLAIM_AMOUNT');

            let chain_id = get_tx_info().chain_id;
            let helper = get_contract_address();
            let derived = BackerZeroHashing::compute_creator_commitment(
                chain_id, helper, op.campaign_id, op.creator_secret,
            );
            assert(derived == campaign.creator_claim_commitment, 'BAD_CREATOR_CAPABILITY');

            let amount = campaign.raised;

            campaign.claimed = true;
            self.campaigns.write(op.campaign_id, campaign);

            let new_total = self.total_escrow.read().checked_sub(amount).expect('ESCROW_UNDERFLOW');
            self.total_escrow.write(new_total);

            let approved = IERC20Dispatcher { contract_address: self.token.read() }
                .approve(self.pool.read(), amount.into());
            assert(approved, 'APPROVE_FAILED');

            self.emit(FundingClaimed { campaign_id: op.campaign_id, amount });

            array![OpenNoteDeposit { note_id: op.note_id, token: self.token.read(), amount }].span()
        }

        fn claim_refund(
            ref self: ContractState, op: ClaimRefundOperation,
        ) -> Span<OpenNoteDeposit> {
            let mut campaign = self.campaigns.read(op.campaign_id);
            assert(campaign.creator.into() != 0, 'CAMPAIGN_NOT_FOUND');
            assert(get_block_timestamp() >= campaign.deadline, 'NOT_FINISHED');
            assert(campaign.raised < campaign.goal, 'CAMPAIGN_SUCCEEDED');
            assert(op.token == self.token.read(), 'WRONG_TOKEN');
            assert(op.amount > 0, 'ZERO_AMOUNT');

            let chain_id = get_tx_info().chain_id;
            let helper = get_contract_address();
            let receipt_commitment = BackerZeroHashing::compute_receipt_commitment(
                chain_id, helper, op.campaign_id, op.receipt_secret,
            );

            let mut contribution = self.contributions.read((op.campaign_id, receipt_commitment));
            assert(contribution.amount > 0, 'NO_CONTRIBUTION');
            assert(contribution.amount == op.amount, 'WRONG_REFUND_AMOUNT');
            assert(!contribution.refunded, 'ALREADY_REFUNDED');

            let refund_id = BackerZeroHashing::compute_refund_id(
                chain_id,
                helper,
                op.campaign_id,
                op.token,
                op.amount,
                op.destination,
                op.receipt_secret,
                op.identity_binding,
                op.context,
                op.seq_nonce,
            );
            assert(refund_id == contribution.refund_id, 'REFUND_ID_MISMATCH');

            contribution.refunded = true;
            self.contributions.write((op.campaign_id, receipt_commitment), contribution);

            let new_refunded = campaign
                .refunded_total
                .checked_add(op.amount)
                .expect('REFUND_TOTAL_OVERFLOW');
            campaign.refunded_total = new_refunded;
            self.campaigns.write(op.campaign_id, campaign);

            let new_total = self
                .total_escrow
                .read()
                .checked_sub(op.amount)
                .expect('ESCROW_UNDERFLOW');
            self.total_escrow.write(new_total);

            let approved = IERC20Dispatcher { contract_address: self.token.read() }
                .approve(self.pool.read(), op.amount.into());
            assert(approved, 'APPROVE_FAILED');

            self.emit(Refunded { campaign_id: op.campaign_id, amount: op.amount });

            array![
                OpenNoteDeposit {
                    note_id: op.note_id, token: self.token.read(), amount: op.amount,
                },
            ]
                .span()
        }
    }
}
