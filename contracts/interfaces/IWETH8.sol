// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./IERC2612.sol";
import "./IERC3156FlashLender.sol";

/// @dev Wrapped Ether v10 (WETH8) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH8 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH8, which will then burn WETH8 token in your wallet. The amount of WETH8 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.
interface IWETH8 is IERC20, IERC2612, IERC3156FlashLender {

    /// @dev Returns current amount of flash-minted WETH8 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH8 token balance.
    /// Emits {Transfer} event to reflect WETH8 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH8 token balance.
    /// Emits {Transfer} event to reflect WETH8 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH8 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH8 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH8 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH8 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH8 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH8 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH8 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH8 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH8 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH8 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;
}
