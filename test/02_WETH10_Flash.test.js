const WETH10 = artifacts.require('WETH10')
const TestFlashMinter = artifacts.require('TestFlashMinter')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

contract('WETH10 - Flash Minting', (accounts) => {
  const [deployer, user1, user2] = accounts
  let weth
  let flash

  beforeEach(async () => {
    weth = await WETH10.new({ from: deployer })
    flash = await TestFlashMinter.new({ from: deployer })
  })

  it('should do a simple flash mint', async () => {
    await flash.flashMint(weth.address, 1, { from: user1 })

    const balanceAfter = await weth.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await flash.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashData = await flash.flashData()
    flashData.toString().should.equal(user1)
  })

  it('cannot flash mint and overflow', async () => {
    await weth.deposit({ from: user1, value: '1' })
    await expectRevert(weth.flashMint(MAX, '0x00', { from: user1 }), 'overflow')
  })

  it('should not steal a flash mint', async () => {
    await expectRevert(
      flash.flashMintAndSteal(weth.address, 1, { from: deployer }),
      '!balance'
    )
  })

  it('needs to return funds after a flash mint', async () => {
    await expectRevert(flash.flashMintAndOverspend(weth.address, 1, { from: user1 }), '!balance')
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
