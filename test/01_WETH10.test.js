const WETH10 = artifacts.require('WETH10')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
require('chai').use(require('chai-as-promised')).should()

contract('TestOracle', (accounts) => {
  const [deployer, user] = accounts
  let weth

  beforeEach(async () => {
    weth = await WETH10.new({ from: deployer })
  })

  describe('deployment', async () => {
    it('returns the name', async () => {
      let name = await weth.name()
      name.should.equal('Wrapped Ether')
    })

    it('deposits ether', async () => {
      const balanceBefore = await weth.balanceOf(user)
      await weth.deposit({ from: user, value: 1 })
      const balanceAfter = await weth.balanceOf(user)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    describe('with a positive balance', async () => {
      beforeEach(async () => {
        await weth.deposit({ from: user, value: 1 })
      })

      it('withdraws ether', async () => {
        const balanceBefore = await weth.balanceOf(user)
        await weth.withdraw(1, { from: user })
        const balanceAfter = await weth.balanceOf(user)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })
    })
  })
})
