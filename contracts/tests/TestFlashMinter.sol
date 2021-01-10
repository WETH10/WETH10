// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;

import "../interfaces/IWETH10.sol";
import "../interfaces/IERC3156FlashBorrower.sol";


contract TestFlashLender is IERC3156FlashBorrower {
    enum Action {NORMAL, STEAL, WITHDRAW, REENTER}

    uint256 public flashBalance;
    address public flashToken;
    uint256 public flashValue;
    address public flashUser;

    receive() external payable {}

    function onFlashLoan(address user, address token, uint256 value, uint256, bytes calldata data) external override {
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashUser = user;
        flashToken = token;
        flashValue = value;
        if (action == Action.NORMAL) {
            flashBalance = IWETH10(msg.sender).balanceOf(address(this));
            IWETH10(msg.sender).transfer(msg.sender, value); // Resolve the flash mint
        } else if (action == Action.WITHDRAW) {
            IWETH10(msg.sender).withdraw(value);
            flashBalance = address(this).balance;
            IWETH10(msg.sender).deposit{ value: value }();
            IWETH10(msg.sender).transfer(msg.sender, value);
        } else if (action == Action.STEAL) {
            // Do nothing
        } else if (action == Action.REENTER) {
            flashLoan(msg.sender, value * 2);
            IWETH10(msg.sender).transfer(msg.sender, value);
        }
    }

    function flashLoan(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        IWETH10(mint).flashLoan(address(this), address(mint), value, data);
    }

    function flashLoanAndWithdraw(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.WITHDRAW);
        IWETH10(mint).flashLoan(address(this), address(mint), value, data);
    }

    function flashLoanAndSteal(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.STEAL);
        IWETH10(mint).flashLoan(address(this), address(mint), value, data);
    }

    function flashLoanAndReenter(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.REENTER);
        IWETH10(mint).flashLoan(address(this), address(mint), value, data);
    }
}
