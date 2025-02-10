#[starknet::interface]
pub trait IReceiver<TContractState> {
    fn setL1MessageSender(ref self: TContractState, l1_address: felt252);
}

#[starknet::contract]
pub mod HerodotusStarknet {
    use openzeppelin::{access::ownable::OwnableComponent, upgrades::UpgradeableComponent};
    use herodotus_starknet::{
        evm_fact_registry::evm_fact_registry_component,
        mmr_core::{mmr_core_component, RootForHashingFunction}, state::state_component,
        on_chain_growing::on_chain_growing_component,
    };
    use starknet::ContractAddress;
    use super::*;

    component!(path: state_component, storage: state, event: StateEvent);
    component!(
        path: evm_fact_registry_component, storage: evm_fact_registry, event: EvmFactRegistryEvent,
    );
    component!(path: mmr_core_component, storage: mmr_core, event: MmrCoreEvent);
    component!(
        path: on_chain_growing_component, storage: on_chain_growing, event: OnChainGrowingEvent,
    );

    // Ownable / Upgradeable
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[storage]
    struct Storage {
        l1_message_sender: felt252,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        state: state_component::Storage,
        #[substorage(v0)]
        evm_fact_registry: evm_fact_registry_component::Storage,
        #[substorage(v0)]
        mmr_core: mmr_core_component::Storage,
        #[substorage(v0)]
        on_chain_growing: on_chain_growing_component::Storage,
    }

    #[constructor]
    fn constructor(ref self: ContractState, chain_id: u256, owner: ContractAddress) {
        self.state.chain_id.write(chain_id);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl IReceiverImpl of IReceiver<ContractState> {
        fn setL1MessageSender(ref self: ContractState, l1_address: felt252) {
            self.ownable.assert_only_owner();
            self.l1_message_sender.write(l1_address);
        }
    }

    #[l1_handler]
    fn receiveParentHash(
        ref self: ContractState,
        from_address: felt252,
        chain_id: u256,
        hashing_function: u256,
        block_number: u256,
        parent_hash: u256,
    ) {
        assert(from_address == self.l1_message_sender.read(), 'ONLY_L1_MESSAGE_SENDER');
        self._receiveParentHash(chain_id, hashing_function, block_number, parent_hash);
    }

    #[l1_handler]
    fn receiveMmr(
        ref self: ContractState,
        from_address: felt252,
        new_mmr_id: u256,
        roots_for_hashing_functions: Span<RootForHashingFunction>,
        mmr_size: u256,
        accumulated_chain_id: u256,
        origin_chain_id: u256,
        original_mmr_id: u256,
        is_sibling_synced: bool,
    ) {
        assert(from_address == self.l1_message_sender.read(), 'ONLY_L1_MESSAGE_SENDER');
        self
            ._createMmrFromForeign(
                new_mmr_id,
                roots_for_hashing_functions,
                mmr_size,
                accumulated_chain_id,
                origin_chain_id,
                original_mmr_id,
                is_sibling_synced,
            );
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        StateEvent: state_component::Event,
        #[flat]
        EvmFactRegistryEvent: evm_fact_registry_component::Event,
        #[flat]
        MmrCoreEvent: mmr_core_component::Event,
        #[flat]
        OnChainGrowingEvent: on_chain_growing_component::Event,
    }

    #[abi(embed_v0)]
    impl EvmFactRegistryImpl =
        evm_fact_registry_component::EvmFactRegistry<ContractState>;

    impl MmrCoreInternalImpl = mmr_core_component::MmrCoreInternal<ContractState>;
    #[abi(embed_v0)]
    impl MmrCoreExternalImpl = mmr_core_component::MmrCoreExternal<ContractState>;

    #[abi(embed_v0)]
    impl OnChainGrowingImpl =
        on_chain_growing_component::OnChainGrowing<ContractState>;

    // Ownable / Upgradeable
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
}
