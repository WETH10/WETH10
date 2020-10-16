// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.10;
// Copyright (C) 2015, 2016, 2017 Dapphub / adapted by [] 2020

contract TestERC677Receiver {
    address public token;

    event TransferReceived(address token, address sender, uint256 value, bytes data);

    function onTokenTransfer(address sender, uint value, bytes calldata data) external {
        emit TransferReceived(msg.sender, sender, value, data);
    }
}
