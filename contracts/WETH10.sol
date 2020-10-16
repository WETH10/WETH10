// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub // Adapted by Ethereum Community 2020
pragma solidity 0.7.0;

interface ERC677Receiver { 
    function onTokenTransfer(address, uint256, bytes calldata) external;
}

interface FlashMinterLike {
    function executeOnFlashMint(uint256, bytes calldata) external;
}

contract WETH10 {
    string public constant name = "Wrapped Ether"; // Declares fixed WETH10 token name - matches canonical WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2.
    string public constant symbol = "WETH"; // Declares fixed WETH10 token symbol - matches canonical WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2.
    uint8  public constant decimals = 18; // Declares fixed WETH10 token unit scaling factor - matches canonical WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2.
    bytes32 public immutable DOMAIN_SEPARATOR; // ERC2612 permit() pattern - hash identifies WETH10 token contract.
    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"); // ERC2612 permit() pattern - hash identifies WETH10 token function for signature.
    
    /**
     * @dev Emitted when allowance of `spender` for `owner` account WETH10 token is set by call to {approve}. `value` is new allowance.
     */
    event  Approval(address indexed owner, address indexed spender, uint256 value);
    /**
     * @dev Emitted when `value` WETH10 token are moved from account (`from`) to account (`to`). Event also tracks mint and burn of WETH10 token through deposit and withdrawal.
     */
    event  Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev Records amount of WETH10 token owned by account.
     */
    mapping (address => uint256)                       public  balanceOf;
    /**
     * @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
     * Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
     */
    mapping (address => uint256)                       public  nonces;
    /**
     * @dev Records number of WETH10 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}. 
     * This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    mapping (address => mapping (address => uint256))  public  allowance;
    
    /**
     * @dev Internal WETH10 value to track state of calls and mitigate reentrancy.
     */
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

    /**
     * @dev Function modifier to track state and mitigate reentrancy.
     */
    modifier lock() {
        require(unlocked == 1, "locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    /**
     * @dev Function modifier to track state and mitigate reentrancy.
     */
    modifier isUnlocked() {
        require(unlocked == 1, "locked");
        _;
    }
    
    /**
     * @dev Internal function to deposit caller account ether and grant account (`to`) matching WETH10 token balance.
     */
    function _deposit(address to) internal {
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);
    }
    
    /**
     * @dev Fallback, `msg.value` of ether sent to contract grants caller account matching WETH10 token balance.
     * Lock check provided for reentrancy guard.
     *
     * Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
     */
    receive() external payable lock {
        _deposit(msg.sender);
    }
    
    /**
     * @dev `msg.value` of ether grants caller account matching WETH10 token balance.
     *
     * Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
     */
    function deposit() external payable {
        _deposit(msg.sender);
    }
    
    /**
     * @dev `msg.value` of ether grants account (`to`) matching WETH10 token balance.
     *
     * Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to account (`to`).
     */
    function depositTo(address to) external payable {
        _deposit(to);
    }
    
    /**
     * @dev Flash mints WETH10 token and burns from caller account.
     * Arbitrary data can be passed as a bytes calldata parameter.
     * Lock check provided for reentrancy guard.
     *
     * Emits two {Transfer} events.
     * 
     *  Requirements:
     * - flash mint must respect balance and overflow checks.
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
    
    /**
     * @dev Internal function to burn `value` WETH10 token from account (`from`) and withdraw matching ether to account (`to`).
     */
    function _withdraw(address from, address to, uint256 value) internal {
        require(balanceOf[from] >= value, "!balance");
        
        balanceOf[from] -= value;
        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(from, address(0), value);
    }
    
    /**
     * @dev Burns caller account WETH10 token `value` to withdraw matching ether.
     * Lock check provided for reentrancy guard.
     *
     * Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from caller account.
     * 
     * Requirements:
     * - caller account must have at least `value` balance of WETH10 token.
     */
    function withdraw(uint256 value) external isUnlocked {
        _withdraw(msg.sender, msg.sender, value);
    }
    
    /**
     * @dev Burns caller account WETH10 token `value` to withdraw matching ether to account (`to`).
     * Lock check provided for reentrancy guard.
     *
     * Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from caller account.
     * 
     * Requirements:
     * - caller account must have at least `value` balance of WETH10 token.
     */
    function withdrawTo(address to, uint256 value) external isUnlocked {
        _withdraw(msg.sender, to, value);
    }
    
    /**
     * @dev Burns account's (`from`) WETH10 token `value` to withdraw matching ether to account (`to`).
     * `value` is then deducted from caller account's allowance.
     * Lock check provided for reentrancy guard.
     *
     * Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`).
     * Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from account (`from`).
     * 
     * Requirements:
     * - caller account must have at least `value` allowance from withdrawing account (`from`).
     * - withdrawing account (`from`) must have at least `value` balance of WETH10 token.
     */
    function withdrawFrom(address from, address to, uint256 value) external isUnlocked {
        _allowanceCheckandUpdate(from, msg.sender, value);
        _withdraw(from, to, value);
    }
    
    /**
     * @dev Returns amount of WETH10 token in existence based on deposited ether.
     */
    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Internal function to check and update `value` for caller account (`spender`) to spend from `owner` account if not same account.
     */
    function _allowanceCheckandUpdate(address owner, address spender, uint256 value) internal {
        if (owner != spender) {
            uint256 allow = allowance[owner][spender];
            if (allow != uint256(-1)) {
                require(allow >= value, "!allowance");
                allowance[owner][spender] -= value;
            }
            emit Approval(owner, spender, allow - value);
        }
    }
    
    /**
     * @dev Internal function to set `value` as allowance of `spender` account over `owner` account's WETH10 token.
     *
     */
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    /**
     * @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token.
     * 
     * Returns boolean value indicating whether operation succeeded.
     *
     * Emits {Approval} event.
     * 
     * Requirements:
     * - allowance reset required to mitigate race condition - see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        require(value == 0 || allowance[msg.sender][spender] == 0, "!reset"); 
        _approve(msg.sender, spender, value); 
        return true;
    }
    
    /**
     * @dev Internal function to check `from` account has at least `value` WETH10 token and transfer to account (`to`) won't cause overflow.
     */
    function _balanceCheck(address from, address to, uint256 value) internal view {
        require(balanceOf[from] >= value, "!balance");
        require(balanceOf[to] + value >= value, "overflow");
    }
    
    /**
     * @dev Internal function to update balance of WETH10 token from account (`from`) to account (`to`).
     */
    function _balanceUpdate(address from, address to, uint256 value) internal {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    /**
     * @dev Sets `value` as allowance of `spender` account over `owner` account's WETH10 token, given `owner` account's signed approval.
     *
     * Emits {Approval} event.
     *
     * Requirements:
     * - `deadline` must be timestamp in future.
     * - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
     * - the signature must use `owner` account's current nonce (see {nonces}).
     * - the signer cannot be zero address and must be `owner` account.
     *
     * For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
     * WETH10 token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
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
     * @dev Moves `value` WETH10 token from caller's account to account (`to`).
     *
     * Returns boolean value indicating whether operation succeeded.
     *
     * Emits {Transfer} event.
     * 
     * Requirements:
     * - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        _balanceCheck(msg.sender, to, value);
        _balanceUpdate(msg.sender, to, value);
        return true;
    }
    
    /**
     * @dev Moves `value` WETH10 token from caller's account to account (`to`) with added ERC677 data method.
     *
     * Returns boolean value indicating whether operation succeeded.
     *
     * Emits {Transfer} event.
     * 
     * Requirements:
     * - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
     *
     * For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success) {
        _balanceCheck(msg.sender, to, value);
        _balanceUpdate(msg.sender, to, value);
        ERC677Receiver(to).onTokenTransfer(msg.sender, value, data);
        return true;
    }
    
    /**
     * @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism. 
     * `value` is then deducted from caller account's allowance.
     *
     * Returns boolean value indicating whether operation succeeded.
     *
     * Emits {Transfer} and {Approval} events.
     * 
     * Requirements:
     * - owner account (`from`) must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
     * - caller account must have at least `value` allowance from account (`from`).
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _balanceCheck(from, to, value);
        _allowanceCheckandUpdate(from, msg.sender, value);
        _balanceUpdate(from, to, value);
        return true;
    }
}
