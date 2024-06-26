// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Pixel8NftTestBase } from "./Pixel8NftTestBase.sol";
import { GoodERC721Receiver } from "../utils/TestBase01.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract Pixel8NftBatchTransferRange is Pixel8NftTestBase {
  function setUp() public override {
    super.setUp();

    vm.prank(owner1);
    pixel8.setPool(pool1);

    vm.startPrank(pool1);
    pixel8.batchMint(wallet1, 1, 4);
    pixel8.batchMint(wallet2, 5, 1);
    vm.stopPrank();
  }

  function test_Pixel8NftBatchTransferRange_ByOwner_Succeeds() public {
    vm.prank(wallet1);
    pixel8.batchTransferRange(wallet1, wallet2, 2);

    assertEq(pixel8.ownerOf(1), wallet1);
    assertEq(pixel8.ownerOf(2), wallet1);
    assertEq(pixel8.ownerOf(3), wallet2);
    assertEq(pixel8.ownerOf(4), wallet2);
    assertEq(pixel8.ownerOf(5), wallet2);

    assertEq(pixel8.totalSupply(), 5);
    assertEq(pixel8.balanceOf(wallet1), 2);
    assertEq(pixel8.balanceOf(wallet2), 3);

    assertEq(pixel8.tokenOfOwnerByIndex(wallet1, 0), 1);
    assertEq(pixel8.tokenOfOwnerByIndex(wallet1, 1), 2);
    assertEq(pixel8.tokenOfOwnerByIndex(wallet2, 0), 5);
    assertEq(pixel8.tokenOfOwnerByIndex(wallet2, 1), 4);
    assertEq(pixel8.tokenOfOwnerByIndex(wallet2, 2), 3);
  }

  function test_Pixel8NftBatchTransferRange_ByPool_Succeeds() public {
    vm.prank(pool1);
    pixel8.batchTransferRange(wallet1, wallet2, 2);

    assertEq(pixel8.ownerOf(4), wallet2);
    assertEq(pixel8.ownerOf(3), wallet2);
  }

  function test_Pixel8NftBatchTransferRangeIfNotAuthorised_Fails() public {
    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 4));
    pixel8.batchTransferRange(wallet1, wallet2, 2);
  }

  function test_Pixel8NftBatchTransferRange_IfAllAuthorised_Succeeds() public {
    vm.startPrank(wallet1);
    pixel8.approve(wallet2, 4);
    pixel8.approve(wallet2, 3);
    vm.stopPrank();

    vm.prank(wallet2);
    pixel8.batchTransferRange(wallet1, wallet2, 2);

    assertEq(pixel8.ownerOf(4), wallet2);
    assertEq(pixel8.ownerOf(3), wallet2);
  }

  function test_Pixel8NftBatchTransferRange_IfNotAllAuthorised_Fails() public {
    vm.startPrank(wallet1);
    pixel8.approve(wallet2, 4);
    vm.stopPrank();

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 3));
    pixel8.batchTransferRange(wallet1, wallet2, 2);
  }

  function test_Pixel8NftBatchTransferRange_ToZeroAddress_Fails() public {
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721ZeroAddress.selector));
    pixel8.batchTransferRange(wallet1, address(0), 2);
  }

  function test_Pixel8NftBatchTransfer_InvokesReceiver() public {
    GoodERC721Receiver good = new GoodERC721Receiver();

    vm.prank(pool1);
    pixel8.batchTransferRange(wallet1, address(good), 2);

    GoodERC721Receiver.Received memory r = GoodERC721Receiver(good).getReceived(0);
    assertEq(r.operator, pool1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 4);
    assertEq(r.data, "");

    r = GoodERC721Receiver(good).getReceived(1);
    assertEq(r.operator, pool1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 3);
    assertEq(r.data, "");
  }
}
