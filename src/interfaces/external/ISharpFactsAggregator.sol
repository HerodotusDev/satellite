// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ISharpFactsAggregator {
    struct AggregatorState {
        bytes32 poseidonMmrRoot;
        bytes32 keccakMmrRoot;
        uint256 mmrSize;
        bytes32 continuableParentHash;
    }

    struct JobOutputPacked {
        uint256 blockNumbersPacked;
        bytes32 blockNPlusOneParentHash;
        bytes32 blockNMinusRPlusOneParentHash;
        bytes32 mmrPreviousRootPoseidon;
        bytes32 mmrPreviousRootKeccak;
        bytes32 mmrNewRootPoseidon;
        bytes32 mmrNewRootKeccak;
        uint256 mmrSizesPacked;
    }

    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AggregationBlockMismatch();
    error AggregationError(string message);
    error AlreadyInitialized();
    error GenesisBlockReached();
    error InvalidFact();
    error NotEnoughBlockConfirmations();
    error NotEnoughJobs();
    error NotInitializing();
    error TooManyBlocksConfirmations();
    error UnknownParentHash();

    event Aggregate(uint256 fromBlockNumberHigh, uint256 toBlockNumberLow, bytes32 poseidonMmrRoot, bytes32 keccakMmrRoot, uint256 mmrSize, bytes32 continuableParentHash);
    event Initialized(uint8 version);
    event NewRangeRegistered(uint256 targetBlock, bytes32 targetBlockParentHash);
    event OperatorRequirementChange(bool newRequirement);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function FACTS_REGISTRY() external view returns (address);

    function MAXIMUM_BLOCKS_CONFIRMATIONS() external view returns (uint256);

    function MINIMUM_BLOCKS_CONFIRMATIONS() external view returns (uint256);

    function OPERATOR_ROLE() external view returns (bytes32);

    function PROGRAM_HASH() external view returns (bytes32);

    function UNLOCKER_ROLE() external view returns (bytes32);

    function aggregateSharpJobs(uint256 rightBoundStartBlock, JobOutputPacked[] memory outputs) external;

    function aggregatorState() external view returns (bytes32 poseidonMmrRoot, bytes32 keccakMmrRoot, uint256 mmrSize, bytes32 continuableParentHash);

    function blockNumberToParentHash(uint256) external view returns (bytes32);

    function getMMRKeccakRoot() external view returns (bytes32);

    function getMMRPoseidonRoot() external view returns (bytes32);

    function getMMRSize() external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function initialize(AggregatorState memory initialAggregatorState) external;

    function isOperatorRequired() external view returns (bool);

    function registerNewRange(uint256 blocksConfirmations) external;

    function renounceRole(bytes32 role, address callerConfirmation) external;

    function revokeRole(bytes32 role, address account) external;

    function setOperatorRequired(bool _isOperatorRequired) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function verifyFact(uint256[] memory outputs) external view returns (bool);
}
