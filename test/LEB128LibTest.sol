// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LEB128Lib} from "../src/LEB128Lib.sol";

contract LEB128 {
    function encode(int256 x) external pure returns (bytes memory) {
        return LEB128Lib.encode(x);
    }

    function encode(uint256 x) external pure returns (bytes memory) {
        return LEB128Lib.encode(x);
    }

    function rawDecodeUint(bytes calldata input) external pure returns (uint256, uint256) {
        uint256 ptr;
        assembly {
            ptr := input.offset
        }
        return LEB128Lib.rawDecodeUint(ptr);
    }

    function rawDecodeInt(bytes calldata input) external pure returns (int256, uint256) {
        uint256 ptr;
        assembly {
            ptr := input.offset
        }
        return LEB128Lib.rawDecodeInt(ptr);
    }
}

contract LEB128LibTest is Test {
    LEB128 public leb128;

    function setUp() public {
        leb128 = new LEB128();
    }

    function uleb128encodejs(uint256 x) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "test/utils/uleb128encode.js";
        inputs[2] = vm.toString(x);
        return vm.ffi(inputs);
    }

    function sleb128encodejs(int256 x) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "test/utils/sleb128encode.js";
        inputs[2] = vm.toString(x);
        return vm.ffi(inputs);
    }

    function test_encodeUint(uint256 x) public {
        assertEq(leb128.encode(x), uleb128encodejs(x));
    }

    function test_encodeInt(int256 x) public {
        assertEq(leb128.encode(x), sleb128encodejs(x));
    }

    function test_rawDecodeUint(uint256 x) public {
        bytes memory encoded = leb128.encode(x);
        (uint256 decoded,) = leb128.rawDecodeUint(encoded);
        assertEq(decoded, x);
    }

    function test_rawDecodeInt(int256 x) public {
        bytes memory encoded = leb128.encode(x);
        (int256 decoded,) = leb128.rawDecodeInt(encoded);
        assertEq(decoded, x);
    }

    function test_memDecodeUint(uint256 x) public {
        bytes memory encoded = leb128.encode(x);
        (uint256 decoded,) = LEB128Lib.memDecodeUint(encoded);
        assertEq(decoded, x);
    }

    function test_memDecodeInt(int256 x) public {
        bytes memory encoded = leb128.encode(x);
        (int256 decoded,) = LEB128Lib.memDecodeInt(encoded);
        assertEq(decoded, x);
    }
}
