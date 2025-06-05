// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {IApeChainInbox} from "src/interfaces/external/IApeChainInbox.sol";
import {IArbitrumToApeChainSenderModule} from "src/interfaces/modules/messaging/sender/IArbitrumToApeChainSenderModule.sol";
import {AccessController} from "src/libraries/AccessController.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ArbitrumToApeChainSenderModule is IArbitrumToApeChainSenderModule, AccessController {
    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.arbitrum-to-ape-chain-sender");

    function moduleStorage() internal pure returns (ArbitrumToApeChainSenderModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Owner-only Functions ========================= //

    /// @inheritdoc IArbitrumToApeChainSenderModule
    function setApeChainTokenAddress(address tokenAddress) external onlyOwner {
        ArbitrumToApeChainSenderModuleStorage storage ms = moduleStorage();
        ms.apeChainTokenAddress = tokenAddress;
    }

    // ========================= Module-only Functions ======================== //

    /// @inheritdoc IArbitrumToApeChainSenderModule
    function sendMessageArbitrumToApeChain(uint256 satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable onlyModule {
        ArbitrumToApeChainSenderModuleStorage storage ms = moduleStorage();
        address tokenAddress = ms.apeChainTokenAddress;

        (uint256 l3GasLimit, uint256 l3MaxFeePerGas, uint256 l3MaxSubmissionCost, uint256 tokenTotalFeeAmount) = abi.decode(
            _xDomainMsgGasData,
            (uint256, uint256, uint256, uint256)
        );

        IERC20(tokenAddress).approve(inboxAddress, tokenTotalFeeAmount);

        IApeChainInbox(inboxAddress).createRetryableTicket(
            address(uint160(satelliteAddress)),
            0,
            l3MaxSubmissionCost,
            address(this),
            address(0),
            l3GasLimit,
            l3MaxFeePerGas,
            tokenTotalFeeAmount,
            _data
        );
    }
}
