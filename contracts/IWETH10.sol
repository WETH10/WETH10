// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2020
pragma solidity 0.7.0;

/// @dev WETH10 is an Ether ERC20 wrapper. You can `deposit` Ether and obtain Wrapped Ether which can then be operated as an ERC20 token. You can
/// `withdraw` Ether from WETH10, which will burn Wrapped Ether in your wallet. The amount of Wrapped Ether in any wallet is always identical to the
/// balance of Ether deposited minus the Ether withdrawn with that specific wallet.
interface IWETH10 {

    /// @dev Emitted when allowance of `spender` for `owner` account WETH10 token changes. `value` is new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Emitted when `value` WETH10 token are moved from account (`from`) to account (`to`). Event also tracks minting and burning of WETH10 tokens.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Returns amount of WETH10 token owned by account.
    function balanceOf(address owner) external view returns(uint256);

    /// @dev Returns current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} must increase account's nonce by one. This prevents signature from being used multiple times.
    function nonceOf(address) external view returns(uint256);

    /// @dev Returns amount of WETH10 token that account (spender) will be able to spend on behalf of another account (owner) through {transferFrom}.
    function allowance(address owner, address spender) external view returns(uint256);

    /// @dev Returns current amount of flash minted WETH10 token.
    function flashSupply() external view returns(uint256);

    /// @dev `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to `to` account.
    function depositTo(address to) external payable;

    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool success);

    /// @dev Flash mints WETH10 token and burns from caller account.
    /// The flash minted WETH10 is not backed by real Ether, but can be withdrawn as such up to the Ether balance of this contract.
    /// Arbitrary data can be passed as a bytes calldata parameter.
    /// Emits two {Transfer} events for minting and burning of the flash minted amount.
    function flashMint(uint256 value, bytes calldata data) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ether to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address to, uint256 value) external;

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Approval} event.
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's WETH10 token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner` account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// WETH10 token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`).
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// Returns boolean value indicating whether operation succeeded.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool success);
}

