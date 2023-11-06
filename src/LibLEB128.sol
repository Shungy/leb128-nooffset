// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibLEB128 {
    using LibLEB128 for bytes;

    // bool is simply extracted from the byte.
    // uint8 is decoded like bool, different to other uints.
    // `uint*` bar `uint8` are decoded using unsigned LEB128 algorithm. Anything overflowing is silently truncated.

    // Decode until we get LEB128 stop bit, even if we go beyond type size limit. We do this to make sure the new
    // offset is properly calculated. Then silently truncate anything overflowing. Only revert if we are out of `data`.
    function decodeUint(bytes calldata data) internal pure returns (uint256 result, bytes calldata unconsumedData) {
        uint256 size;
        assembly ("memory-safe") {
            let ptr := data.offset
            for { let bitSize := 0 } 1 {} {
                let nextByte := byte(0, calldataload(ptr))
                if eq(bitSize, 252) {
                    if and(nextByte, 0xf0) {
                        revert(0, 0)
                    }
                }
                result := or(result, shl(bitSize, and(nextByte, 0x7f)))
                ptr := add(ptr, 1)
                bitSize := add(bitSize, 7)
                if iszero(shr(7, nextByte)) { break }
            }
            size := sub(ptr, data.offset)
        }
        unconsumedData = data[size:];
    }

    function decodeBytes(bytes calldata data)
        internal
        pure
        returns (bytes memory result, bytes calldata unconsumedData)
    {
        uint256 length;
        (length, unconsumedData) = data.decodeUint();
        result = new bytes(length);
        assembly ("memory-safe") {
            calldatacopy(add(result, 0x20), unconsumedData.offset, length)
        }
        unconsumedData = unconsumedData[length:];
    }

    function decodeString(bytes calldata data) internal pure returns (string memory result, bytes calldata unconsumedData) {
        bytes memory intermediate;
        (intermediate, unconsumedData) = data.decodeBytes();
        result = string(intermediate);
    }

    function decodeBool(bytes calldata data) internal pure returns (bool result, bytes calldata unconsumedData) {
        assembly ("memory-safe") {
            result := iszero(iszero(byte(0, calldataload(data.offset))))
        }
        unconsumedData = data[1:];
    }

    function decodeUint8(bytes calldata data) internal pure returns (uint8 result, bytes calldata unconsumedData) {
        assembly ("memory-safe") {
            result := byte(0, calldataload(data.offset))
        }
        unconsumedData = data[1:];
    }

    function decodeUint16(bytes calldata data) internal pure returns (uint16 result, bytes calldata unconsumedData) {
        uint256 intermediate;
        (intermediate, unconsumedData) = data.decodeUint();
        require(intermediate <= type(uint16).max);
        result = uint16(intermediate);
    }

    // We can fill the inbetween uint16 and uint248 later. basically the same shit as above and below.

    function decodeUint248(bytes calldata data) internal pure returns (uint248 result, bytes calldata unconsumedData) {
        uint256 intermediate;
        (intermediate, unconsumedData) = data.decodeUint();
        require(intermediate <= type(uint248).max);
        result = uint248(intermediate);
    }

    function decodeUint256(bytes calldata data) internal pure returns (uint256 result, bytes calldata unconsumedData) {
        (result, unconsumedData) = data.decodeUint();
    }
}
