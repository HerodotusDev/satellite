// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IAggregatorsFactory {
    error AccessControlBadConfirmation();
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error ERC1167FailedCreateClone();

    event AggregatorCreation(address aggregator, uint256 newAggregatorId, uint256 detachedFromAggregatorId);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Upgrade(address oldTemplate, address newTemplate);
    event UpgradeProposal(address newTemplate);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint256);

    function KECCAK_MMR_INITIAL_ROOT() external view returns (bytes32);

    function OPERATOR_ROLE() external view returns (bytes32);

    function POSEIDON_MMR_INITIAL_ROOT() external view returns (bytes32);

    function aggregatorsById(uint256) external view returns (address);

    function aggregatorsCount() external view returns (uint256);

    function createAggregator(uint256 aggregatorId) external returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function proposeUpgrade(address newTemplate) external;

    function renounceRole(bytes32 role, address callerConfirmation) external;

    function revokeRole(bytes32 role, address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function template() external view returns (address);

    function upgrade(uint256 updateId) external;

    function upgrades(uint256) external view returns (uint256 timestamp, address newTemplate);

    function upgradesCount() external view returns (uint256);
}
