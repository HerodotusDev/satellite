use starknet::storage::Map;

#[starknet::storage_node]
pub struct MmrInfo {
    isSiblingSynced: bool,
    latestSize: u256,
    mmrSizeToRoot: Map<felt252, felt252>,
}

#[starknet::component]
pub mod state_component {
    use starknet::storage::Map;
    use super::MmrInfo;

    #[storage]
    struct Storage {
        /// ChainId => MMR ID => hashing function => MMR info
        mmrs: Map<u256, Map<u256, Map<u256, MmrInfo>>>,

        /// ChainId => hashing function => block number => parent hash
        receivedParentHashes: Map<u256, Map<u256, Map<u256, u256>>>,

        testvar: felt252,
    }
}