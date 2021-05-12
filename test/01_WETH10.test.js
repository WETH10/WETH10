const WETH10 = artifacts.require('WETH10')
const { signERC2612Permit } = require('eth-permit')
const TestTransferReceiver = artifacts.require('TestTransferReceiver')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
const { web3 } = require('@openzeppelin/test-helpers/src/setup')
require('chai').use(require('chai-as-promised')).should()

const MAX = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

contract('WETH10', (accounts) => {
  const [deployer, user1, user2, user3] = accounts
  let weth10

  beforeEach(async () => {
    weth10 = await WETH10.new({ from: deployer })
  })

  describe('deployment', async () => {
    it('returns the name', async () => {
      let name = await weth10.name()
      name.should.equal('Wrapped Ether v10')
    })

    it('deposits ether', async () => {
      const balanceBefore = await weth10.balanceOf(user1)
      await weth10.deposit({ from: user1, value: 1 })
      const balanceAfter = await weth10.balanceOf(user1)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('deposits ether using the legacy method', async () => {
      const balanceBefore = await weth10.balanceOf(user1)
      await weth10.sendTransaction({ from: user1, value: 1 })
      const balanceAfter = await weth10.balanceOf(user1)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('deposits ether to another account', async () => {
      const balanceBefore = await weth10.balanceOf(user2)
      await weth10.depositTo(user2, { from: user1, value: 1 })
      const balanceAfter = await weth10.balanceOf(user2)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('deposits with depositToAndCall', async () => {
      const receiver = await TestTransferReceiver.new()
      await weth10.depositToAndCall(receiver.address, '0x11', { from: user1, value: 1 })

      const events = await receiver.getPastEvents()
      events.length.should.equal(1)
      events[0].event.should.equal('TransferReceived')
      events[0].returnValues.token.should.equal(weth10.address)
      events[0].returnValues.sender.should.equal(user1)
      events[0].returnValues.value.should.equal('1')
      events[0].returnValues.data.should.equal('0x11')
    })

    describe('with a positive balance', async () => {
      beforeEach(async () => {
        await weth10.deposit({ from: user1, value: 10 })
      })

      it('returns the Ether balance as total supply', async () => {
        const totalSupply = await weth10.totalSupply()
        totalSupply.toString().should.equal('10')
      })

      it('withdraws ether', async () => {
        const balanceBefore = await weth10.balanceOf(user1)
        await weth10.withdraw(1, { from: user1 })
        const balanceAfter = await weth10.balanceOf(user1)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })

      it('withdraws ether to another account', async () => {
        const fromBalanceBefore = await weth10.balanceOf(user1)
        const toBalanceBefore = new BN(await web3.eth.getBalance(user2))

        await weth10.withdrawTo(user2, 1, { from: user1 })

        const fromBalanceAfter = await weth10.balanceOf(user1)
        const toBalanceAfter = new BN(await web3.eth.getBalance(user2))

        fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
        toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
      })

      it('should not withdraw beyond balance', async () => {
        await expectRevert(weth10.withdraw(100, { from: user1 }), 'WETH: burn amount exceeds balance')
        await expectRevert(weth10.withdrawTo(user2, 100, { from: user1 }), 'WETH: burn amount exceeds balance')
        await expectRevert(weth10.withdrawFrom(user1, user2, 100, { from: user1 }), 'WETH: burn amount exceeds balance')
      })

      it('transfers ether', async () => {
        const balanceBefore = await weth10.balanceOf(user2)
        await weth10.transfer(user2, 1, { from: user1 })
        const balanceAfter = await weth10.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('withdraws ether by transferring to address(0)', async () => {
        const balanceBefore = await weth10.balanceOf(user1)
        await weth10.transfer('0x0000000000000000000000000000000000000000', 1, { from: user1 })
        const balanceAfter = await weth10.balanceOf(user1)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })

      it('transfers ether using transferFrom', async () => {
        const balanceBefore = await weth10.balanceOf(user2)
        await weth10.transferFrom(user1, user2, 1, { from: user1 })
        const balanceAfter = await weth10.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('withdraws ether by transferring from someone to address(0)', async () => {
        const balanceBefore = await weth10.balanceOf(user1)
        await weth10.transferFrom(user1, '0x0000000000000000000000000000000000000000', 1, { from: user1 })
        const balanceAfter = await weth10.balanceOf(user1)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })

      it('transfers with transferAndCall', async () => {
        const receiver = await TestTransferReceiver.new()
        await weth10.transferAndCall(receiver.address, 1, '0x11', { from: user1 })

        const events = await receiver.getPastEvents()
        events.length.should.equal(1)
        events[0].event.should.equal('TransferReceived')
        events[0].returnValues.token.should.equal(weth10.address)
        events[0].returnValues.sender.should.equal(user1)
        events[0].returnValues.value.should.equal('1')
        events[0].returnValues.data.should.equal('0x11')
      })

      it('should not transfer and call to zero address', async () => {
        const receiver = '0x0000000000000000000000000000000000000000'
        await expectRevert.unspecified(weth10.transferAndCall(receiver, 100, '0x11', { from: user1 }))
      })

      it('should not transfer beyond balance', async () => {
        await expectRevert(weth10.transfer(user2, 100, { from: user1 }), 'WETH: transfer amount exceeds balance')
        await expectRevert(weth10.transferFrom(user1, user2, 100, { from: user1 }), 'WETH: transfer amount exceeds balance')
        const receiver = await TestTransferReceiver.new()
        await expectRevert(weth10.transferAndCall(receiver.address, 100, '0x11', { from: user1 }), 'WETH: transfer amount exceeds balance')
      })

      it('approves to increase allowance', async () => {
        const allowanceBefore = await weth10.allowance(user1, user2)
        await weth10.approve(user2, 1, { from: user1 })
        const allowanceAfter = await weth10.allowance(user1, user2)
        allowanceAfter.toString().should.equal(allowanceBefore.add(new BN('1')).toString())
      })

      it('approves with approveAndCall', async () => {
        const receiver = await TestTransferReceiver.new()
        await weth10.approveAndCall(receiver.address, 1, '0x11', { from: user1 })

        const events = await receiver.getPastEvents()
        events.length.should.equal(1)
        events[0].event.should.equal('ApprovalReceived')
        events[0].returnValues.token.should.equal(weth10.address)
        events[0].returnValues.spender.should.equal(user1)
        events[0].returnValues.value.should.equal('1')
        events[0].returnValues.data.should.equal('0x11')
      })

      it('approves to increase allowance with permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth10.address, user1, user2, '1')
        await weth10.permit(user1, user2, '1', permitResult.deadline, permitResult.v, permitResult.r, permitResult.s)
        const allowanceAfter = await weth10.allowance(user1, user2)
        allowanceAfter.toString().should.equal('1')
      })

      it('does not approve with expired permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth10.address, user1, user2, '1')
        await expectRevert(weth10.permit(
          user1, user2, '1', 0, permitResult.v, permitResult.r, permitResult.s),
          'WETH: Expired permit'
        )
      })

      it('does not approve with invalid permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth10.address, user1, user2, '1')
        await expectRevert(
          weth10.permit(user1, user2, '2', permitResult.deadline, permitResult.v, permitResult.r, permitResult.s),
          'WETH: invalid permit'
        )
      })

      describe('with a positive allowance', async () => {
        beforeEach(async () => {
          await weth10.approve(user2, 1, { from: user1 })
        })

        it('transfers ether using transferFrom and allowance', async () => {
          const balanceBefore = await weth10.balanceOf(user2)
          await weth10.transferFrom(user1, user2, 1, { from: user2 })
          const balanceAfter = await weth10.balanceOf(user2)
          balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
        })

        it('should not transfer beyond allowance', async () => {
          await expectRevert(weth10.transferFrom(user1, user2, 2, { from: user2 }), 'WETH: request exceeds allowance')
        })
  
        it('withdraws ether using withdrawFrom and allowance', async () => {
          const fromBalanceBefore = await weth10.balanceOf(user1)
          const toBalanceBefore = new BN(await web3.eth.getBalance(user3))

          await weth10.withdrawFrom(user1, user3, 1, { from: user2 })

          const fromBalanceAfter = await weth10.balanceOf(user1)
          const toBalanceAfter = new BN(await web3.eth.getBalance(user3))

          fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
          toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
        })

        it('should not withdraw beyond allowance', async () => {
          await expectRevert(weth10.withdrawFrom(user1, user3, 2, { from: user2 }), 'WETH: request exceeds allowance')
        })
      })

      describe('with a maximum allowance', async () => {
        beforeEach(async () => {
          await weth10.approve(user2, MAX, { from: user1 })
        })

        it('does not decrease allowance using transferFrom', async () => {
          await weth10.transferFrom(user1, user2, 1, { from: user2 })
          const allowanceAfter = await weth10.allowance(user1, user2)
          allowanceAfter.toString().should.equal(MAX)
        })

        it('does not decrease allowance using withdrawFrom', async () => {
          await weth10.withdrawFrom(user1, user2, 1, { from: user2 })
          const allowanceAfter = await weth10.allowance(user1, user2)
          allowanceAfter.toString().should.equal(MAX)
        })
      })
    })
  })
})
