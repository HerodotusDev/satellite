// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

library Bitmap8 {
    function readBitAtIndexFromRight(uint8 bitmap, uint8 index) public pure returns (bool value) {
        require(index < 8, "ERR_OUR_OF_RANGE");
        return (bitmap & (1 << index)) != 0;
    }
}
