# WETH10

This [twitter hackathon project 🐦](https://twitter.com/r_ross_campbell/status/1314726259050639364?s=20) updates the canonical ["Wrapped Ether" WETH(9) contract](https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code) with minor but significant upgrades to save Ethereum network users gas and time in making transactions with tokenized ETH on lo-trust, lo-code 🍬⛽.

[Kovan testnet deployment](https://kovan.etherscan.io/address/0xD25f374A2d7d40566b006eC21D82b9655865F941) of latest meaningful commit ([fd225b0](https://github.com/WETH10/WETH10/commit/fd225b03531c1af261a0ec9be16c6b8c8cb4110a)) 🔨.

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

## Flash Minting
This contract allows to `flashMint` an arbitrary amount of Wrapped Ether, unbacked by real Ether, with the condition that it is burned before the end of the transaction. 

This function will call `executeOnFlashMint` on the calling address, receiving and passing along a `bytes` parameter which can be used by the calling contract to process the callback.

## Convert to WETH9
This contract allows to convert WETH10 into WETH9 at a minimal cost, using `convert` functions. Combining `convertFrom` with `permit` this conversion can be done at no cost to the WETH10 holder.
