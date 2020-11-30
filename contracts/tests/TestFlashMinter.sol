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
    address public flashUser;

    receive() external payable {}

    function executeOnFlashMint(bytes calldata data) external {
        (Action action, address user, uint112 value) = abi.decode(data, (Action, address, uint112)); // Use this to unpack arbitrary data
        flashUser = user;
        flashValue = value;
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
            FlashMintableLike(msg.sender).transfer(address(1), 1);
        }
    }

    function flashMint(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.NORMAL, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndWithdraw(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.WITHDRAW, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndSteal(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.STEAL, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndReenter(address target, uint112 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.REENTER, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }

    function flashMintAndOverspend(address target, uint112 value) public {
        bytes memory data = abi.encode(Action.OVERSPEND, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(value, data);
    }
}
