// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IMessagesSenderModule {
    function configure(address chainMessenger, address satellite) external;
}
