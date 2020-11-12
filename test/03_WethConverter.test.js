const WETH9 = artifacts.require('WETH9')
const WETH10 = artifacts.require('WETH10')
const WethConverter = artifacts.require('WethConverter')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
const { web3 } = require('@openzeppelin/test-helpers/src/setup')
require('chai').use(require('chai-as-promised')).should()

contract('WethConverter', (accounts) => {
  const [deployer, user1, user2, user3] = accounts
  let weth9, weth10, wethConverter

  beforeEach(async () => {
    weth9 = await WETH9.new({ from: deployer })
    weth10 = await WETH10.new({ from: deployer })
    wethConverter = await WethConverter.new({ from: deployer })

    await weth9.deposit({ from: user1, value: 1 })
    await weth10.deposit({ from: user2, value: 1 })
  })

  describe('deployment', async () => {
    it('converts from weth9 to weth10', async () => {
      await weth9.approve(wethConverter.address, 1, { from: user1 })
      await wethConverter.weth9ToWeth10(weth9.address, weth10.address, user1, 1, { from: user1 })
      const balanceAfter = await weth10.balanceOf(user1)
      balanceAfter.toString().should.equal('1')
    })

    it('converts from weth10 to weth9', async () => {
      await weth10.approve(wethConverter.address, 1, { from: user2 })
      await wethConverter.weth10ToWeth9(weth9.address, weth10.address, user2, 1, { from: user2 })
      const balanceAfter = await weth9.balanceOf(user2)
      balanceAfter.toString().should.equal('1')
    })
  })
})
