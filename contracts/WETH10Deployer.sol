pragma solidity 0.7.0;

import "./WETH10.sol";

contract WETH10Deployer {
    bool public deployed;
    
    function deployWETH10(bytes32 salt) external returns (address) {
        require(!deployed, "deployed");
        address addr;
        bytes memory bytecode = type(WETH10).creationCode;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "failed");
        deployed = true;
        return addr;
    }
    
    function computeAddress(bytes32 salt) external view returns (address) {
        bytes32 bytecodeHash = keccak256(type(WETH10).creationCode);
        bytes32 data = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)
        );
        return address(bytes20(data << 96));
    }
}
