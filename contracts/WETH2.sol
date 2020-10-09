// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;
// Copyright (C) 2015, 2016, 2017 Dapphub / adapted by LexDAO 2020
contract WETH2 {
    string public name;
    string public symbol;
    uint8  public decimals;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public PERMIT_TYPEHASH = keccak256("Permit(address src,address guy,uint wad,uint nonce,uint deadline)");

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    mapping (address => uint)                       public  nonces;
    
    constructor() public {
        name = "Wrapped Ether";
        symbol = "WETH";
        decimals = 18;
        uint chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)));
    }

    function() external payable {
        deposit();
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint wad) external {
        require(balanceOf[msg.sender] >= wad, "!balance");
        balanceOf[msg.sender] -= wad;
        (bool success, ) = msg.sender.call.value(wad)("");
        require(success, "!withdraw");
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() external view returns (uint) {
        return address(this).balance;
    }
    
    function _approve(address src, address guy, uint wad) internal {
        allowance[src][guy] = wad;
        emit Approval(src, guy, wad);
    }
    
    function approve(address guy, uint wad) external returns (bool) {
        _approve(msg.sender, guy, wad); 
        return true;
    }
    
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    
    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad, "!balance");

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "!allowance");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
    
    // Adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol
    function permit(address src, address guy, uint wad, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "expired");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                src,
                guy,
                wad,
                nonces[src]++,
                deadline));

        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == src, "!signer");

        _approve(src, guy, wad);
    }
}
