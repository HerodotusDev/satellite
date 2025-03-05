pub mod state;
pub mod evm_fact_registry;
pub mod mmr_core;
pub mod receiver;
pub mod evm_growing;
pub mod utils;
// Main contract is in receiver.cairo file
// because L1 handlers cannot be defined in components
