// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {IArbitrumInbox} from "src/interfaces/external/IArbitrumInbox.sol";
import {IL1ToArbitrumSenderModule} from "src/interfaces/modules/messaging/sender/IL1ToArbitrumSenderModule.sol";
import {AccessController} from "src/libraries/AccessController.sol";

contract L1ToArbitrumSenderModule is IL1ToArbitrumSenderModule, AccessController {
    /// @inheritdoc IL1ToArbitrumSenderModule
    function sendMessageL1ToArbitrum(uint256 satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable onlyModule {
        (uint256 l2GasLimit, uint256 maxFeePerGas, uint256 maxSubmissionCost) = abi.decode(_xDomainMsgGasData, (uint256, uint256, uint256));

        IArbitrumInbox(inboxAddress).createRetryableTicket{value: msg.value}(
            address(uint160(satelliteAddress)),
            0,
            maxSubmissionCost,
            msg.sender,
            address(0),
            l2GasLimit,
            maxFeePerGas,
            _data
        );
    }
}
