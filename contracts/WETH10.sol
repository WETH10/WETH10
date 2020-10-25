// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2020
pragma solidity 0.7.0;


interface ERC677Receiver {
    function onTokenTransfer(address, uint, bytes calldata) external;
}

interface FlashMinterLike {
    function executeOnFlashMint(uint256, bytes calldata) external;
}

/// @dev WETH10 is an Ether ERC20 wrapper. You can `deposit` Ether and obtain Wrapped Ether which can then be operated as an ERC20 token. You can
/// `withdraw` Ether from WETH10, which will burn Wrapped Ether in your wallet. The amount of Wrapped Ether in any wallet is always identical to the
/// balance of Ether deposited minus the Ether withdrawn with that specific wallet.
contract WETH10 {
    string public constant name = "Wrapped Ether v10";
    string public constant symbol = "WETH10";
    uint8  public constant decimals = 18;
    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @dev Emitted when allowance of `spender` for `owner` account WETH10 token changes. `value` is new allowance.
    event  Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Emitted when `value` WETH10 token are moved from account (`from`) to account (`to`). Event also tracks minting and burning of WETH10 tokens.
    event  Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Records amount of WETH10 token owned by account.
    mapping (address => uint256) public balanceOf;

    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping (address => uint256) public nonces;

    /// @dev Records number of WETH10 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public allowance;

    /// @dev Current amount of WETH.
    uint256 public totalSupply;

    constructor() {
        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)));
    }

    /// @dev Fallback, `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    receive() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        require(totalSupply <= type(uint112).max, "limit");
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// @dev `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        require(totalSupply <= type(uint112).max, "limit");
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to `to` account.
    function depositTo(address to) external payable {
        require(to != address(this), "!recipient");
        balanceOf[to] += msg.value;
        totalSupply += msg.value;
        require(totalSupply <= type(uint112).max, "limit");
        emit Transfer(address(0), to, msg.value);
    }


    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool success) {
        require(to != address(this), "!recipient");
        balanceOf[to] += msg.value;
        totalSupply += msg.value;
        require(totalSupply <= type(uint112).max, "limit");
        emit Transfer(address(0), to, msg.value);

        ERC677Receiver(to).onTokenTransfer(msg.sender, msg.value, data);
        return true;
    }

    /// @dev Flash mints WETH10 token and burns from caller account.
    /// The flash minted WETH10 is not backed by real Ether, but can be withdrawn as such up to the Ether balance of this contract.
    /// Arbitrary data can be passed as a bytes calldata parameter.
    /// Emits two {Transfer} events for minting and burning of the flash minted amount.
    function flashMint(uint256 value, bytes calldata data) external {
        balanceOf[msg.sender] += value;
        totalSupply += value;
        require(totalSupply <= type(uint112).max, "limit");
        emit Transfer(address(0), msg.sender, value);

        FlashMinterLike(msg.sender).executeOnFlashMint(value, data);

        require(balanceOf[msg.sender] >= value, "!balance");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender, address(0), value);
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external {
        require(balanceOf[msg.sender] >= value, "!balance");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "!withdraw");

        emit Transfer(msg.sender, address(0), value);
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address to, uint256 value) external {
        require(to != address(this), "!recipient");
        require(balanceOf[msg.sender] >= value, "!balance");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");

        emit Transfer(msg.sender, address(0), value);
    }

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ether to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address to, uint256 value) external {
        require(to != address(this), "!recipient");
        require(balanceOf[from] >= value, "!balance");
        
        if (from != msg.sender) {
            uint256 allow = allowance[from][msg.sender];
            if (allow != type(uint256).max) {
                require(allow >= value, "!allowance");
                allowance[from][msg.sender] -= value;
                emit Approval(from, msg.sender, allow - value);
            }
        }
        balanceOf[from] -= value;
        totalSupply -= value;

        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");

        emit Transfer(from, address(0), value);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Approval} event.
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "expired");

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
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "!permit");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`).
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(this), "!recipient");
        require(balanceOf[msg.sender] >= value, "!balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    /// @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// Returns boolean value indicating whether operation succeeded.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(this), "!recipient");
        require(balanceOf[from] >= value, "!balance");

        if (from != msg.sender) {
            uint256 allow = allowance[from][msg.sender];
            if (allow != type(uint256).max) {
                require(allow >= value, "!allowance");
                allowance[from][msg.sender] -= value;
                emit Approval(from, msg.sender, allow - value);
            }
        }

        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);

        return true;
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool success) {
        require(to != address(this), "!recipient");
        require(balanceOf[msg.sender] >= value, "!balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        ERC677Receiver(to).onTokenTransfer(msg.sender, value, data);
        return true;
    }
}

