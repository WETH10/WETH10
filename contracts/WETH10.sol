// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2020
pragma solidity 0.7.0;

import "./interfaces/IWETH10.sol";
import "./interfaces/IERC3156FlashBorrower.sol";

interface ITransferReceiver {
    function onTokenTransfer(address, uint, bytes calldata) external;
}

interface IApprovalReceiver {
    function onTokenApproval(address, uint, bytes calldata) external;
}


/// @dev WETH10 is an Ether ERC20 wrapper. You can `deposit` Ether and obtain Wrapped Ether which can then be operated as an ERC20 token. You can
/// `withdraw` Ether from WETH10, which will burn Wrapped Ether in your wallet. The amount of Wrapped Ether in any wallet is always identical to the
/// balance of Ether deposited minus the Ether withdrawn with that specific wallet.
contract WETH10 is IWETH10 {

    string public constant name = "Wrapped Ether v10";
    string public constant symbol = "WETH10";
    uint8  public constant decimals = 18;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @dev Records amount of WETH10 token owned by account.
    mapping (address => uint256) public override balanceOf;

    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping (address => uint256) public override nonces;

    /// @dev Records number of WETH10 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public override allowance;

    /// @dev Current amount of flash minted WETH.
    uint256 public override flashMinted;

    /// @dev Fallback, `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    receive() external payable {
        require(address(this).balance + flashMinted <= type(uint112).max, "WETH: supply limit exceeded");
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// @dev Returns the total supply of WETH10 as the Ether held in this contract.
    function totalSupply() external view override returns(uint256) {
        return address(this).balance + flashMinted;
    }

    /// @dev `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    function deposit() external override payable {
        require(address(this).balance + flashMinted <= type(uint112).max, "WETH: supply limit exceeded");
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to `to` account.
    function depositTo(address to) external override payable {
        require(address(this).balance + flashMinted <= type(uint112).max, "WETH: supply limit exceeded");
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);
    }


    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external override payable returns (bool success) {
        require(address(this).balance + flashMinted <= type(uint112).max, "WETH: supply limit exceeded");
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);
        ITransferReceiver(to).onTokenTransfer(msg.sender, msg.value, data);
        return true; // TODO: Return the output of previous line
    }

    /// @dev Return the amount of WETH10 that can be flash lended.
    function flashSupply(address token) external view override returns (uint256) {
        return token == address(this) ? type(uint112).max - address(this).balance - flashMinted : 0; // Can't underflow - L108
    }

    /// @dev Return the fee (zero) for flash lending an amount of WETH10.
    function flashFee(address token, uint256) external view override returns (uint256) {
        require(token == address(this), "WETH: flash mint only WETH10");
        return 0;
    }

    /// @dev Mints `value` WETH10 tokens to the receiver address.
    /// By the end of the transaction, `value` WETH10 tokens will be burned from this contract.
    /// The flash minted WETH10 is not backed by real Ether, but can be withdrawn as such up to the Ether balance of this contract.
    /// Arbitrary data can be passed as a bytes calldata parameter.
    /// Emits two {Transfer} events for minting and burning of the flash minted amount.
    function flashLoan(address receiver, address token, uint256 value, bytes calldata data) external override {
        require(token == address(this), "WETH: flash mint only WETH10");
        require(value <= type(uint112).max, "WETH: flash mint limit exceeded");
        flashMinted += value;
        require(address(this).balance + flashMinted <= type(uint112).max, "WETH: supply limit exceeded");
        balanceOf[receiver] += value;
        emit Transfer(address(0), receiver, value);

        IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, address(this), value, 0, data);

        uint256 balance = balanceOf[address(this)];
        require(balance >= value, "WETH: not enough balance to resolve");
        balanceOf[address(this)] = balance - value;
        flashMinted -= value;
        emit Transfer(address(this), address(0), value);
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external override {
        _burnFrom(msg.sender, value);
        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "WETH: Ether transfer failed");
        emit Transfer(msg.sender, address(0), value);
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address to, uint256 value) external override {
        _burnFrom(msg.sender, value);
        (bool success, ) = to.call{value: value}("");
        require(success, "WETH: Ether transfer failed");
        emit Transfer(msg.sender, address(0), value);
    }

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ether to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address to, uint256 value) external override {
        _burnFrom(from, value);
        (bool success, ) = to.call{value: value}("");
        require(success, "WETH: Ether transfer failed");
        emit Transfer(from, address(0), value);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Approval} event.
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed on `spender` with the `data` parameter.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Approval} event.
    /// For more information on approveAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external override returns (bool) {
        _approve(msg.sender, spender, value);

        IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
        return true; // TODO: Return the output of previous line
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's WETH10 token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner` account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// WETH10 token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(block.timestamp <= deadline, "WETH: Expired permit");

        uint256 chainId;
        assembly {chainId := chainid()}
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)));

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "WETH: invalid permit");
        _approve(owner, spender, value);
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`).
    /// A transfer to `address(0)` triggers a withdraw of the sent tokens.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    function transfer(address to, uint256 value) external override returns (bool) {
        return _transferFrom(msg.sender, to, value);
    }

    /// @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers a withdraw of the sent tokens in favor of caller.
    /// Returns boolean value indicating whether operation succeeded.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        return _transferFrom(from, to, value);
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external override returns (bool) {
        _transferFrom(msg.sender, to, value);
        ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
        return true; // TODO: Return the output of previous line
    }

    /// @dev Sets `value` as allowance of `spender` account over `holder` account's WETH10 token.
    /// Emits {Approval} event.
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers a withdraw of the sent tokens in favor of caller.
    /// Returns boolean value indicating whether operation succeeded.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function _transferFrom(address from, address to, uint256 value) internal returns (bool) {
        uint256 balance = balanceOf[from];
        require(balance >= value, "WETH: transfer amount exceeds balance");

        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "WETH: transfer amount exceeds allowance");
                _approve(from, msg.sender, allowed - value);
            }
        }

        balanceOf[from] = balance - value;
        
        if(to == address(0)) { // Withdraw
            (bool success, ) = msg.sender.call{value: value}("");
            require(success, "WETH: Ether transfer failed");
        } else { // Transfer
            balanceOf[to] += value;
        }
        emit Transfer(from, to, value);
        return true;
    }

    /// @dev Destroys `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function _burnFrom(address from, uint256 value) internal {
        uint256 balance = balanceOf[from];
        require(balance >= value, "WETH: burn amount exceeds balance");
        
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "WETH: burn amount exceeds allowance");
                _approve(from, msg.sender, allowed - value);
            }
        }
        balanceOf[from] = balance - value;
        emit Transfer(from, address(0), value);
    }
}

