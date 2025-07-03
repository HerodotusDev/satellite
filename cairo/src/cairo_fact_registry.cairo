use starknet::ContractAddress;

// For now, unlike solidity version, this module does not store non-mocked facts locally.

#[starknet::interface]
pub trait ICairoFactRegistry<TContractState> {
    /// Whether given fact was verified (not necessarily stored locally).
    fn isCairoFactValid(self: @TContractState, fact_hash: felt252) -> bool;

    /// Returns address of the contract that stores verified facts.
    fn getCairoFactRegistryExternalContract(self: @TContractState) -> ContractAddress;

    /// Sets address of the contract that stores verified facts.
    fn setCairoFactRegistryExternalContract(ref self: TContractState, fallback_address: ContractAddress);

    /// Whether given fact was mocked.
    fn isCairoMockedFactValid(self: @TContractState, fact_hash: felt252) -> bool;

    /// Mocks given fact. Caller must be an admin.
    fn setCairoMockedFact(ref self: TContractState, fact_hash: felt252);

    // ========= For internal use in grower and data processor ========= //

    fn isCairoFactValidForInternal(self: @TContractState, fact_hash: felt252) -> bool;

    fn isMockedForInternal(self: @TContractState) -> bool;
    
    fn setMockedForInternal(ref self: TContractState, is_mocked: bool);

    // ======================= Admin management ======================== //

    fn isAdmin(self: @TContractState, account: ContractAddress) -> bool;

    fn manageAdmins(ref self: TContractState, accounts: Span<ContractAddress>, is_admin: bool);
}


#[starknet::component]
pub mod cairo_fact_registry_component {
    use crate::mmr_core::mmr_core_component::MmrCoreExternalImpl;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use starknet::get_caller_address;
    use openzeppelin::access::ownable::{
        OwnableComponent, OwnableComponent::InternalTrait as OwnableInternal,
    };
    use super::*;

    #[storage]
    struct Storage {
        _facts: Map<felt252, bool>, // for now unused
        mocked_facts: Map<felt252, bool>,
        fallback_contract: ContractAddress,
        is_mocked_for_internal: bool,
        admins: Map<ContractAddress, bool>,
    }

    #[derive(Drop, starknet::Event)]
    struct MockedForInternalSet {
        is_mocked: bool
    }

    #[derive(Drop, starknet::Event)]
    struct CairoFactRegistryExternalContractSet {
        fallback_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CairoFactSet {
        fact_hash: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct CairoMockedFactSet {
        fact_hash: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        MockedForInternalSet: MockedForInternalSet,
        CairoFactRegistryExternalContractSet: CairoFactRegistryExternalContractSet,
        CairoFactSet: CairoFactSet,
        CairoMockedFactSet: CairoMockedFactSet,
    }

    #[embeddable_as(CairoFactRegistry)]
    pub impl CairoFactRegistryImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
    > of ICairoFactRegistry<ComponentState<TContractState>> {
        fn isCairoFactValid(self: @ComponentState<TContractState>, fact_hash: felt252) -> bool {
            true // TODO:
        }

        fn getCairoFactRegistryExternalContract(self: @ComponentState<TContractState>) -> ContractAddress {
            self.fallback_contract.read()
        }

        fn setCairoFactRegistryExternalContract(ref self: ComponentState<TContractState>, fallback_address: ContractAddress) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            self.fallback_contract.write(fallback_address);
            self.emit(Event::CairoFactRegistryExternalContractSet(CairoFactRegistryExternalContractSet {fallback_address}));
        }

        fn isCairoMockedFactValid(self: @ComponentState<TContractState>, fact_hash: felt252) -> bool {
            self.mocked_facts.entry(fact_hash).read()
        }
    
        fn setCairoMockedFact(ref self: ComponentState<TContractState>, fact_hash: felt252) {
            assert(self.isAdmin(get_caller_address()), 'ONLY_ADMIN');

            self.mocked_facts.entry(fact_hash).write(true);
            self.emit(Event::CairoMockedFactSet(CairoMockedFactSet {fact_hash}));
        }
    
        // ========= For internal use in grower and data processor ========= //
    
        fn isCairoFactValidForInternal(self: @ComponentState<TContractState>, fact_hash: felt252) -> bool {
            if self.is_mocked_for_internal.read() {
                self.mocked_facts.entry(fact_hash).read()
            } else {
                self.isCairoFactValid(fact_hash)
            }
        }
    
        fn isMockedForInternal(self: @ComponentState<TContractState>) -> bool {
            self.is_mocked_for_internal.read()
        }
    
        fn setMockedForInternal(ref self: ComponentState<TContractState>, is_mocked: bool) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            self.is_mocked_for_internal.write(is_mocked);
            self.emit(Event::MockedForInternalSet(MockedForInternalSet { is_mocked }));
        }

        // ======================= Admin management ======================== //

        fn isAdmin(self: @ComponentState<TContractState>, account: ContractAddress) -> bool {
            self.admins.entry(account).read()
        }

        fn manageAdmins(ref self: ComponentState<TContractState>, accounts: Span<ContractAddress>, is_admin: bool) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            for account in accounts {
                self.admins.entry(*account).write(is_admin);
            };
        }
    }
}
