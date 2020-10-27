// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;

interface FlashMintableLike {
    function flashMint(address, uint256, bytes calldata) external;
    function flashBurn(uint256) external;
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
        (Action action, address user, uint256 value) = abi.decode(data, (Action, address, uint256)); // Use this to unpack arbitrary data
        flashUser = user;
        flashValue = value;
        if (action == Action.NORMAL) {
            flashBalance = FlashMintableLike(msg.sender).balanceOf(address(this));
            FlashMintableLike(msg.sender).flashBurn(value);
        } else if (action == Action.WITHDRAW) {
            FlashMintableLike(msg.sender).withdraw(value);
            flashBalance = address(this).balance;
            FlashMintableLike(msg.sender).deposit{ value: value }();
            FlashMintableLike(msg.sender).flashBurn(value);
        } else if (action == Action.STEAL) {
            // Just keep the funds
        } else if (action == Action.REENTER) {
            flashMint(msg.sender, value * 2); // Do an inner flash mint with value * 2
            FlashMintableLike(msg.sender).flashBurn(value); // Exit the outer flash mint from `flashMintAndReenter`
        }
    }

    function flashMint(address target, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.NORMAL, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(address(this), value, data);
    }

    function flashMintAndWithdraw(address target, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.WITHDRAW, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(address(this), value, data);
    }

    function flashMintAndSteal(address target, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.STEAL, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(address(this), value, data);
    }

    function flashMintAndReenter(address target, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.REENTER, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(address(this), value, data);
    }

    function flashMintAndOverspend(address target, uint256 value) public {
        bytes memory data = abi.encode(Action.OVERSPEND, msg.sender, value); // Here msg.sender is the user, and target is the weth contract
        FlashMintableLike(target).flashMint(msg.sender, value, data);
    }
}
