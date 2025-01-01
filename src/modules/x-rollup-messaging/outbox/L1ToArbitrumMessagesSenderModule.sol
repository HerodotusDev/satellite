// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

// import {ISharpProofsAggregator} from "../../interfaces/ISharpProofsAggregator.sol";
// import {ISharpProofsAggregatorsFactory} from "../../interfaces/ISharpProofsAggregatorsFactory.sol";
// import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";
import {IArbitrumInbox} from "../../../interfaces/external/IArbitrumInbox.sol";
import {ISatellite} from "../../../interfaces/ISatellite.sol";
import {LibSatellite} from "../../../libraries/LibSatellite.sol";
import {IL1ToArbitrumMessagesSenderModule} from "src/interfaces/modules/x-rollup-messaging/outbox/IL1ToArbitrumMessagesSenderModule.sol";

contract L1ToArbitrumMessagesSenderModule is IL1ToArbitrumMessagesSenderModule {
    /// @notice Set the Arbitrum Inbox and Satellite addresses
    /// @param arbitrumInbox address of Arbitrum Inbox contract deployed on Sepolia
    /// @param arbitrumSatellite address of Satellite contract deployed on Arbitrum
    function configure(address arbitrumInbox, address arbitrumSatellite) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.arbitrumSatellite == address(0), "ARB_SAT_ALREADY_SET");
        s.arbitrumInbox = arbitrumInbox;
        s.arbitrumSatellite = arbitrumSatellite;
    }

    /// @notice Send parent hash that was registered on L1 to Arbitrum
    /// @param chainId the chain ID of the block whose parent hash is being sent
    /// @param hashingFunction the hashing function used to hash the parent hash
    /// @param blockNumber the number of block being sent
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination L2
    function sendParentHashL1ToArbitrum(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external payable {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        bytes32 parentHash = s.receivedParentHashes[chainId][hashingFunction][blockNumber];

        require(parentHash != bytes32(0), "ERR_BLOCK_NOT_REGISTERED");

        _sendMessage(
            s.arbitrumSatellite,
            abi.encodeWithSignature("receiveHashForBlock(uint256,bytes32,uint256,bytes32)", chainId, hashingFunction, blockNumber, parentHash),
            _xDomainMsgGasData
        );
    }

    // function sendMMRL1ToArbitrum(uint256 newMmrId, )

    // function sendKeccakMMRTreeToL2(uint256 aggregatorId, uint256 newMmrId, bytes calldata _xDomainMsgGasData) external payable {
    //     address existingAggregatorAddr = proofsAggregatorsFactory.aggregatorsById(aggregatorId);
    //     require(existingAggregatorAddr != address(0), "Unknown aggregator");
    //     ISharpProofsAggregator aggregator = ISharpProofsAggregator(existingAggregatorAddr);

    //     bytes32 keccakMMRRoot = aggregator.getMMRKeccakRoot();
    //     uint256 mmrSize = aggregator.getMMRSize();

    //     // Ensure initialized aggregator
    //     require(mmrSize >= 1, "Invalid tree size");
    //     require(keccakMMRRoot != bytes32(0), "Invalid root (keccak)");

    //     _sendMessage(l2Target, abi.encodeWithSignature("receiveKeccakMMR(uint256,uint256,bytes32,uint256)", aggregatorId, mmrSize, keccakMMRRoot, newMmrId), _xDomainMsgGasData);
    // }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        (uint256 l2GasLimit, uint256 maxFeePerGas, uint256 maxSubmissionCost) = abi.decode(_xDomainMsgGasData, (uint256, uint256, uint256));
        IArbitrumInbox(s.arbitrumInbox).createRetryableTicket{value: msg.value}(_l2Target, 0, maxSubmissionCost, msg.sender, address(0), l2GasLimit, maxFeePerGas, _data);
    }
}
