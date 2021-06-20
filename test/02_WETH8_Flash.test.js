const WETH8 = artifacts.require('WETH8')
const TestFlashLender = artifacts.require('TestFlashLender')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

contract('WETH8 - Flash Minting', (accounts) => {
  const [deployer, user1, user2] = accounts
  let weth8
  let flash

  beforeEach(async () => {
    weth8 = await WETH8.new({ from: deployer })
    flash = await TestFlashLender.new({ from: deployer })

    await weth8.deposit({ from: deployer, value: 100 })
  })

  it('should do a simple flash mint', async () => {
    await flash.flashLoan(weth8.address, 1, { from: user1 })

    const balanceAfter = await weth8.balanceOf(user1)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await flash.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashSender = await flash.flashSender()
    flashSender.toString().should.equal(flash.address)
  })

  it('cannot flash mint beyond the individual limit', async () => {
    await expectRevert(flash.flashLoan(weth8.address, 101, { from: user1 }), 'WETH: individual loan limit exceeded')
  })

  it('needs to return funds after a flash mint', async () => {
    await expectRevert(
      flash.flashLoanAndSteal(weth8.address, 1, { from: deployer }),
      'WETH: request exceeds allowance'
    )
  })

  it('should do two nested flash loans', async () => {
    await flash.flashLoanAndReenter(weth8.address, 1, { from: deployer })

    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal('3')
  })

  it('cannot flash mint beyond the total loan limit', async () => {
    await expectRevert(flash.flashLoanAndReenter(weth8.address, 50, { from: deployer }), 'WETH: total loan limit exceeded')
  })

  describe('with a non-zero WETH supply', () => {
    beforeEach(async () => {
      await weth8.deposit({ from: deployer, value: 10 })
    })

    it('should flash mint, withdraw & deposit', async () => {
      await flash.flashLoanAndWithdraw(weth8.address, 1, { from: deployer })

      const flashBalance = await flash.flashBalance()
      flashBalance.toString().should.equal('1')
    })
  })
})
