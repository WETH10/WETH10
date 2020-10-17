// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2020
pragma solidity 0.7.0;

interface ERC677Receiver {
    function onTokenTransfer(address, uint, bytes calldata) external;
}

interface FlashMinterLike {
    function executeOnFlashMint(uint, bytes calldata) external;
}


contract WETH10 {
    string public constant name = "Wrapped Ether";
    string public constant symbol = "WETH";
    uint8  public constant decimals = 18;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @dev Emitted when allowance of `spender` for `owner` account WETH10 token is set by call to {approve}. `value` is new allowance.
    event  Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Emitted when `value` WETH10 token are moved from account (`from`) to account (`to`). Event also tracks mint and burn of WETH10 token through deposit and withdrawal.
    event  Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Records amount of WETH10 token owned by account.
    mapping (address => uint256)                       public  balanceOf;

    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping (address => uint256)                       public  nonces;

    /// @dev Records number of WETH10 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}. 
    /// This is zero by default.
    /// This value changes when {approve} or {transferFrom} are called.
    mapping (address => mapping (address => uint256))  public  allowance;

    /// @dev Internal WETH10 value to disallow withdrawals during flash minting.
    uint256 private unlocked = 1;

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

    /// @dev Disallow withdrawals or (reentrant) flash minting.
    modifier lock() {
        require(unlocked == 1, "locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /// @dev Return whether the contract is locked for withdrawals and flash minting
    modifier isUnlocked() {
        require(unlocked == 1, "locked");
        _;
    }

    /// @dev Returns amount of WETH10 token in existence based on deposited ether.
    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Fallback, `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    receive() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// @dev `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to `to` account.
    function depositTo(address to) external payable {
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);
    }

    /// @dev Flash mints WETH10 token and burns from caller account.
    /// Arbitrary data can be passed as a bytes calldata parameter.
    /// Lock check provided for reentrancy guard.
    /// Emits two {Transfer} events for minting and burning of the flash minted amount.
    function flashMint(uint256 value, bytes calldata data) external lock {
        balanceOf[msg.sender] += value;
        require(balanceOf[msg.sender] >= value, "overflow");
        emit Transfer(address(0), msg.sender, value);

        FlashMinterLike(msg.sender).executeOnFlashMint(value, data);

        require(balanceOf[msg.sender] >= value, "!balance");
        balanceOf[msg.sender] -= value;
        emit Transfer(msg.sender, address(0), value);
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to the same.
    /// Lock check provided to avoid withdrawing Ether from a flash mint
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external isUnlocked {
        require(balanceOf[msg.sender] >= value, "!balance");
        
        balanceOf[msg.sender] -= value;
        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(msg.sender, address(0), value);
    }
    
    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to account (`to`).
    /// Lock check provided to avoid withdrawing Ether from a flash mint
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address to, uint256 value) external isUnlocked {
        require(balanceOf[msg.sender] >= value, "!balance");
        
        balanceOf[msg.sender] -= value;
        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(msg.sender, address(0), value);
    }
    
    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ether to account (`to`).
    /// Lock check provided to avoid withdrawing Ether from a flash mint
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`), unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address to, uint256 value) external isUnlocked {
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
        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(from, address(0), value);
    }
    
    /// @dev Internal function to execute the `approve logic.
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - allowance reset required to mitigate race condition - see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
    function approve(address spender, uint256 value) external returns (bool) {
        require(value == 0 || allowance[msg.sender][spender] == 0, "!reset"); 
        _approve(msg.sender, spender, value); 
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
        require(signer != address(0) && signer == owner, "!signer");

        _approve(owner, spender, value);
    }
    
    /// @dev Moves `value` WETH10 token from caller's account to account (`to`).
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "!balance");
        require(balanceOf[to] + value >= value, "overflow");

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
    /// - owner account (`from`) must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
    /// - caller account must have at least `value` allowance from account (`from`).
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "!balance");
        require(balanceOf[to] + value >= value, "overflow");

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
    ///   - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool success) {
        transferFrom(msg.sender, to, value);

        ERC677Receiver(to).onTokenTransfer(msg.sender, value, data);
        return true;
    }
}

