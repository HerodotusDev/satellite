use starknet::storage::Map;

#[starknet::storage_node]
pub struct MmrInfo {
    is_sibling_synced: bool,
    latest_size: u256,
    mmr_size_to_root: Map<u256, u256>,
}

#[starknet::component]
pub mod state_component {
    use starknet::storage::Map;
    use super::MmrInfo;

    #[storage]
    struct Storage {
        chain_id: u256,
        /// ChainId => MMR ID => hashing function => MMR info
        mmrs: Map<u256, Map<u256, Map<u256, MmrInfo>>>,
        /// ChainId => hashing function => block number => parent hash
        received_parent_hashes: Map<u256, Map<u256, Map<u256, u256>>>,
    }
}
