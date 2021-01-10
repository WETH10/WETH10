// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.6;
import "../WETH10.sol";


/// @dev A contract that will receive weth, and allows for it to be retrieved.
contract MockHolder {
    constructor (address payable weth, address retriever) {
        WETH10(weth).approve(retriever, type(uint).max);
    }
}

/// @dev Invariant testing
contract WETH10Fuzzing {

    WETH10 internal weth;
    address internal holder;

    /// @dev Instantiate the WETH10 contract, and a holder address that will return weth when asked to.
    constructor () {
        weth = new WETH10();
        holder = address(new MockHolder(address(weth), address(this)));
    }

    /// @dev Receive ETH when withdrawing.
    receive () external payable { }

    /// @dev Add two numbers, but return 0 on overflow
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a); // Normally it would be a `require`, but we want the test to fail if there is an overflow, not to be ignored.
    }

    /// @dev Subtract two numbers, but return 0 on overflow
    function sub(uint a, uint b) internal pure returns (uint c) {
        c = a - b;
        assert(c <= a); // Normally it would be a `require`, but we want the test to fail if there is an overflow, not to be ignored.
    }

    /// @dev Test that supply and balance hold on deposit.
    function deposit(uint ethAmount) public {
        uint supply = address(weth).balance;
        uint balance = weth.balanceOf(address(this));
        weth.deposit{value: ethAmount}(); // It seems that echidna won't let the total value sent go over type(uint256).max
        assert(address(weth).balance == add(supply, ethAmount));
        assert(weth.balanceOf(address(this)) == add(balance, ethAmount));
        assert(address(weth).balance == address(weth).balance);
    }

    /// @dev Test that supply and balance hold on withdraw.
    function withdraw(uint ethAmount) public {
        uint supply = address(weth).balance;
        uint balance = weth.balanceOf(address(this));
        weth.withdraw(ethAmount);
        assert(address(weth).balance == sub(supply, ethAmount));
        assert(weth.balanceOf(address(this)) == sub(balance, ethAmount));
        assert(address(weth).balance == address(weth).balance);
    }

    /// @dev Test that supply and balance hold on transfer.
    function transfer(uint ethAmount) public {
        uint thisBalance = weth.balanceOf(address(this));
        uint holderBalance = weth.balanceOf(holder);
        weth.transfer(holder, ethAmount);
        assert(weth.balanceOf(address(this)) == sub(thisBalance, ethAmount));
        assert(weth.balanceOf(holder) == add(holderBalance, ethAmount));
        assert(address(weth).balance == address(weth).balance);
    }

    /// @dev Test that supply and balance hold on transferFrom.
    function transferFrom(uint ethAmount) public {
        uint thisBalance = weth.balanceOf(address(this));
        uint holderBalance = weth.balanceOf(holder);
        weth.transferFrom(holder, address(this), ethAmount);
        assert(weth.balanceOf(address(this)) == add(thisBalance, ethAmount));
        assert(weth.balanceOf(holder) == sub(holderBalance, ethAmount));
        assert(address(weth).balance == address(weth).balance);
    }
}