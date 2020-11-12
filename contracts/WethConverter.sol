// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2020
pragma solidity 0.7.0;


interface WETH9Like {
    function withdraw(uint) external payable;
    function deposit() external payable;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface WETH10Like {
    function depositTo(address) external payable;
    function withdrawFrom(address, address, uint256) external payable;
}

contract WethConverter {

    receive() external payable {
    }

    function weth9ToWeth10(WETH9Like weth9, WETH10Like weth10, address account, uint256 value) public {
        weth9.transferFrom(account, address(this), value);
        weth9.withdraw(value);
        weth10.depositTo{ value: value }(account);
    }

    function weth10ToWeth9(WETH9Like weth9, WETH10Like weth10, address account, uint256 value) public {
        weth10.withdrawFrom(account, address(this), value);
        weth9.deposit{ value: value }();
        weth9.transfer(account, value);
    }
}

