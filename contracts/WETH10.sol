/**
 *Submitted for verification at Etherscan.io on 2020-10-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.0;
// Copyright (C) 2015, 2016, 2017 Dapphub / adapted by Ethereum Community 2020
contract WETH10 {
    string public constant name = "Wrapped Ether";
    string public constant symbol = "WETH";
    uint8  public constant decimals = 18;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address from,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event  Approval(address indexed from, address indexed spender, uint256 value);
    event  Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256)                       public  balanceOf;
    mapping (address => mapping (address => uint256))  public  allowance;
    mapping (address => uint256)                       public  nonces;
    
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

    receive() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    function withdraw(uint256 value) external {
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "!balance");
        balance -= value;
        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "!withdraw");
        emit Transfer(msg.sender, address(0), value);
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }
    
    function _approve(address from, address spender, uint256 value) internal {
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value); 
        return true;
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "!balance");

        balance -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 balance = balanceOf[from];
        require(balance >= value, "!balance");

        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1)) {
            uint256 allowed = allowance[from][msg.sender];
            require(allowed >= value, "!allowance");
            allowed -= value;
        }

        balance -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);

        return true;
    }
    
    // Adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol
    function permit(address from, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "expired");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                from,
                spender,
                value,
                nonces[from]++,
                deadline));

        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == from, "!signer");

        _approve(from, spender, value);
    }
}
