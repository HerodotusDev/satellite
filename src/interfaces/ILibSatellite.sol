// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

/// @notice This is IMMUTABLE! without re-deploying the whole Satellite Diamond!
interface ILibSatellite {
    // ========================= Types ========================= //

    struct Module {
        address moduleAddress;
        bytes4[] functionSelectors;
    }

    struct ModuleAddressAndPosition {
        address moduleAddress;
        uint96 functionSelectorPosition; // position in moduleFunctionSelectors.functionSelectors array
    }

    struct ModuleFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 moduleAddressPosition; // position of moduleAddress in moduleAddresses array
    }

    /// @dev Add=0, Replace=1, Remove=2
    enum ModuleMaintenanceAction {
        Add,
        Replace,
        Remove
    }

    struct ModuleMaintenance {
        address moduleAddress;
        ModuleMaintenanceAction action;
        bytes4[] functionSelectors;
    }

    /// @notice This struct represents a Merkle Mountain Range accumulating provably valid block hashes
    /// @dev each MMR is mapped to a unique ID also referred to as mmrId
    struct MMRInfo {
        /// @notice isSiblingSynced informs if the MMR has it's siblings and has to be grown in sync with them - used when growing off-chain and growring multiple hashing functions at once, for example, this could be a keccak MMR sibling synced to a poseidon MMR
        bool isSiblingSynced;
        /// @notice latestSize represents the latest size of the MMR
        uint256 latestSize;
        /// @notice mmrSizeToRoot maps the  MMR size => the MMR root, that way we have automatic versioning
        mapping(uint256 => bytes32) mmrSizeToRoot;
    }

    struct SatelliteStorage {
        // ========================= Diamond-related storage ========================= //

        /// @dev maps function selector to the module address and the position of the selector in the moduleFunctionSelectors.selectors array
        mapping(bytes4 => ModuleAddressAndPosition) selectorToModuleAndPosition;
        /// @dev maps module addresses to function selectors
        mapping(address => ModuleFunctionSelectors) moduleFunctionSelectors;
        /// @dev module addresses
        address[] moduleAddresses;
        /// @dev owner of the contract
        address contractOwner;
        // ========================= Core Satellite storage ========================= //

        /// @dev mapping of ChainId => MMR ID => hashing function => MMR info
        /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
        mapping(uint256 => mapping(uint256 => mapping(bytes32 => MMRInfo))) mmrs;
        /// @notice mapping of ChainId => hashing function => block number => block parent hash
        mapping(uint256 => mapping(bytes32 => mapping(uint256 => bytes32))) receivedParentHashes;
    }

    // ========================= Errors ========================= //

    /// @dev Error indicating the caller must be a satellite module
    error MustBeSatelliteModule();
    /// @dev Error indicating the caller must be the contract owner
    error MustBeContractOwner();
    /// @dev Error indicating the module maintenance action is incorrect
    error IncorrectModuleMaintenanceAction(ModuleMaintenanceAction action);
    /// @dev Error indicating there are no selectors in the module to maintenance
    error NoSelectorsInModuleToMaintenance();
    /// @dev Error indicating the module address is zero
    error AddModuleAddressZero();
    /// @dev Error indicating the function already exists
    error AddFunctionAlreadyExists(bytes4 selector);
    /// @dev Error indicating the function already exists
    error ReplaceFunctionWithSameFunction(bytes4 selector);
    /// @dev Error indicating the function does not exist
    error RemoveFunctionDoesNotExist();
    /// @dev Error indicating the function is immutable and cannot be removed
    error RemoveImmutableFunction();
    /// @dev Error indicating the init address is zero but calldata is not empty
    error InitAddressZeroButCalldataNotEmpty();
    /// @dev Error indicating the calldata is empty but init is not address(0)
    error CalldataEmptyButInitNotEmpty();
    /// @dev Error indicating the init function reverted
    error InitFunctionReverted(string errors);
    /// @dev Error indicating the address has no code
    error AddressHasNoCode(string details);

    // ========================= Events ========================= //

    /// @dev Event emitted when satellite maintenance occurs
    event SatelliteMaintenance(ModuleMaintenance[] _satelliteMaintenance, address _init, bytes _calldata);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
