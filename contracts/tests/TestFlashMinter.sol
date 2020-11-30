// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;


interface flashLoanableLike {
    function flashLoan(address receiver, uint256 value, bytes calldata) external;
    function balanceOf(address) external returns (uint256);
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address, uint256) external;
}

contract TestflashLoaner {
    enum Action {NORMAL, STEAL, WITHDRAW, REENTER}

    uint256 public flashBalance;
    uint256 public flashValue;
    address public flashUser;

    receive() external payable {}

    function onflashLoan(address user, uint256 value, uint256, bytes calldata data) external {
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashUser = user;
        flashValue = value;
        if (action == Action.NORMAL) {
            flashBalance = flashLoanableLike(msg.sender).balanceOf(address(this));
            flashLoanableLike(msg.sender).transfer(msg.sender, value); // Resolve the flash mint
        } else if (action == Action.WITHDRAW) {
            flashLoanableLike(msg.sender).withdraw(value);
            flashBalance = address(this).balance;
            flashLoanableLike(msg.sender).deposit{ value: value }();
            flashLoanableLike(msg.sender).transfer(msg.sender, value);
        } else if (action == Action.STEAL) {
            // Do nothing
        } else if (action == Action.REENTER) {
            flashLoan(msg.sender, value * 2);
            flashLoanableLike(msg.sender).transfer(msg.sender, value);
        }
    }

    function flashLoan(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        flashLoanableLike(mint).flashLoan(address(this), value, data);
    }

    function flashLoanAndWithdraw(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.WITHDRAW);
        flashLoanableLike(mint).flashLoan(address(this), value, data);
    }

    function flashLoanAndSteal(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.STEAL);
        flashLoanableLike(mint).flashLoan(address(this), value, data);
    }

    function flashLoanAndReenter(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.REENTER);
        flashLoanableLike(mint).flashLoan(address(this), value, data);
    }
}
