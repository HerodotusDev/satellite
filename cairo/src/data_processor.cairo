use cairo_lib::utils::bitwise::reverse_endianness_u256;
use core::keccak::keccak_u256s_be_inputs;

#[derive(Drop, Serde, starknet::Store, PartialEq)]
enum TaskStatus {
    #[default]
    NONE,
    SCHEDULED,
    FINALIZED,
}

#[derive(Drop, Serde, starknet::Store)]
struct TaskResult {
    status: TaskStatus,
    result: u256,
}

#[derive(Drop, Serde)]
struct MmrData {
    chain_id: u256,
    mmr_id: u256,
    mmr_size: u256,
}

#[derive(Drop, Serde)]
struct MmrCollection {
    poseidon_mmr: Span<MmrData>,
    keccak_mmr: Span<MmrData>,
}

#[derive(Drop, Serde)]
struct TaskData {
    mmr_collection: MmrCollection,
    task_result_low: u128,
    task_result_high: u128,
    task_hash_low: u128,
    task_hash_high: u128,
    program_hash: felt252,
}

#[derive(Drop, Serde)]
struct ModuleTask {
    program_hash: u256,
    inputs: Span<u256>,
}

#[starknet::interface]
pub trait IDataProcessor<TContractState> {
    // ========================= Setup Functions ========================= //

    /// Set the program hash for the HDP program
    fn setDataProcessorProgramHash(ref self: TContractState, program_hash: felt252);

    /// Disable some program hashes
    fn disableProgramHashes(ref self: TContractState, program_hashes: Span<felt252>);

    /// Checks if a program hash is currently authorized
    fn isProgramHashAuthorized(self: @TContractState, program_hash: felt252) -> bool;

    // ========================= Core Functions ========================= //

    /// Requests the execution of a task with a module
    fn requestDataProcessorExecutionOfTask(ref self: TContractState, module_task: ModuleTask);

    /// Authenticates the execution of a task is finalized by verifying the locally computed fact
    /// with the FactsRegistry
    fn authenticateDataProcessorTaskExecution(ref self: TContractState, task_data: TaskData);

    /// Returns the status of a task
    fn getDataProcessorTaskStatus(self: @TContractState, task_commitment: u256) -> TaskStatus;

    /// Returns the result of a finalized task
    fn getDataProcessorFinalizedTaskResult(self: @TContractState, task_commitment: u256) -> u256;
}

#[starknet::component]
pub mod data_processor_component {
    use integrity::{SHARP_BOOTLOADER_PROGRAM_HASH, calculate_bootloaded_fact_hash};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::OwnableComponent::InternalTrait as OwnableInternal;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::cairo_fact_registry::{ICairoFactRegistry, cairo_fact_registry_component};
    use crate::mmr_core::mmr_core_component::MmrCoreExternalImpl;
    use crate::mmr_core::{KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION};
    use crate::state::state_component;
    use super::*;

    #[storage]
    struct Storage {
        cachedTasksResult: Map<u256, TaskResult>,
        authorizedProgramHashes: Map<felt252, bool>,
    }

    #[derive(Drop, starknet::Event)]
    struct ProgramHashEnabled {
        program_hash: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ProgramHashesDisabled {
        program_hashes: Span<felt252>,
    }

    #[derive(Drop, starknet::Event)]
    struct TaskAlreadyStored {
        task_commitment: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ModuleTaskScheduled {
        module_task: ModuleTask,
    }

    #[derive(Drop, starknet::Event)]
    struct TaskFinalized {
        task_hash: u256,
        task_result: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ProgramHashEnabled: ProgramHashEnabled,
        ProgramHashesDisabled: ProgramHashesDisabled,
        TaskAlreadyStored: TaskAlreadyStored,
        ModuleTaskScheduled: ModuleTaskScheduled,
        TaskFinalized: TaskFinalized,
    }

    #[embeddable_as(DataProcessor)]
    impl DataProcessorImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
        impl CairoFactRegistry: cairo_fact_registry_component::HasComponent<TContractState>,
    > of IDataProcessor<ComponentState<TContractState>> {
        // ========================= Setup Functions ========================= //

        fn setDataProcessorProgramHash(
            ref self: ComponentState<TContractState>, program_hash: felt252,
        ) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            self.authorizedProgramHashes.entry(program_hash).write(true);
            self.emit(Event::ProgramHashEnabled(ProgramHashEnabled { program_hash }))
        }

        fn disableProgramHashes(
            ref self: ComponentState<TContractState>, program_hashes: Span<felt252>,
        ) {
            get_dep_component!(@self, Ownable).assert_only_owner();

            for program_hash in program_hashes {
                self.authorizedProgramHashes.entry(*program_hash).write(false);
            }
            self.emit(Event::ProgramHashesDisabled(ProgramHashesDisabled { program_hashes }));
        }

        fn isProgramHashAuthorized(
            self: @ComponentState<TContractState>, program_hash: felt252,
        ) -> bool {
            self.authorizedProgramHashes.entry(program_hash).read()
        }

        // ========================= Core Functions ========================= //

        fn requestDataProcessorExecutionOfTask(
            ref self: ComponentState<TContractState>, module_task: ModuleTask,
        ) {
            let mut keccak_input = array![module_task.program_hash];
            for input in module_task.inputs {
                keccak_input.append(*input);
            }
            let task_commitment = reverse_endianness_u256(
                keccak_u256s_be_inputs(keccak_input.span()),
            );

            let cached_result = self.cachedTasksResult.entry(task_commitment);
            let cached_result_status = cached_result.status.read();
            if cached_result_status == TaskStatus::FINALIZED {
                self.emit(Event::TaskAlreadyStored(TaskAlreadyStored { task_commitment }));
            } else {
                // Ensure task is not already scheduled
                assert(cached_result_status == TaskStatus::NONE, 'DOUBLE_REGISTRATION');

                // Store the task result
                cached_result.write(TaskResult { status: TaskStatus::SCHEDULED, result: 0 });

                self.emit(Event::ModuleTaskScheduled(ModuleTaskScheduled { module_task }));
            }
        }

        fn authenticateDataProcessorTaskExecution(
            ref self: ComponentState<TContractState>, task_data: TaskData,
        ) {
            let task_hash = u256 { low: task_data.task_hash_low, high: task_data.task_hash_high };

            assert(
                self.cachedTasksResult.entry(task_hash).status.read() != TaskStatus::FINALIZED,
                'TaskAlreadyFinalized',
            );

            assert(self.isProgramHashAuthorized(task_data.program_hash), 'UnauthorizedProgramHash');

            // Initialize an array of uint256 to store the program output
            let mut program_output: Array<felt252> = array![];

            // Assign values to the program output array
            // This needs to be compatible with cairo program
            // https://github.com/HerodotusDev/hdp-cairo/blob/main/src/utils/utils.cairo#L27-L48
            program_output.append(task_data.task_hash_low.into());
            program_output.append(task_data.task_hash_high.into());
            program_output.append(task_data.task_result_low.into());
            program_output.append(task_data.task_result_high.into());
            program_output.append(task_data.mmr_collection.poseidon_mmr.len().into());
            program_output.append(task_data.mmr_collection.keccak_mmr.len().into());

            let state = get_dep_component!(@self, State);
            for mmr in task_data.mmr_collection.poseidon_mmr {
                let mmr_root = state
                    .mmrs
                    .entry(*mmr.chain_id)
                    .entry(*mmr.mmr_id)
                    .entry(POSEIDON_HASHING_FUNCTION)
                    .mmr_size_to_root
                    .entry(*mmr.mmr_size)
                    .read();
                assert(mmr_root != 0, 'InvalidMmrRoot');
                program_output.append((*mmr.mmr_id).try_into().expect('mmr_id not felt252'));
                program_output.append((*mmr.mmr_size).try_into().expect('mmr_size not felt252'));
                program_output.append((*mmr.chain_id).try_into().expect('chain_id not felt252'));
                program_output.append(mmr_root.try_into().expect('mmr_root not felt252'));
            }

            for mmr in task_data.mmr_collection.keccak_mmr {
                let mmr_root = state
                    .mmrs
                    .entry(*mmr.chain_id)
                    .entry(*mmr.mmr_id)
                    .entry(KECCAK_HASHING_FUNCTION)
                    .mmr_size_to_root
                    .entry(*mmr.mmr_size)
                    .read();
                assert(mmr_root != 0, 'InvalidMmrRoot');
                program_output.append((*mmr.mmr_id).try_into().expect('mmr_id not felt252'));
                program_output.append((*mmr.mmr_size).try_into().expect('mmr_size not felt252'));
                program_output.append((*mmr.chain_id).try_into().expect('chain_id not felt252'));

                // Split 256-bit root into two 128-bit limbs
                let mmr_root_low: u128 = mmr_root.low;
                let mmr_root_high: u128 = mmr_root.high;

                program_output.append(mmr_root_low.try_into().expect('mmr_root_low not felt252'));
                program_output.append(mmr_root_high.try_into().expect('mmr_root_high not felt252'));
            }

            let fact_hash = calculate_bootloaded_fact_hash(
                SHARP_BOOTLOADER_PROGRAM_HASH, task_data.program_hash, program_output.span(),
            );

            let cairo_fact_registry = get_dep_component!(@self, CairoFactRegistry);
            assert(cairo_fact_registry.isCairoFactValidForInternal(fact_hash), 'Invalid fact');

            let task_result = u256 {
                low: task_data.task_result_low, high: task_data.task_result_high,
            };

            // Store the task result
            self
                .cachedTasksResult
                .entry(task_hash)
                .write(TaskResult { status: TaskStatus::FINALIZED, result: task_result });
            self.emit(Event::TaskFinalized(TaskFinalized { task_hash, task_result }));
        }

        fn getDataProcessorTaskStatus(
            self: @ComponentState<TContractState>, task_commitment: u256,
        ) -> TaskStatus {
            self.cachedTasksResult.entry(task_commitment).status.read()
        }

        fn getDataProcessorFinalizedTaskResult(
            self: @ComponentState<TContractState>, task_commitment: u256,
        ) -> u256 {
            let task_result = self.cachedTasksResult.entry(task_commitment).read();

            // Ensure task is finalized
            assert(task_result.status == TaskStatus::FINALIZED, 'TASK_NOT_FINALIZED');

            task_result.result
        }
    }
}
