// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
import "../interfaces/IERC1271.sol";


contract TestERC1271 is IERC1271 {
    bytes4 public _storedValue;

    function approveAll() public {
        _storedValue = IERC1271(address(this)).isValidSignature.selector;
    }

    function denyAll() public {
        _storedValue = bytes4(0);
    }

    function isValidSignature(bytes32, bytes memory) external view override returns (bytes4) {
        return _storedValue;
    }
}
