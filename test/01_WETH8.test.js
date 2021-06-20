const WETH8 = artifacts.require('WETH8')
const { signERC2612Permit } = require('eth-permit')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
const { web3 } = require('@openzeppelin/test-helpers/src/setup')
require('chai').use(require('chai-as-promised')).should()

const MAX = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

contract('WETH8', (accounts) => {
  const [deployer, user1, user2, user3] = accounts
  let weth8

  beforeEach(async () => {
    weth8 = await WETH8.new({ from: deployer })
  })

  describe('deployment', async () => {
    it('returns the name', async () => {
      let name = await weth8.name()
      name.should.equal('Wrapped Ether v8')
    })

    it('deposits ether', async () => {
      const balanceBefore = await weth8.balanceOf(user1)
      await weth8.deposit({ from: user1, value: 1 })
      const balanceAfter = await weth8.balanceOf(user1)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('deposits ether using the legacy method', async () => {
      const balanceBefore = await weth8.balanceOf(user1)
      await weth8.sendTransaction({ from: user1, value: 1 })
      const balanceAfter = await weth8.balanceOf(user1)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('deposits ether to another account', async () => {
      const balanceBefore = await weth8.balanceOf(user2)
      await weth8.depositTo(user2, { from: user1, value: 1 })
      const balanceAfter = await weth8.balanceOf(user2)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    describe('with a positive balance', async () => {
      beforeEach(async () => {
        await weth8.deposit({ from: user1, value: 10 })
      })

      it('returns the Ether balance as total supply', async () => {
        const totalSupply = await weth8.totalSupply()
        totalSupply.toString().should.equal('10')
      })

      it('withdraws ether', async () => {
        const balanceBefore = await weth8.balanceOf(user1)
        await weth8.withdraw(1, { from: user1 })
        const balanceAfter = await weth8.balanceOf(user1)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })

      it('withdraws ether to another account', async () => {
        const fromBalanceBefore = await weth8.balanceOf(user1)
        const toBalanceBefore = new BN(await web3.eth.getBalance(user2))

        await weth8.withdrawTo(user2, 1, { from: user1 })

        const fromBalanceAfter = await weth8.balanceOf(user1)
        const toBalanceAfter = new BN(await web3.eth.getBalance(user2))

        fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
        toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
      })

      it('should not withdraw beyond balance', async () => {
        await expectRevert(weth8.withdraw(100, { from: user1 }), 'WETH: burn amount exceeds balance')
        await expectRevert(weth8.withdrawTo(user2, 100, { from: user1 }), 'WETH: burn amount exceeds balance')
        await expectRevert(weth8.withdrawFrom(user1, user2, 100, { from: user1 }), 'WETH: burn amount exceeds balance')
      })

      it('transfers ether', async () => {
        const balanceBefore = await weth8.balanceOf(user2)
        await weth8.transfer(user2, 1, { from: user1 })
        const balanceAfter = await weth8.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('withdraws ether by transferring to address(0)', async () => {
        const balanceBefore = await weth8.balanceOf(user1)
        await weth8.transfer('0x0000000000000000000000000000000000000000', 1, { from: user1 })
        const balanceAfter = await weth8.balanceOf(user1)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })

      it('transfers ether using transferFrom', async () => {
        const balanceBefore = await weth8.balanceOf(user2)
        await weth8.transferFrom(user1, user2, 1, { from: user1 })
        const balanceAfter = await weth8.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('withdraws ether by transferring from someone to address(0)', async () => {
        const balanceBefore = await weth8.balanceOf(user1)
        await weth8.transferFrom(user1, '0x0000000000000000000000000000000000000000', 1, { from: user1 })
        const balanceAfter = await weth8.balanceOf(user1)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })

      it('should not transfer beyond balance', async () => {
        await expectRevert(weth8.transfer(user2, 100, { from: user1 }), 'WETH: transfer amount exceeds balance')
        await expectRevert(weth8.transferFrom(user1, user2, 100, { from: user1 }), 'WETH: transfer amount exceeds balance')
      })

      it('approves to increase allowance', async () => {
        const allowanceBefore = await weth8.allowance(user1, user2)
        await weth8.approve(user2, 1, { from: user1 })
        const allowanceAfter = await weth8.allowance(user1, user2)
        allowanceAfter.toString().should.equal(allowanceBefore.add(new BN('1')).toString())
      })

      it('approves to increase allowance with permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth8.address, user1, user2, '1')
        await weth8.permit(user1, user2, '1', permitResult.deadline, permitResult.v, permitResult.r, permitResult.s)
        const allowanceAfter = await weth8.allowance(user1, user2)
        allowanceAfter.toString().should.equal('1')
      })

      it('does not approve with expired permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth8.address, user1, user2, '1')
        await expectRevert(weth8.permit(
          user1, user2, '1', 0, permitResult.v, permitResult.r, permitResult.s),
          'WETH: Expired permit'
        )
      })

      it('does not approve with invalid permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth8.address, user1, user2, '1')
        await expectRevert(
          weth8.permit(user1, user2, '2', permitResult.deadline, permitResult.v, permitResult.r, permitResult.s),
          'WETH: invalid permit'
        )
      })

      describe('with a positive allowance', async () => {
        beforeEach(async () => {
          await weth8.approve(user2, 1, { from: user1 })
        })

        it('transfers ether using transferFrom and allowance', async () => {
          const balanceBefore = await weth8.balanceOf(user2)
          await weth8.transferFrom(user1, user2, 1, { from: user2 })
          const balanceAfter = await weth8.balanceOf(user2)
          balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
        })

        it('should not transfer beyond allowance', async () => {
          await expectRevert(weth8.transferFrom(user1, user2, 2, { from: user2 }), 'WETH: request exceeds allowance')
        })
  
        it('withdraws ether using withdrawFrom and allowance', async () => {
          const fromBalanceBefore = await weth8.balanceOf(user1)
          const toBalanceBefore = new BN(await web3.eth.getBalance(user3))

          await weth8.withdrawFrom(user1, user3, 1, { from: user2 })

          const fromBalanceAfter = await weth8.balanceOf(user1)
          const toBalanceAfter = new BN(await web3.eth.getBalance(user3))

          fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
          toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
        })

        it('should not withdraw beyond allowance', async () => {
          await expectRevert(weth8.withdrawFrom(user1, user3, 2, { from: user2 }), 'WETH: request exceeds allowance')
        })
      })

      describe('with a maximum allowance', async () => {
        beforeEach(async () => {
          await weth8.approve(user2, MAX, { from: user1 })
        })

        it('does not decrease allowance using transferFrom', async () => {
          await weth8.transferFrom(user1, user2, 1, { from: user2 })
          const allowanceAfter = await weth8.allowance(user1, user2)
          allowanceAfter.toString().should.equal(MAX)
        })

        it('does not decrease allowance using withdrawFrom', async () => {
          await weth8.withdrawFrom(user1, user2, 1, { from: user2 })
          const allowanceAfter = await weth8.allowance(user1, user2)
          allowanceAfter.toString().should.equal(MAX)
        })
      })
    })
  })
})
