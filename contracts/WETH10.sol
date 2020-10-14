pragma solidity 0.7.0;
// Copyright (C) 2015, 2016, 2017 Dapphub // Adapted by Ethereum Community 2020

contract WETH10 {
    string public constant name = "Wrapped Ether"; // Declares fixed WETH10 token name - matches canonical WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    string public constant symbol = "WETH"; // Declares fixed WETH10 token symbol - matches canonical WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    uint8  public constant decimals = 18; // Declares fixed WETH10 token unit scaling factor - matches canonical WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    bytes32 public immutable DOMAIN_SEPARATOR; // ERC2612 permit() pattern - hash identifies WETH10 token contract
    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"); // ERC2612 permit() pattern - hash identifies WETH10 token function for signature

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` account WETH10 token is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event  Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * @dev Emitted when `value` WETH10 token are moved from one account (`from`) to
     * another (`to`).
     */
    event  Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Returns the amount of WETH10 token owned by an account.
     */
    mapping (address => uint256)                       public  balanceOf;
    
    /**
     * @dev Returns the current ERC2612 nonce for an account. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases the account's nonce by one. This
     * prevents a signature from being used multiple times.
     */
    mapping (address => uint256)                       public  nonces;
    
    /**
     * @dev Returns the remaining number of WETH10 token that an account (second) will be
     * allowed to spend on behalf of another (first) through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    mapping (address => mapping (address => uint256))  public  allowance;

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

    modifier lock() {
        require(unlocked == 1, "locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }    

    /**
     * @dev Fallback, `msg.value` of ether sent to contract grants caller account matching WETH10 token balance.
     *
     * lock is provided for functions that deal with ether as check on potential abuse.
     *
     * Emits a {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller.
     */
    receive() external payable lock {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    /**
     * @dev `msg.value` of ether grants caller matching WETH10 token balance.
     *
     * lock is provided for functions that deal with ether as check on potential abuse.
     *
     * Emits a {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller.
     */
    function deposit() external payable lock {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    /**
     * @dev `msg.value` of ether grants account (`to`) matching WETH10 token balance.
     *
     * lock is provided for functions that deal with ether as check on potential abuse.
     *
     * Emits a {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to account (`to`).
     */
    function depositTo(address to) external payable lock {
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);
    }
    
    /**
     * @dev Burns caller WETH10 token `value` to withdraw matching ether.
     *
     * lock is provided for functions that deal with ether as check on potential abuse.
     *
     * Emits a {Transfer} event to reflect WETH10 token burn of `value` to zero address from caller.
     */
    function withdraw(uint256 value) external lock {
        require(balanceOf[msg.sender] >= value, "!balance");
        
        balanceOf[msg.sender] -= value;
        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(msg.sender, address(0), value);
    }
    
     /**
     * @dev Burns caller WETH10 token `value` to withdraw matching ether to account (`to`).
     *
     * lock is provided for functions that deal with ether as check on potential abuse.
     *
     * Emits a {Transfer} event to reflect WETH10 token burn of `value` to zero address from caller.
     */
    function withdrawTo(address to, uint256 value) external lock {
        require(balanceOf[msg.sender] >= value, "!balance");
        
        balanceOf[msg.sender] -= value;
        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(msg.sender, address(0), value);
    }
    
     /**
     * @dev Burns an account's (`from`) WETH10 token `value` to withdraw matching ether to account (`to`).
     * `value` is then deducted from the caller's allowance.
     * 
     * lock is provided for functions that deal with ether as check on potential abuse.
     *
     * Emits a {Transfer} event to reflect WETH10 token burn of `value` to zero address from account (`from`).
     */
    function withdrawFrom(address from, address to, uint256 value) external lock {
        require(balanceOf[from] >= value, "!balance");

        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1)) {
            require(allowance[from][msg.sender] >= value, "!allowance");
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;
        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(from, address(0), value);
    }
    
    /**
     * @dev Returns the amount of WETH10 token in existence based on deposited ether.
     */
    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Internally sets `value` as the allowance of `spender` over the `owner`'s WETH10 token.
     *
     * Emits an {Approval} event.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    /**
     * @dev Sets `value` as the allowance of `spender` over the caller's WETH10 token.
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value); 
        return true;
    }
    
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s WETH10 token,
     * given `owner`'s signed approval.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     * - the signer cannot be the zero address and must be `owner`.
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     * 
     * Adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol
     */
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
    
    /**
     * @dev Moves `value` WETH10 token from the caller's account to target account (`to`).
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "!balance");
        require(balanceOf[to] + value >= value, "overflow");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }
    
    /**
     * @dev Moves `value` WETH10 token from account (`from`) to target account (`to`) using the allowance mechanism. 
     * `value` is then deducted from the caller's allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "!balance");
        require(balanceOf[to] + value >= value, "overflow");

        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1)) {
            require(allowance[from][msg.sender] >= value, "!allowance");
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Flash mint WETH10 token and burn from caller account.
     * Arbitrary data can be passed as a bytes calldata parameter.
     *
     * Emits {Transfer} events.
     */
    function flashMint(uint256 value, bytes calldata data) external lock {
        balanceOf[msg.sender] += value;
        require(balanceOf[msg.sender] >= value, "overflow");
        emit Transfer(address(0), msg.sender, value);

        FlashMinterLike(msg.sender).executeOnFlashMint(value, data);

        require(balanceOf[msg.sender] >= value, "!balance");
        balanceOf[msg.sender] -= value;
        emit Transfer(msg.sender, address(0), value);
    }
}
