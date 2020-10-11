// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.10;

interface ERC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes memory _data) external;
}
