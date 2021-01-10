// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub / adapted by [] 2020
pragma solidity 0.7.6;


contract TestTransferReceiver {
    address public token;

    event TransferReceived(address token, address sender, uint256 value, bytes data);
    event ApprovalReceived(address token, address spender, uint256 value, bytes data);

    function onTokenTransfer(address sender, uint value, bytes calldata data) external returns(bool) {
        emit TransferReceived(msg.sender, sender, value, data);
        return true;
    }

    function onTokenApproval(address spender, uint value, bytes calldata data) external returns(bool) {
        emit ApprovalReceived(msg.sender, spender, value, data);
        return true;
    }
}
