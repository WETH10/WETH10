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

  it('flash mints', async () => {
    flash.flashMint(weth.address, 1, { from: deployer })

    const balanceAfter = await weth.balanceOf(deployer)
    balanceAfter.toString().should.equal(new BN('0').toString())
    const flashBalance = await flash.flashBalance()
    flashBalance.toString().should.equal(new BN('1').toString())
    const flashValue = await flash.flashValue()
    flashValue.toString().should.equal(new BN('1').toString())
    const flashData = await flash.flashData()
    flashData.toString().should.equal(deployer)
  })

  it('cannot reenter during a flash mint', async () => {
    await expectRevert(flash.flashMintReentry(weth.address, 1, { from: deployer }), 'locked')
  })

  it('cannot withdraw during a flash mint', async () => {
    await expectRevert(flash.flashMintAndWithdraw(weth.address, 1, { from: deployer }), 'locked')
  })

  it('cannot withdrawTo during a flash mint', async () => {
    await expectRevert(flash.flashMintAndWithdrawTo(weth.address, 1, { from: deployer }), 'locked')
  })

  it('cannot withdrawFrom during a flash mint', async () => {
    await expectRevert(flash.flashMintAndWithdrawFrom(weth.address, 1, { from: deployer }), 'locked')
  })

  it('needs to return funds after a flash mint', async () => {
    await expectRevert(flash.flashMintAndOverspend(weth.address, 1, { from: deployer }), '!balance')
  })
})
