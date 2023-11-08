// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode and decode numbers with LEB128: https://en.wikipedia.org/wiki/LEB128
/// @author shung (https://github.com/Shungy)
library LEB128Lib {
    /// @dev Encodes `x` using Unsigned LEB128 algorithm.
    /// See: https://en.wikipedia.org/wiki/LEB128#Encode_unsigned_integer
    function encode(uint256 x) internal pure returns (bytes memory result) {
        if (x == 0) return result = new bytes(1);
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let offset := add(result, 32)
            let i := offset
            for {} 1 {} {
                let nextByte := and(x, 0x7f)
                x := shr(7, x)
                switch x
                case 0 {
                    mstore8(i, nextByte)
                    i := add(i, 1)
                    break
                }
                default {
                    nextByte := or(nextByte, 0x80)
                    mstore8(i, nextByte)
                    i := add(i, 1)
                }
            }
            mstore(result, sub(i, offset))
            mstore(0x40, i)
        }
    }

    /// @dev Encodes `x` using Signed LEB128 algorithm.
    /// See: https://en.wikipedia.org/wiki/LEB128#Encode_signed_integer
    function encode(int256 x) internal pure returns (bytes memory result) {
        if (x == 0) return result = new bytes(1);
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let offset := add(result, 32)
            let i := offset
            for {} 1 {} {
                let nextByte := and(x, 0x7f)
                x := sar(7, x)
                switch or(
                    and(iszero(x), iszero(and(nextByte, 0x40))),
                    and(iszero(add(x, 1)), iszero(iszero(and(nextByte, 0x40))))
                )
                case 1 {
                    mstore8(i, nextByte)
                    i := add(i, 1)
                    break
                }
                default {
                    nextByte := or(nextByte, 0x80)
                    mstore8(i, nextByte)
                    i := add(i, 1)
                }
            }
            mstore(result, sub(i, offset))
            mstore(0x40, i)
        }
    }

    /// @dev Decodes an Unsigned LEB128 encoded value, starting from calldata `ptr`.
    /// See: https://en.wikipedia.org/wiki/LEB128#Decode_unsigned_integer
    /// Note: Anything overflowing is truncated silently without a revert.
    /// Note: Superfluous zero padding can be used to control the length of the encoded data.
    function rawDecodeUint(uint256 ptr) internal pure returns (uint256 result, uint256 newPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let shift := 0 } 1 { shift := add(shift, 7) } {
                let nextByte := byte(0, calldataload(ptr))
                result := or(result, shl(shift, and(nextByte, 0x7f)))
                ptr := add(ptr, 1)
                if iszero(shr(7, nextByte)) { break }
            }
            newPtr := ptr
        }
    }

    /// @dev Decodes a Signed LEB128 encoded value, starting from calldata `ptr`.
    /// See: https://en.wikipedia.org/wiki/LEB128#Decode_signed_integer
    /// Note: Same caveats as `rawDecodeUint` apply.
    function rawDecodeInt(uint256 ptr) internal pure returns (int256 result, uint256 newPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let shift := 0 } 1 {} {
                let nextByte := byte(0, calldataload(ptr))
                result := or(result, shl(shift, and(nextByte, 0x7f)))
                ptr := add(ptr, 1)
                shift := add(shift, 7)
                if iszero(shr(7, nextByte)) {
                    if and(lt(shift, 256), iszero(iszero(and(nextByte, 0x40)))) {
                        result := or(result, shl(shift, not(0)))
                    }
                    break
                }
            }
            newPtr := ptr
        }
    }

    /// @dev Decodes an Unsigned LEB128 encoded value, starting from memory `ptr`.
    /// Note: Same caveats as `rawDecodeUint` apply.
    /// Note: It is less optimized than its calldata equivalent `rawDecodeUint`.
    function rawMemDecodeUint(uint256 ptr) internal pure returns (uint256 result, uint256 newPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let shift := 0 } 1 { shift := add(shift, 7) } {
                let nextByte := byte(0, mload(ptr))
                result := or(result, shl(shift, and(nextByte, 0x7f)))
                ptr := add(ptr, 1)
                if iszero(shr(7, nextByte)) { break }
            }
            newPtr := ptr
        }
    }

    /// @dev Decodes a Signed LEB128 encoded value, starting from memory `ptr`.
    /// Note: Same caveats as `rawDecodeUint` apply.
    /// Note: It is less optimized than its calldata equivalent `rawDecodeInt`.
    function rawMemDecodeInt(uint256 ptr) internal pure returns (int256 result, uint256 newPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let shift := 0 } 1 {} {
                let nextByte := byte(0, mload(ptr))
                result := or(result, shl(shift, and(nextByte, 0x7f)))
                ptr := add(ptr, 1)
                shift := add(shift, 7)
                if iszero(shr(7, nextByte)) {
                    if and(lt(shift, 256), iszero(iszero(and(nextByte, 0x40)))) {
                        result := or(result, shl(shift, not(0)))
                    }
                    break
                }
            }
            newPtr := ptr
        }
    }

    /// @dev Decodes an Unsigned LEB128 encoded value from the beginning of calldata `data`.
    /// Note: Same caveats as `rawDecodeUint` apply.
    /// Note: Reverts if decoding is not completed within the bounds of `data`.
    /// @return result The decoded unsigned integer value.
    /// @return remainingData Unconsumed part of `data`.
    function decodeUint(bytes calldata data)
        internal
        pure
        returns (uint256 result, bytes calldata remainingData)
    {
        uint256 ptr;
        /// @solidity memory-safe-assembly
        assembly {
            ptr := data.offset
        }
        uint256 newPtr;
        (result, newPtr) = rawDecodeUint(ptr);
        unchecked {
            remainingData = data[newPtr - ptr:];
        }
    }

    /// @dev Decodes a Signed LEB128 encoded value from the beginning of calldata `data`.
    /// Note: Same caveats as `rawDecodeUint` apply.
    /// Note: Reverts if decoding is not completed within the bounds of `data`.
    /// @return result The decoded signed integer value.
    /// @return remainingData Unconsumed part of `data`.
    function decodeInt(bytes calldata data)
        internal
        pure
        returns (int256 result, bytes calldata remainingData)
    {
        uint256 ptr;
        /// @solidity memory-safe-assembly
        assembly {
            ptr := data.offset
        }
        uint256 newPtr;
        (result, newPtr) = rawDecodeInt(ptr);
        unchecked {
            remainingData = data[newPtr - ptr:];
        }
    }

    /// @dev Decodes an Unsigned LEB128 encoded value from the beginning of memory `data`.
    /// Note: Memory equivalent of `decodeUint`.
    /// @return result The decoded unsigned integer value.
    /// @return size The length of `data` spent to generate `result`.
    function memDecodeUint(bytes memory data)
        internal
        pure
        returns (uint256 result, uint256 size)
    {
        uint256 ptr;
        /// @solidity memory-safe-assembly
        assembly {
            ptr := add(data, 0x20)
        }
        uint256 newPtr;
        (result, newPtr) = rawMemDecodeUint(ptr);
        unchecked {
            size = newPtr - ptr;
        }
        if (size > data.length) revert();
    }

    /// @dev Decodes a Signed LEB128 encoded value from the beginning of memory `data`.
    /// Note: Memory equivalent of `decodeInt`.
    /// @return result The decoded signed integer value.
    /// @return size The length of `data` spent to generate `result`.
    function memDecodeInt(bytes memory data) internal pure returns (int256 result, uint256 size) {
        uint256 ptr;
        /// @solidity memory-safe-assembly
        assembly {
            ptr := add(data, 0x20)
        }
        uint256 newPtr;
        (result, newPtr) = rawMemDecodeInt(ptr);
        unchecked {
            size = newPtr - ptr;
        }
        if (size > data.length) revert();
    }
}
