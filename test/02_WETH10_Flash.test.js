const WETH9 = artifacts.require('WETH9')
const WETH10 = artifacts.require('WETH10')
const TestFlashMinter = artifacts.require('TestFlashMinter')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = "5192296858534827628530496329220095"

contract('WETH10 - Flash Minting', (accounts) => {
  const [deployer, user1, user2] = accounts
  let weth9
  let weth10
  let flash

  beforeEach(async () => {
    weth9 = await WETH9.new({ from: deployer })
    weth10 = await WETH10.new(weth9.address, { from: deployer })
    flash = await TestFlashMinter.new({ from: deployer })
  })

  it('should do a simple flash mint', async () => {
    await flash.flashMint(weth10.address, 1, { from: user1 })

    const balanceAfter = await weth10.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await flash.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashUser = await flash.flashUser()
    flashUser.toString().should.equal(user1)
  })

  it('cannot flash mint beyond the total supply limit', async () => {
    await weth10.deposit({ from: user1, value: '1' })
    await expectRevert(flash.flashMint(weth10.address, MAX, { from: user1 }), 'WETH::flashMint: supply limit exceeded')
  })

  it('should not steal a flash mint', async () => {
    await expectRevert(
      flash.flashMintAndSteal(weth10.address, 1, { from: deployer }),
      'WETH::flashMint: not enough balance to resolve'
    )
  })

  it('needs to return funds after a flash mint', async () => {
    await expectRevert(
      flash.flashMintAndOverspend(weth10.address, 1, { from: user1 }),
      'WETH::flashMint: not enough balance to resolve'
    )
  })

  it('should do two nested flash loans', async () => {
    await flash.flashMintAndReenter(weth10.address, 1, { from: deployer })

    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal('3')
  })

  describe('with a non-zero WETH supply', () => {
    beforeEach(async () => {
      await weth10.deposit({ from: deployer, value: 10 })
    })

    it('should flash mint, withdraw & deposit', async () => {
      await flash.flashMintAndWithdraw(weth10.address, 1, { from: deployer })

      const flashBalance = await flash.flashBalance()
      flashBalance.toString().should.equal('1')
    })
  })
})
