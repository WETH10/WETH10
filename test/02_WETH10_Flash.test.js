const WETH10 = artifacts.require('WETH10')
const TestFlashLender = artifacts.require('TestFlashLender')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

const MAX = "5192296858534827628530496329220095"

contract('WETH10 - Flash Minting', (accounts) => {
  const [deployer, user1, user2] = accounts
  let weth10
  let flash

  beforeEach(async () => {
    weth10 = await WETH10.new({ from: deployer })
    flash = await TestFlashLender.new({ from: deployer })
  })

  it('should do a simple flash mint', async () => {
    await flash.flashLoan(weth10.address, 1, { from: user1 })

    const balanceAfter = await weth10.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await flash.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashSender = await flash.flashSender()
    flashSender.toString().should.equal(flash.address)
  })

  it('cannot flash mint beyond the total supply limit', async () => {
    await expectRevert(flash.flashLoan(weth10.address, (new BN(MAX)).addn(1), { from: user1 }), 'WETH: individual loan limit exceeded')
  })

  it('needs to return funds after a flash mint', async () => {
    await expectRevert(
      flash.flashLoanAndSteal(weth10.address, 1, { from: deployer }),
      'WETH: request exceeds allowance'
    )
  })

  it('should do two nested flash loans', async () => {
    await flash.flashLoanAndReenter(weth10.address, 1, { from: deployer })

    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal('3')
  })

  describe('with a non-zero WETH supply', () => {
    beforeEach(async () => {
      await weth10.deposit({ from: deployer, value: 10 })
    })

    it('should flash mint, withdraw & deposit', async () => {
      await flash.flashLoanAndWithdraw(weth10.address, 1, { from: deployer })

      const flashBalance = await flash.flashBalance()
      flashBalance.toString().should.equal('1')
    })
  })
})
