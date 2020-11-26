// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;


interface FlashMintableLike {
    function flashMint(address receiver, uint256 value, bytes calldata) external;
    function balanceOf(address) external returns (uint256);
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address, uint256) external;
}

contract TestFlashMinter {
    enum Action {NORMAL, STEAL, WITHDRAW, REENTER}

    uint256 public flashBalance;
    uint256 public flashValue;
    address public flashUser;

    receive() external payable {}

    function onFlashMint(address user, uint256 value, uint256, bytes calldata data) external {
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data
        flashUser = user;
        flashValue = value;
        if (action == Action.NORMAL) {
            flashBalance = FlashMintableLike(msg.sender).balanceOf(address(this));
            FlashMintableLike(msg.sender).transfer(msg.sender, value); // Resolve the flash mint
        } else if (action == Action.WITHDRAW) {
            FlashMintableLike(msg.sender).withdraw(value);
            flashBalance = address(this).balance;
            FlashMintableLike(msg.sender).deposit{ value: value }();
            FlashMintableLike(msg.sender).transfer(msg.sender, value);
        } else if (action == Action.STEAL) {
            // Do nothing
        } else if (action == Action.REENTER) {
            flashMint(msg.sender, value * 2);
            FlashMintableLike(msg.sender).transfer(msg.sender, value);
        }
    }

    function flashMint(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.NORMAL);
        FlashMintableLike(mint).flashMint(address(this), value, data);
    }

    function flashMintAndWithdraw(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.WITHDRAW);
        FlashMintableLike(mint).flashMint(address(this), value, data);
    }

    function flashMintAndSteal(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.STEAL);
        FlashMintableLike(mint).flashMint(address(this), value, data);
    }

    function flashMintAndReenter(address mint, uint256 value) public {
        // Use this to pack arbitrary data to `executeOnFlashMint`
        bytes memory data = abi.encode(Action.REENTER);
        FlashMintableLike(mint).flashMint(address(this), value, data);
    }
}
