// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "solady/tokens/ERC20.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {LEB128Lib} from "../LEB128Lib.sol";

/// @notice Example of an ERC20 token using LEB128 encoded calldata for `approve` and `transfer`.
/// @author shung (https://github.com/Shungy)
contract EncodedCalldataERC20 is ERC20 {
    using LEB128Lib for uint256;
    using SafeCastLib for uint256;

    function alternativeSelector(bytes4 selector) external pure returns (bytes memory) {
        if (selector == ERC20.approve.selector) return hex"00";
        else if (selector == ERC20.transfer.selector) return hex"01";
        else return hex""; // Means no alternative exists.
    }

    function alternativeEncoding(bytes calldata selector) external pure returns (string memory) {
        if (selector.length == 1 && (selector[0] == 0x00 || selector[0] == 0x01)) {
            return "leb128-nooffset";
        }
        return "solidity-abi";
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        uint256 to;
        uint256 amount;
        uint256 ptr = 1;
        (to, ptr) = ptr.rawDecodeUint();
        (amount, ptr) = ptr.rawDecodeUint();
        if (ptr > data.length) revert();

        if (data[0] == 0x00) return abi.encode(approve(address(to.toUint160()), amount));
        else if (data[0] == 0x01) return abi.encode(transfer(address(to.toUint160()), amount));
        else revert();
    }

    function name() public pure override returns (string memory) {
        return "Token";
    }

    function symbol() public pure override returns (string memory) {
        return "TOK";
    }
}
