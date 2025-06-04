use storage_proofs::{
    evm_fact_registry::{
        evm_fact_registry_component::{EvmFactRegistryInternalImpl, EvmFactRegistryImpl},
        BlockHeaderProof,
    },
    mmr_core::{
        mmr_core_component::MmrCoreInternalImpl, RootForHashingFunction, POSEIDON_HASHING_FUNCTION,
    },
    receiver::StorageProofs,
};
use cairo_lib::{hashing::poseidon::hash_words64, data_structures::mmr::utils::compute_root};

pub fn create_mmr_with_block(
    ref contract: StorageProofs::ContractState, header_rlp: Span<u64>, chain_id: u256, mmr_id: u256,
) -> BlockHeaderProof {
    let mmr_size = 1;
    let leaf_hash = hash_words64(header_rlp);
    let root = compute_root(mmr_size, [leaf_hash].span());
    let roots_for_hashing_functions = [
        RootForHashingFunction { root: root.into(), hashing_function: POSEIDON_HASHING_FUNCTION }
    ]
        .span();

    contract
        ._createMmrFromForeign(
            mmr_id, roots_for_hashing_functions, mmr_size, chain_id, chain_id, 0, false,
        );

    BlockHeaderProof {
        mmr_id,
        mmr_size,
        mmr_leaf_index: 1,
        mmr_peaks: [leaf_hash].span(),
        mmr_proof: [].span(),
        block_header_rlp: header_rlp,
    }
}
