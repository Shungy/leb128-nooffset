// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LEB128Lib} from "../../src/LEB128Lib.sol";
import {EncodedCalldataERC20} from "../../src/examples/EncodedCalldataERC20.sol";

contract EncodedCalldataERC20Test is Test {
    EncodedCalldataERC20 public token;

    function setUp() public {
        token = new EncodedCalldataERC20();

        deal(address(token), address(this), type(uint256).max);
    }

    function testApprove(address to, uint256 amount) public {
        vm.assume(to != address(this));
        vm.assume(to != address(0));

        bytes memory data =
            abi.encodePacked(hex"00", LEB128Lib.encode(uint160(to)), LEB128Lib.encode(amount));

        (bool result, bytes memory returnData) = address(token).call{value: 0}(data);
        assertTrue(result);
        assertTrue(abi.decode(returnData, (bool)));

        assertEq(token.allowance(address(this), to), amount);
    }

    function testTransfer(address to, uint256 amount) public {
        vm.assume(to != address(this));
        vm.assume(to != address(0));

        bytes memory data =
            abi.encodePacked(hex"01", LEB128Lib.encode(uint160(to)), LEB128Lib.encode(amount));

        (bool result, bytes memory returnData) = address(token).call{value: 0}(data);
        assertTrue(result);
        assertTrue(abi.decode(returnData, (bool)));

        assertEq(token.balanceOf(to), amount);
        assertEq(token.balanceOf(address(this)), type(uint256).max - amount);
    }
}
