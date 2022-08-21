// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
pragma solidity 0.7.6;

interface WETH9Like {
    function withdraw(uint) external;
    function deposit() external payable;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface WETH10Like {
    function depositTo(address) external payable;
    function withdrawFrom(address, address, uint256) external;
}

contract WethConverter {
    WETH9Like immutable private weth9;
    WETH10Like immutable private weth10;
    
    constructor (WETH9Like weth9_, WETH10Like weth10_) {
        weth9 = weth9_;
        weth10 = weth10_;
    }

    receive() external payable { }

    function weth9ToWeth10(address account, uint256 value) external payable {
        weth9.transferFrom(account, address(this), value);
        weth9.withdraw(value);
        weth10.depositTo{value: value + msg.value}(account);
    }

    function weth10ToWeth9(address account, uint256 value) external payable {
        weth10.withdrawFrom(account, address(this), value);
        uint256 combined = value + msg.value;
        weth9.deposit{value: combined}();
        weth9.transfer(account, combined);
    }
}
