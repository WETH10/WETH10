// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;

interface FlashMintableLike {
    function flashMint(uint256, bytes calldata) external;
    function balanceOf(address) external returns (uint256);
    function withdraw(uint256) external;
    function withdrawTo(address, uint256) external;
    function withdrawFrom(address, address, uint256) external;
}

contract FlashMinter {
    enum Action {BALANCE, WITHDRAW, WITHDRAW_TO, WITHDRAW_FROM}

    uint256 public flashBalance;
    uint256 public flashValue;
    address public flashData;

    receive() external payable {}

    function executeOnFlashMint(uint256 value, bytes calldata data) external {
        flashValue = value;
        (Action action, address target) = abi.decode(data, (Action, address)); // Use this to unpack arbitrary data
        flashData = target;  // Here msg.sender is the weth contract, and target is the user
        if (action == Action.BALANCE) {
            flashBalance = FlashMintableLike(msg.sender).balanceOf(address(this));
        } else if (action == Action.WITHDRAW) {
            FlashMintableLike(msg.sender).withdraw(value);
        } else if (action == Action.WITHDRAW_TO) {
            FlashMintableLike(msg.sender).withdrawTo(target, value);
        } else if (action == Action.WITHDRAW_FROM) {
            FlashMintableLike(msg.sender).withdrawFrom(target, target, value);
        }
    }

    function flashMint(address target, uint256 value) external {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.BALANCE, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndWithdraw(address target, uint256 value) external {
        bytes memory data = abi.encode(Action.WITHDRAW, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndWithdrawTo(address target, uint256 value) external {
        bytes memory data = abi.encode(Action.WITHDRAW_TO, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndWithdrawFrom(address target, uint256 value) external {
        bytes memory data = abi.encode(Action.WITHDRAW_FROM, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }
}
