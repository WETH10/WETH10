// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;


interface IERC3156FlashBorrower {
    function onFlashLoan(address user, address token, uint256 value, uint256 fee, bytes calldata) external;
}