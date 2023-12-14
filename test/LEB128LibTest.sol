// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LEB128Lib} from "../src/LEB128Lib.sol";

import {LibBit} from "solady/utils/LibBit.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

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

    function _encodedUintLength(uint256 x) internal pure returns (uint256) {
        return x == 0 ? 1 : FixedPointMathLib.divUp(LibBit.fls(x) + 1, 7);
    }

    function _encodedIntLength(int256 x) internal pure returns (uint256) {
        uint256 deSigned = x < 0 ? uint256(-(x + 1)) + 1 : uint256(x);
        return x == 0 ? 1 : FixedPointMathLib.divUp(LibBit.fls(deSigned) + 2, 7);
    }

    function _uleb128encodejs(uint256 x) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "test/utils/uleb128encode.js";
        inputs[2] = vm.toString(x);
        return vm.ffi(inputs);
    }

    function _sleb128encodejs(int256 x) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "test/utils/sleb128encode.js";
        inputs[2] = vm.toString(x);
        return vm.ffi(inputs);
    }

    function testEncodeUint(uint256 x) public {
        assertEq(leb128.encode(x), _uleb128encodejs(x));
    }

    function testEncodeInt(int256 x) public {
        assertEq(leb128.encode(x), _sleb128encodejs(x));
    }

    function testRawDecodeUint(uint256 x) public {
        bytes memory encoded = leb128.encode(x);
        (uint256 decoded,) = leb128.rawDecodeUint(encoded);
        assertEq(decoded, x);
    }

    function testRawDecodeInt(int256 x) public {
        bytes memory encoded = leb128.encode(x);
        (int256 decoded,) = leb128.rawDecodeInt(encoded);
        assertEq(decoded, x);
    }

    function testMemDecodeUint(uint256 x) public {
        bytes memory encoded = leb128.encode(x);
        (uint256 decoded,) = LEB128Lib.memDecodeUint(encoded);
        assertEq(decoded, x);
    }

    function testMemDecodeInt(int256 x) public {
        bytes memory encoded = leb128.encode(x);
        (int256 decoded,) = LEB128Lib.memDecodeInt(encoded);
        assertEq(decoded, x);
    }

    function testSignedEncode() public {
        assertEq(LEB128Lib.encode(int256(0)), hex"00");
        assertEq(LEB128Lib.encode(int256(1)), hex"01");
        assertEq(LEB128Lib.encode(int256(-1)), hex"7f");
        assertEq(LEB128Lib.encode(int256(69)), hex"c500");
        assertEq(LEB128Lib.encode(int256(-69)), hex"bb7f");
        assertEq(LEB128Lib.encode(int256(420)), hex"a403");
        assertEq(LEB128Lib.encode(int256(-420)), hex"dc7c");
        assertEq(LEB128Lib.encode(int256(1 ether)), hex"808090bbbad6adf00d");
        assertEq(LEB128Lib.encode(int256(-1 ether)), hex"8080f0c4c5a9d28f72");
        assertEq(
            LEB128Lib.encode(int256(type(int256).max - 1)),
            hex"feffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff07"
        );
        assertEq(
            LEB128Lib.encode(int256(type(int256).min + 1)),
            hex"81808080808080808080808080808080808080808080808080808080808080808080808078"
        );
        assertEq(
            LEB128Lib.encode(int256(type(int256).max)),
            hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff07"
        );
        assertEq(
            LEB128Lib.encode(int256(type(int256).min)),
            hex"80808080808080808080808080808080808080808080808080808080808080808080808078"
        );
    }

    function testUnsignedEncode() public {
        assertEq(LEB128Lib.encode(uint256(0)), hex"00");
        assertEq(LEB128Lib.encode(uint256(1)), hex"01");
        assertEq(LEB128Lib.encode(uint256(69)), hex"45");
        assertEq(LEB128Lib.encode(uint256(420)), hex"a403");
        assertEq(LEB128Lib.encode(uint256(666)), hex"9a05");
        assertEq(LEB128Lib.encode(uint256(1 ether)), hex"808090bbbad6adf00d");
        assertEq(
            LEB128Lib.encode(type(uint256).max - 1),
            hex"feffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0f"
        );
        assertEq(
            LEB128Lib.encode(type(uint256).max),
            hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0f"
        );
    }

    function testUnsignedEncodeLength(uint256 x) public {
        vm.assume(x != 0);
        assertEq(LEB128Lib.encode(x).length, _encodedUintLength(x));
    }

    function testSignedEncodeLength(int256 x) public {
        vm.assume(x != 0);
        assertEq(LEB128Lib.encode(x).length, _encodedIntLength(x));
    }

    function testEncodeDecode(uint256 x) public {
        bytes memory uencoded = LEB128Lib.encode(x);
        bytes memory sencoded = LEB128Lib.encode(int256(x));

        {
            (uint256 decoded, bytes memory rem) = leb128.decodeUint(uencoded);
            assertEq(decoded, x);
            assertEq(rem.length, 0);
        }
        {
            (int256 decoded, bytes memory rem) = leb128.decodeInt(sencoded);
            assertEq(decoded, int256(x));
            assertEq(rem.length, 0);
        }
        {
            (uint256 decoded, uint256 size) = LEB128Lib.memDecodeUint(uencoded);
            assertEq(decoded, x);
            assertEq(size, _encodedUintLength(x));
        }
        {
            (int256 decoded, uint256 size) = LEB128Lib.memDecodeInt(sencoded);
            assertEq(decoded, int256(x));
            assertEq(size, _encodedIntLength(int256(x)));
        }
    }

    // Empty input revert for high level decoding methods.
    function testRevertOnEmptyInput() public {
        vm.expectRevert();
        leb128.decodeUint(hex"");

        vm.expectRevert();
        leb128.decodeInt(hex"");

        vm.expectRevert();
        LEB128Lib.memDecodeUint(hex"");

        vm.expectRevert();
        LEB128Lib.memDecodeInt(hex"");
    }

    // Out of bounds revert for high level decoding methods.
    function testRevertOnOutOfBoundsDecoding(uint256 x) public {
        bytes memory uencoded = LEB128Lib.encode(x);
        bytes memory sencoded = LEB128Lib.encode(int256(x));

        uencoded[uencoded.length - 1] ^= 0x80;
        sencoded[sencoded.length - 1] ^= 0x80;

        vm.expectRevert();
        leb128.decodeUint(uencoded);

        vm.expectRevert();
        leb128.decodeInt(sencoded);

        vm.expectRevert();
        LEB128Lib.memDecodeUint(uencoded);

        vm.expectRevert();
        LEB128Lib.memDecodeInt(sencoded);
    }

    // No out of bounds revert for raw decoding methods.
    function testNoRevertOnOutOfBoundsRawDecoding(uint256 x) public view {
        bytes memory uencoded = LEB128Lib.encode(x);
        bytes memory sencoded = LEB128Lib.encode(int256(x));

        uint256 uencodedPtr;
        uint256 sencodedPtr;
        /// @solidity memory-safe-assembly
        assembly {
            uencodedPtr := add(uencoded, 0x20)
            sencodedPtr := add(sencoded, 0x20)
        }

        uencoded[uencoded.length - 1] ^= 0x80;
        sencoded[sencoded.length - 1] ^= 0x80;

        leb128.rawDecodeUint(uencoded);
        leb128.rawDecodeInt(sencoded);
        LEB128Lib.rawMemDecodeUint(uencodedPtr);
        LEB128Lib.rawMemDecodeInt(sencodedPtr);
    }

    function testBenchBE128CompressDecompress() public {
        // Test that encoding these values takes 72 bytes.
        uint256[] memory a = new uint256[](21);
        a[0] = 0x0000000000000000000000000000000000000000000000000000000000000020;
        a[1] = 0x000000000000000000000000ca1694433e499862ee242f2f403cb1e73ae91cfb;
        a[2] = 0x0000000000000000000000000000000000000000000000000000000000000001;
        a[3] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[4] = 0x0000000000000000000000001f5d295778796a8b9f29600a585ab73d452acb1c;
        a[5] = 0x0000000000000000000000000000000000000000000000000000000000000001;
        a[6] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[7] = 0x00000000000000000000000000000000000000000000000000000000ffffffff;
        a[8] = 0x0000000000000000000000000000000000000000000000000000000000000200;
        a[9] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[10] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[11] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[12] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[13] = 0x0000000000000000000000000000000000000000000000000000000000000220;
        a[14] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[15] = 0x0000000000000000000000000000000000000000000000000000000000000260;
        a[16] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[17] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[18] = 0x0000000000000000000000000000000000000000000000000000000000000014;
        a[19] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        a[20] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes memory encodedData;
        for (uint256 i; i < a.length; ++i) {
            encodedData = abi.encodePacked(encodedData, LEB128Lib.encode(a[i]));
        }
        assertEq(encodedData.length, 72);

        // Test that we can decode these values.
        uint256 ptr;
        assembly {
            ptr := add(encodedData, 0x20)
        }
        for (uint256 i; i < a.length; ++i) {
            uint256 result;
            (result, ptr) = LEB128Lib.rawMemDecodeUint(ptr);
            assertEq(result, a[i]);
        }
    }
}
