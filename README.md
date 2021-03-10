# WETH10

This [twitter hackathon project 🐦](https://twitter.com/r_ross_campbell/status/1314726259050639364?s=20) updates the canonical ["Wrapped Ether" WETH(9) contract](https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code) with minor but significant upgrades to save Ethereum network users gas and time in making transactions with tokenized ETH on lo-trust, lo-code 🍬⛽.

[Mainnet deployment](https://etherscan.io/address/0xf4BB2e28688e89fCcE3c0580D37d36A7672E8A9F) of commit ([34d2712](https://github.com/WETH10/WETH10/commit/34d2712876138fb3d5f769a3965f4e330bc91169)) 🔨. The contract has been deployed at the same address in Kovan, Goerli, Rinkeby and Ropsten.


## Total Supply
The supply of WETH10 is capped at `type(uint112).max`.

## Wrapping Ether
Any operation that ends with this contract holding Wrapped Ether is prohibited.

`deposit` Ether in this contract to receive Wrapped Ether (WETH), which implements the ERC20 standard. WETH is interchangeable with Ether in a 1:1 basis.

`withdraw` Ether from this contract by unwrapping WETH from your wallet.

The `depositTo` and `withdrawTo` convenience functions allow to place the resulting WETH or Ether in an address other than the caller.

The `withdrawFrom` function allows to unwrap Ether from an owner wallet to a recipient wallet, as long as the owner called `approve`

## Approvals
When an approval is set to `type(uint256).max` it will not decrease through `transferFrom` or `withdrawFrom` calls.

WETH10 implements [EIP2612](https://eips.ethereum.org/EIPS/eip-2612) to set approvals through off-chain signatures

## Call Chaining
The `depositAndCall` and `transferAndCall` functions allow to deposit Ether or transfer WETH, executing a call in a user-defined contract immediately afterwards, but within the same transaction.

This function will call `onTokenTransfer` on the recipient address, receiving and passing along a `bytes` parameter which can be used by the calling contract to process the callback. See [EIP667](https://github.com/ethereum/EIPs/issues/677).

## Flash Loans
This contract implements [EIP3156](https://eips.ethereum.org/EIPS/eip-3156) that allows to `flashLoan` an arbitrary amount of Wrapped Ether, unbacked by real Ether, with the condition that it is burned before the end of the transaction. No fees are charged.

This function will call `onFlashLoan` on the calling address, receiving and passing along a `bytes` parameter which can be used by the calling contract to process the callback.

## Function unrolling
For a minimal gas cost, all functions in WETH10 are `external`, and a great deal of code repetition exists. To help in understanding the code, blocks that are used recurrently are preceded by a commented-out function call such as `// _transferFrom(msg.sender, to, value)` that describes the functionality of the block, and followed by a blank line.
