// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";
import {IL1ToArbitrumMessagesSenderModule} from "interfaces/modules/x-rollup-messaging/outbox/IL1ToArbitrumMessagesSenderModule.sol";

contract L1ToArbitrumMessagesSenderModule is IL1ToArbitrumMessagesSenderModule {
    function sendMessageL1ToArbitrum(address satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable {
        LibSatellite.enforceIsSatelliteModule();

        (uint256 l2GasLimit, uint256 maxFeePerGas, uint256 maxSubmissionCost) = abi.decode(_xDomainMsgGasData, (uint256, uint256, uint256));
        IArbitrumInbox(inboxAddress).createRetryableTicket{value: msg.value}(satelliteAddress, 0, maxSubmissionCost, msg.sender, address(0), l2GasLimit, maxFeePerGas, _data);
    }
}
