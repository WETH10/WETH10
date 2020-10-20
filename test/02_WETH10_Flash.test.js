const WETH10 = artifacts.require('WETH10')
const TestFlashMinter = artifacts.require('TestFlashMinter')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

contract('WETH10 - Flash Minting', (accounts) => {
  const [deployer, user1, user2] = accounts
  let weth
  let flash

  beforeEach(async () => {
    weth = await WETH10.new({ from: deployer })
    flash = await TestFlashMinter.new({ from: deployer })
  })

  it('should do a simple flash mint', async () => {
    await flash.flashMint(weth.address, 1, { from: deployer })

    const balanceAfter = await weth.balanceOf(deployer)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await flash.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashData = await flash.flashData()
    flashData.toString().should.equal(deployer)
  })

  it('should not steal a flash mint', async () => {
    await expectRevert(
      flash.flashMintAndSteal(weth.address, 1, { from: deployer }),
      '!balance'
    )
  })

  it('should do two nested flash loans', async () => {
    await flash.flashMintAndReenter(weth.address, 1, { from: deployer })

    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal('3')
  })

  describe('with a non-zero WETH supply', () => {
    beforeEach(async () => {
      await weth.deposit({ from: deployer, value: 10 })
    })

    it('should flash mint, withdraw & deposit', async () => {
      await flash.flashMintAndWithdraw(weth.address, 1, { from: deployer })

      const flashBalance = await flash.flashBalance()
      flashBalance.toString().should.equal('1')
    })
  })
})
