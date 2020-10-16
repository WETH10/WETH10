// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;

interface FlashMinterLike {
    function balanceOf(address) external returns (uint256);
    function executeOnFlashMint(uint256 value, bytes calldata data) external;
    function flashMint(uint256, bytes calldata) external;
}

contract FlashMinter {
    uint256 public flashBalance;
    uint256 public flashValue;
    address public flashData;

    function executeOnFlashMint(uint256 value, bytes calldata data) external {
        flashValue = value;
        (address target) = abi.decode(data, (address)); // Use this to unpack arbitrary data
        flashData = target;
        flashBalance = FlashMinterLike(target).balanceOf(address(this));
    }

    function flashMint(address target, uint256 value) external {
        bytes memory data = abi.encode(target); // Use this to pack arbitrary data to `executeOnFlashMint`
        FlashMinterLike(target).flashMint(value, data);
    }
}
