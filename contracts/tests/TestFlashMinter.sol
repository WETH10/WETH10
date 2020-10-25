// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;

interface FlashMintableLike {
    function flashMint(uint112, bytes calldata) external;
    function balanceOf(address) external returns (uint256);
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address, uint256) external;
}

contract TestFlashMinter {
    enum Action {NORMAL, STEAL, WITHDRAW, REENTER, OVERSPEND}

    uint256 public flashBalance;
    uint256 public flashValue;
    address public flashData;

    receive() external payable {}

    function executeOnFlashMint(uint112 value, bytes calldata data) external {
        flashValue = value;
        (Action action, address target) = abi.decode(data, (Action, address)); // Use this to unpack arbitrary data
        flashData = target;  // Here msg.sender is the weth contract, and target is the user
        if (action == Action.NORMAL) {
            flashBalance = FlashMintableLike(msg.sender).balanceOf(address(this));
        } else if (action == Action.WITHDRAW) {
            FlashMintableLike(msg.sender).withdraw(value);
            flashBalance = address(this).balance;
            FlashMintableLike(msg.sender).deposit{ value: value }();
        } else if (action == Action.STEAL) {
            FlashMintableLike(msg.sender).transfer(address(1), value);
        } else if (action == Action.REENTER) {
            flashMint(msg.sender, value * 2);
        } else if (action == Action.OVERSPEND) {
            FlashMintableLike(msg.sender).transfer(address(0), 1);
        }
    }

    function flashMint(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.NORMAL, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndWithdraw(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.WITHDRAW, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndSteal(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.STEAL, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndReenter(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.REENTER, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndOverspend(address target, uint112 value) public {
        bytes memory data = abi.encode(Action.OVERSPEND, msg.sender); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }
}
