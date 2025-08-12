// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IFaultDisputeGame, IDisputeGameFactory} from "../src/interfaces/modules/parent-hash-fetching/IOptimismParentHashFetcherModule.sol";
import {Lib_RLPReader} from "../src/libraries/external/optimism/rlp/Lib_RLPReader.sol";

contract OptimismParentHashFetcherModuleTest is Test {
    function test_OptimismFetchParentHash_Success() public view {
        uint256 gameIndex = 177;
        IDisputeGameFactory disputeGameFactory = IDisputeGameFactory(address(0xe5965Ab5962eDc7477C8520243A95517CD252fA9));
        address trustedGameProposer = 0x473300df21D047806A082244b417f96b32f13A33;
        bytes
            memory blockHeader = hex"f90245a040e73048087fca25ae73f38e37bb77aef9dc5d622ab3fed7c02f8d0e8eda3771a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347944200000000000000000000000000000000000011a08cd5c86564142d3020554cffa6b3591a6a8d2f7b8ec2d263863f29e0ab6de222a0947d56916131017aa9b0b825c5df87eb1dba7abe2e64af928af19aefe19d15f9a0c7ab6c66f4cd77d512ee6f05293bee8d5ca8373b1f4c3f78ef93a0d2e5a25e11b901009009a20811241081800105868000c040818122180240000a000401006060400005881000200600010040001420002800048110c00102340280200040006c2b4122a00020021010083030090800823c0101822c00004400200000001080a04000100440454214000060011a0004004800003c10471000060011000336810a041180011040280400010128030030020100021050009020002020020002420a40020300200450802c041001000000c02080060870900000820008410100844801006202500b00000402974000360021140008a0000406a88608040024060a102a040030400b0221000080086048000001028580840009e3098000600800000d24088084073e52508401c9c380833a194f8466707e5980a0b082f25e221d6afde1bde578a17c505cc1dbbb22308aea8c5da45bb0a45eae42880000000000000000840396dd41a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b4218080a094acc027205dbe6f346931a354cd7db875a51bc4f876f18452046e552b14e13e";
        bytes32 stateRoot = 0x8cd5c86564142d3020554cffa6b3591a6a8d2f7b8ec2d263863f29e0ab6de222;
        bytes32 withdrawalStorageRoot = 0x8ebc68365e414b7382e25ceed949cd8cbdf68c69e760c84d2c38ffe009452f54;
        bytes32 versionByte = 0x0000000000000000000000000000000000000000000000000000000000000000;

        (, , address proxy) = disputeGameFactory.gameAtIndex(gameIndex);
        require(proxy != address(0), "ERR_GAME_NOT_FOUND");

        IFaultDisputeGame game = IFaultDisputeGame(proxy);
        uint8 status = game.status();

        if (status == 1) {
            revert("ERR_GAME_FAILED");
        } else if (status == 0 && game.gameCreator() != trustedGameProposer) {
            revert("ERR_UNFINISHED_GAME_NOT_TRUSTED");
        } else if (status != 2) {
            revert("ERR_UNKNOWN_GAME_STATUS");
        }

        bytes32 rootClaim = game.rootClaim();

        bytes32 blockHash = keccak256(blockHeader);
        bytes memory payload = abi.encode(stateRoot, withdrawalStorageRoot, blockHash);
        console.logBytes(payload);
        // should be:
        console.logBytes(
            hex"8cd5c86564142d3020554cffa6b3591a6a8d2f7b8ec2d263863f29e0ab6de2228ebc68365e414b7382e25ceed949cd8cbdf68c69e760c84d2c38ffe009452f54c72e9ee468bcf8d5832cb48eec27270e1675d25a32bd7e90b299bcffd730f3e2"
        );

        bytes memory fullInput = bytes.concat(bytes32(versionByte), payload);
        console.logBytes(fullInput);
        // should be:
        console.logBytes(
            hex"00000000000000000000000000000000000000000000000000000000000000008cd5c86564142d3020554cffa6b3591a6a8d2f7b8ec2d263863f29e0ab6de2228ebc68365e414b7382e25ceed949cd8cbdf68c69e760c84d2c38ffe009452f54c72e9ee468bcf8d5832cb48eec27270e1675d25a32bd7e90b299bcffd730f3e2"
        );

        bytes32 calculatedRoot = keccak256(fullInput);
        console.logBytes32(calculatedRoot);
        console.logBytes32(rootClaim);

        require(rootClaim == calculatedRoot, "ERR_ROOT_CLAIM_MISMATCH");

        uint256 blockNumber = _decodeBlockNumber(blockHeader);

        require(blockNumber == 121524816, "ERR_BLOCK_NUMBER_MISMATCH");
    }

    function _decodeBlockNumber(bytes memory headerRlp) internal pure returns (uint256) {
        Lib_RLPReader.RLPItem[] memory items = Lib_RLPReader.readList(Lib_RLPReader.toRLPItem(headerRlp));
        return Lib_RLPReader.readUint256(items[8]);
    }
}
