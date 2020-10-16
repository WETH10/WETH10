// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub // Adapted by Ethereum Community 2020
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

    event  Approval(address indexed owner, address indexed spender, uint256 value);
    event  Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256)                       public  balanceOf;
    mapping (address => uint256)                       public  nonces;
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

    receive() external payable lock {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    function deposit() external payable lock {
        balanceOf[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    function depositTo(address to) external payable lock {
        balanceOf[to] += msg.value;
        emit Transfer(address(0), to, msg.value);
    }
    
    function withdraw(uint256 value) external lock {
        require(balanceOf[msg.sender] >= value, "!balance");
        
        balanceOf[msg.sender] -= value;
        (bool success, ) = msg.sender.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(msg.sender, address(0), value);
    }
    
    function withdrawTo(address to, uint256 value) external lock {
        require(balanceOf[msg.sender] >= value, "!balance");
        
        balanceOf[msg.sender] -= value;
        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(msg.sender, address(0), value);
    }
    
    function withdrawFrom(address from, address to, uint256 value) external lock {
        require(balanceOf[from] >= value, "!balance");

        
        if (from != msg.sender) {
            uint256 allow = allowance[from][msg.sender];
            if (allow != uint256(-1)) {
                require(allow >= value, "!allowance");
                allowance[from][msg.sender] -= value;
            }
        }

        balanceOf[from] -= value;
        (bool success, ) = to.call{value: value}("");
        require(success, "!withdraw");
        
        emit Transfer(from, address(0), value);
    }
    
    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value); 
        return true;
    }

    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool success) {
        transferFrom(msg.sender, to, value);

        ERC677Receiver(to).onTokenTransfer(msg.sender, value, data);
        return true;
    }
    
    // Adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol
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
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "!balance");
        require(balanceOf[to] + value >= value, "overflow");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "!balance");
        require(balanceOf[to] + value >= value, "overflow");

        if (from != msg.sender) {
            uint256 allow = allowance[from][msg.sender];
            if (allow != uint256(-1)) {
                require(allow >= value, "!allowance");
                allowance[from][msg.sender] -= value;
            }
        }

        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);

        return true;
    }

    function flashMint(uint256 value, bytes calldata data) external lock {
        balanceOf[msg.sender] += value;
        require(balanceOf[msg.sender] >= value, "overflow");
        emit Transfer(address(0), msg.sender, value);

        FlashMinterLike(msg.sender).executeOnFlashMint(value, data);

        require(balanceOf[msg.sender] >= value, "!balance");
        balanceOf[msg.sender] -= value;
        emit Transfer(msg.sender, address(0), value);
    }


    function isContract(address _addr) private view returns (bool hasCode) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}
