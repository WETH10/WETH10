const WETH10 = artifacts.require('WETH10')
const FlashMinter = artifacts.require('FlashMinter')

const { BN } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

contract('WETH10 - Flash Minting', (accounts) => {
  const [deployer, user1, user2] = accounts
  let weth
  let flash

  beforeEach(async () => {
    weth = await WETH10.new({ from: deployer })
    flash = await FlashMinter.new({ from: deployer })
  })

  it('flash mints', async () => {
    flash.flashMint(weth.address, deployer, 1, { from: deployer })

    const balanceAfter = await weth.balanceOf(deployer)
    balanceAfter.toString().should.equal((new BN('0')).toString())
    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal((new BN('1')).toString())
    const flashValue = await flash.flashValue()
    flashValue.toString().should.equal((new BN('1')).toString())
    const flashData = await flash.flashData()
    flashData.toString().should.equal(weth.address)
  })
})
