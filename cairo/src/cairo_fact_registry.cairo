use cairo_lib::utils::bitwise::reverse_endianness_u256;
use core::keccak::keccak_u256s_be_inputs;
use integrity::contracts::fact_registry_interface::{
    IFactRegistryDispatcher, IFactRegistryDispatcherTrait, Verification, VerificationListElement,
};
use integrity::settings::{FactHash, SecurityBits, VerificationHash, VerifierConfiguration};
use integrity::{SHARP_BOOTLOADER_PROGRAM_HASH, calculate_bootloaded_fact_hash};
use starknet::ContractAddress;


// For now, unlike solidity version, this module does not store non-mocked facts locally.

const ALLOWED_SECURITY_BITS: SecurityBits = 96;
const TRANSLATED_SECURITY_BITS: SecurityBits = 96;

#[starknet::interface]
pub trait ICairoFactRegistry<TContractState> {
    // ========= Main function for end user ========= //

    /// Whether given fact is valid (mocked or verified).
    fn isCairoFactValid(self: @TContractState, fact_hash: felt252, is_mocked: bool) -> bool;

    fn get_all_verifications_for_fact_hash(
        self: @TContractState, fact_hash: FactHash, is_mocked: bool,
    ) -> Span<VerificationListElement>;

    fn get_verification(
        self: @TContractState, verification_hash: VerificationHash, is_mocked: bool,
    ) -> Option<Verification>;

    // ========= Fact registry with real verification ========= //

    /// Whether given fact was verified (not necessarily stored locally).
    fn isCairoVerifiedFactValid(self: @TContractState, fact_hash: felt252) -> bool;

    /// Returns address of the contract that stores verified facts.
    fn getCairoVerifiedFactRegistryContract(self: @TContractState) -> ContractAddress;

    /// Sets address of the contract that stores verified facts.
    fn setCairoVerifiedFactRegistryContract(
        ref self: TContractState, fallback_address: ContractAddress,
    );

    /// Whether given fact was mocked.
    fn isCairoMockedFactValid(self: @TContractState, fact_hash: felt252) -> bool;

    /// Mocks given fact. Caller must be an admin.
    fn setCairoMockedFact(
        ref self: TContractState,
        verifier_config: VerifierConfiguration,
        fact_hash: FactHash,
        security_bits: SecurityBits,
    );

    /// Returns address of the contract that stores mocked facts.
    fn getCairoMockedFactRegistryFallbackContract(self: @TContractState) -> ContractAddress;

    /// Sets address of the contract that stores mocked facts.
    fn setCairoMockedFactRegistryFallbackContract(
        ref self: TContractState, fallback_address: ContractAddress,
    );

    // ========= For internal use in grower and data processor ========= //

    fn isCairoFactValidForInternal(self: @TContractState, fact_hash: felt252) -> bool;

    fn isMockedForInternal(self: @TContractState) -> bool;

    fn setIsMockedForInternal(ref self: TContractState, is_mocked: bool);

    // ======================= Admin management ======================== //

    fn isAdmin(self: @TContractState, account: ContractAddress) -> bool;

    fn manageAdmins(ref self: TContractState, accounts: Span<ContractAddress>, is_admin: bool);

    // ======================= Keccak facts ======================== //

    fn isKeccakFactHashValid(self: @TContractState, fact_hash: u256, is_mocked: bool) -> bool;

    fn isKeccakVerifiedFactHashValid(self: @TContractState, fact_hash: u256) -> bool;

    fn isKeccakMockedFactHashValid(self: @TContractState, fact_hash: u256) -> bool;

    fn translateFactHash(
        ref self: TContractState, program_hash: felt252, output: Span<felt252>, is_mocked: bool,
    );

    fn isTranslatedFactHashValid(
        self: @TContractState, fact_hash: felt252, is_mocked: bool,
    ) -> bool;
}

#[starknet::interface]
pub trait ICairoFactRegistryInternal<TContractState> {
    fn _receiveKeccakFactHash(ref self: TContractState, fact_hash: u256, is_mocked: bool);
}

#[starknet::component]
pub mod cairo_fact_registry_component {
    use core::num::traits::Zero;
    use integrity::Integrity;
    use integrity::contracts::mocked_fact_registry::{
        IFactRegistryExternalDispatcher, IFactRegistryExternalDispatcherTrait,
    };
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::OwnableComponent::InternalTrait as OwnableInternal;
    use starknet::get_caller_address;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::mmr_core::mmr_core_component::MmrCoreExternalImpl;
    use super::*;

    #[storage]
    struct Storage {
        _facts: Map<felt252, bool>, // for now unused
        mocked_facts: Map<felt252, bool>,
        external_fact_registry: ContractAddress,
        is_mocked_for_internal: bool,
        fallback_mocked_contract: ContractAddress,
        admins: Map<ContractAddress, bool>,
        keccak_facts: Map<(u256, bool), bool>,
        translated_fact_hashes: Map<(felt252, bool), bool>,
    }

    #[derive(Drop, starknet::Event)]
    struct CairoFactSet {
        fact_hash: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct CairoFactRegistryExternalContractSet {
        fallback_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CairoMockedFactSet {
        fact_hash: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct CairoMockedFactRegistryFallbackContractSet {
        fallback_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct IsMockedForInternalSet {
        is_mocked: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct CairoKeccakHashSet {
        fact_hash: u256,
        is_mocked: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct TranslatedFactHashSet {
        keccak_fact_hash: u256,
        integrity_fact_hash: felt252,
        is_mocked: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CairoFactSet: CairoFactSet,
        CairoFactRegistryExternalContractSet: CairoFactRegistryExternalContractSet,
        CairoMockedFactSet: CairoMockedFactSet,
        CairoMockedFactRegistryFallbackContractSet: CairoMockedFactRegistryFallbackContractSet,
        IsMockedForInternalSet: IsMockedForInternalSet,
        CairoKeccakHashSet: CairoKeccakHashSet,
        TranslatedFactHashSet: TranslatedFactHashSet,
    }

    #[embeddable_as(CairoFactRegistry)]
    pub impl CairoFactRegistryImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
    > of ICairoFactRegistry<ComponentState<TContractState>> {
        // ========= Main function for end user ========= //

        fn isCairoFactValid(
            self: @ComponentState<TContractState>, fact_hash: felt252, is_mocked: bool,
        ) -> bool {
            let standard = if is_mocked {
                self.mocked_facts.entry(fact_hash).read()
            } else {
                self.isCairoVerifiedFactValid(fact_hash)
            };
            standard || self.translated_fact_hashes.entry((fact_hash, is_mocked)).read()
        }

        fn get_all_verifications_for_fact_hash(
            self: @ComponentState<TContractState>, fact_hash: FactHash, is_mocked: bool,
        ) -> Span<VerificationListElement> {
            let contract_address = if is_mocked {
                self.fallback_mocked_contract.read()
            } else {
                self.external_fact_registry.read()
            };
            let mut verifications = IFactRegistryDispatcher { contract_address }
                .get_all_verifications_for_fact_hash(fact_hash);

            // Check for translated fact hashes
            if self.translated_fact_hashes.entry((fact_hash, is_mocked)).read() {
                verifications
                    .append(
                        VerificationListElement {
                            verification_hash: 0x0,
                            security_bits: TRANSLATED_SECURITY_BITS,
                            verifier_config: VerifierConfiguration {
                                layout: 'translated',
                                hasher: 'translated',
                                stone_version: 'translated',
                                memory_verification: 'translated',
                            },
                        },
                    )
            }
            verifications.span()
        }

        fn get_verification(
            self: @ComponentState<TContractState>,
            verification_hash: VerificationHash,
            is_mocked: bool,
        ) -> Option<Verification> {
            let contract_address = if is_mocked {
                self.fallback_mocked_contract.read()
            } else {
                self.external_fact_registry.read()
            };
            IFactRegistryDispatcher { contract_address }.get_verification(verification_hash)
        }

        // ========= Fact registry with real verification ========= //

        fn isCairoVerifiedFactValid(
            self: @ComponentState<TContractState>, fact_hash: felt252,
        ) -> bool {
            Integrity::from_address(self.external_fact_registry.read())
                .is_fact_hash_valid_with_security(fact_hash, ALLOWED_SECURITY_BITS)
                || self.translated_fact_hashes.entry((fact_hash, false)).read()
        }

        fn getCairoVerifiedFactRegistryContract(
            self: @ComponentState<TContractState>,
        ) -> ContractAddress {
            self.external_fact_registry.read()
        }

        fn setCairoVerifiedFactRegistryContract(
            ref self: ComponentState<TContractState>, fallback_address: ContractAddress,
        ) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            self.external_fact_registry.write(fallback_address);
            self
                .emit(
                    Event::CairoFactRegistryExternalContractSet(
                        CairoFactRegistryExternalContractSet { fallback_address },
                    ),
                );
        }

        // ========= Mocked fact registry ========= //

        fn isCairoMockedFactValid(
            self: @ComponentState<TContractState>, fact_hash: felt252,
        ) -> bool {
            if self.mocked_facts.entry(fact_hash).read() {
                return true;
            }
            let fallback_mocked_contract = self.fallback_mocked_contract.read();
            let standard = if fallback_mocked_contract.is_non_zero() {
                Integrity::from_address(fallback_mocked_contract)
                    .is_fact_hash_valid_with_security(fact_hash, ALLOWED_SECURITY_BITS)
            } else {
                false
            };
            standard || self.translated_fact_hashes.entry((fact_hash, true)).read()
        }

        fn setCairoMockedFact(
            ref self: ComponentState<TContractState>,
            verifier_config: VerifierConfiguration,
            fact_hash: FactHash,
            security_bits: SecurityBits,
        ) {
            assert(self.isAdmin(get_caller_address()), 'ONLY_ADMIN');
            assert(security_bits >= ALLOWED_SECURITY_BITS, 'INVALID_SECURITY_BITS');

            self.mocked_facts.entry(fact_hash).write(true);
            self.emit(Event::CairoMockedFactSet(CairoMockedFactSet { fact_hash }));

            let contract_address = self.fallback_mocked_contract.read();
            if contract_address.is_zero() {
                return;
            }
            IFactRegistryExternalDispatcher { contract_address }
                .register_fact(verifier_config, fact_hash, security_bits);
        }

        fn getCairoMockedFactRegistryFallbackContract(
            self: @ComponentState<TContractState>,
        ) -> ContractAddress {
            self.fallback_mocked_contract.read()
        }

        fn setCairoMockedFactRegistryFallbackContract(
            ref self: ComponentState<TContractState>, fallback_address: ContractAddress,
        ) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            self.fallback_mocked_contract.write(fallback_address);
            self
                .emit(
                    Event::CairoMockedFactRegistryFallbackContractSet(
                        CairoMockedFactRegistryFallbackContractSet { fallback_address },
                    ),
                );
        }

        // ========= For internal use in grower and data processor ========= //

        fn isCairoFactValidForInternal(
            self: @ComponentState<TContractState>, fact_hash: felt252,
        ) -> bool {
            self.isCairoFactValid(fact_hash, self.is_mocked_for_internal.read())
        }

        fn isMockedForInternal(self: @ComponentState<TContractState>) -> bool {
            self.is_mocked_for_internal.read()
        }

        fn setIsMockedForInternal(ref self: ComponentState<TContractState>, is_mocked: bool) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            self.is_mocked_for_internal.write(is_mocked);
            self.emit(Event::IsMockedForInternalSet(IsMockedForInternalSet { is_mocked }));
        }

        // ======================= Admin management ======================== //

        fn isAdmin(self: @ComponentState<TContractState>, account: ContractAddress) -> bool {
            self.admins.entry(account).read()
        }

        fn manageAdmins(
            ref self: ComponentState<TContractState>,
            accounts: Span<ContractAddress>,
            is_admin: bool,
        ) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            for account in accounts {
                self.admins.entry(*account).write(is_admin);
            };
        }

        // ======================= Keccak facts ======================== //
        // Facts can be sent from Ethereum satellite contract instead of calling Integrity.
        // THe fact will be different, because it uses keccak, not poseidon and bootloader is
        // decommited.

        fn isKeccakFactHashValid(
            self: @ComponentState<TContractState>, fact_hash: u256, is_mocked: bool,
        ) -> bool {
            self.keccak_facts.entry((fact_hash, is_mocked)).read()
        }

        fn isKeccakVerifiedFactHashValid(
            self: @ComponentState<TContractState>, fact_hash: u256,
        ) -> bool {
            self.keccak_facts.entry((fact_hash, false)).read()
        }

        fn isKeccakMockedFactHashValid(
            self: @ComponentState<TContractState>, fact_hash: u256,
        ) -> bool {
            self.keccak_facts.entry((fact_hash, true)).read()
        }

        fn translateFactHash(
            ref self: ComponentState<TContractState>,
            program_hash: felt252,
            output: Span<felt252>,
            is_mocked: bool,
        ) {
            let (keccak_fact_hash, integrity_fact_hash) = get_fact_hashes(program_hash, output);
            assert(
                self.keccak_facts.entry((keccak_fact_hash, is_mocked)).read() == true,
                'KECCAK_FACT_HASH_NOT_SAVED',
            );
            self.translated_fact_hashes.entry((integrity_fact_hash, is_mocked)).write(true);
            self
                .emit(
                    Event::TranslatedFactHashSet(
                        TranslatedFactHashSet { keccak_fact_hash, integrity_fact_hash, is_mocked },
                    ),
                );
        }

        fn isTranslatedFactHashValid(
            self: @ComponentState<TContractState>, fact_hash: felt252, is_mocked: bool,
        ) -> bool {
            self.translated_fact_hashes.entry((fact_hash, is_mocked)).read()
        }
    }

    #[embeddable_as(CairoFactRegistryInternal)]
    pub impl CairoFactRegistryInternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>,
        // impl State: state_component::HasComponent<TContractState>
    > of ICairoFactRegistryInternal<ComponentState<TContractState>> {
        fn _receiveKeccakFactHash(
            ref self: ComponentState<TContractState>, fact_hash: u256, is_mocked: bool,
        ) {
            self.keccak_facts.entry((fact_hash, is_mocked)).write(true);
            self.emit(Event::CairoKeccakHashSet(CairoKeccakHashSet { fact_hash, is_mocked }));
        }
    }
}

pub fn get_fact_hashes(program_hash: felt252, output: Span<felt252>) -> (u256, felt252) {
    let mut output_u256s = array![];
    for value in output {
        output_u256s.append((*value).into());
    }
    let output_hash = reverse_endianness_u256(keccak_u256s_be_inputs(output_u256s.span()));
    let keccak_fact = reverse_endianness_u256(
        keccak_u256s_be_inputs(array![program_hash.into(), output_hash].span()),
    );
    let poseidon_fact = calculate_bootloaded_fact_hash(
        SHARP_BOOTLOADER_PROGRAM_HASH, program_hash, output,
    );
    (keccak_fact, poseidon_fact)
}
