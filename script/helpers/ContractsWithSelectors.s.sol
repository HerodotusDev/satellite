// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

contract ContractsWithSelectors is Script {
    string CONTRACTS_WITH_SELECTORS = "out/contracts-with-selectors.json";
    string contractsWithSelectors;

    constructor() {
        contractsWithSelectors = vm.readFile(CONTRACTS_WITH_SELECTORS);
    }

    function getSelectors(string memory contractName) public view returns (bytes4[] memory selectors) {
        bytes memory selectorsBytes = vm.parseJson(contractsWithSelectors, string.concat(".", contractName));
        selectors = _convertBytesArrayToBytes4Array(abi.decode(selectorsBytes, (bytes[])));
    }

    function _convertBytesArrayToBytes4Array(bytes[] memory byteArray) internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](byteArray.length);

        for (uint256 i = 0; i < byteArray.length; i++) {
            require(byteArray[i].length == 4, "Element is not 4 bytes long");
            selectors[i] = bytes4(byteArray[i]);
        }
    }
}
