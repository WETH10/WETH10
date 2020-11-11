const WETH9 = artifacts.require('WETH9')
const WETH10 = artifacts.require('WETH10')
const { signERC2612Permit } = require('eth-permit')
const TestERC677Receiver = artifacts.require('TestERC677Receiver')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
const { web3 } = require('@openzeppelin/test-helpers/src/setup')
require('chai').use(require('chai-as-promised')).should()

const MAX = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

contract('WETH10', (accounts) => {
  const [deployer, user1, user2, user3] = accounts
  let weth9
  let weth10

  beforeEach(async () => {
    weth9 = await WETH9.new({ from: deployer })
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

    it('should not depositTo to the contract address', async () => {
      await expectRevert(weth10.depositTo(weth10.address, { value: 1, from: user1 }), 'WETH::depositTo: invalid recipient')
    })

    it('should not depositToAndCall to the contract address', async () => {
      await expectRevert(weth10.depositToAndCall(weth10.address, '0x11', { from: user1, value: 1 }), 'WETH::depositToAndCall: invalid recipient')
    })

    it('deposits with depositToAndCall', async () => {
      const receiver = await TestERC677Receiver.new()
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
        await weth9.deposit({ from: user2, value: 10 })
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

      it('should not withdraw to the contract address', async () => {
        await expectRevert(weth10.withdrawTo(weth10.address, 1, { from: user1 }), 'WETH::withdrawTo: invalid recipient')
        await expectRevert(weth10.withdrawFrom(user1, weth10.address, 1, { from: user1 }), 'WETH::withdrawFrom: invalid recipient')
      })

      it('should not withdraw beyond balance', async () => {
        await expectRevert(weth10.withdraw(100, { from: user1 }), 'WETH::withdraw: withdraw amount exceeds balance')
        await expectRevert(weth10.withdrawTo(user2, 100, { from: user1 }), 'WETH::withdrawTo: withdraw amount exceeds balance')
        await expectRevert(weth10.withdrawFrom(user1, user2, 100, { from: user1 }), 'WETH::withdrawFrom: withdraw amount exceeds balance')
      })

      it.only('converts weth10 to weth9', async () => {
        const weth9Before = await weth9.balanceOf(user1)
        const weth10Before = await weth10.balanceOf(user1)
        await weth10.weth10ToWeth9(weth9.address, user1, user1, 1, { from: user1 })
        const weth9After = await weth9.balanceOf(user1)
        const weth10After = await weth10.balanceOf(user1)
        weth9After.toString().should.equal(weth9Before.add(new BN('1')).toString())
        weth10After.toString().should.equal(weth10Before.sub(new BN('1')).toString())
      })

      it.only('converts weth9 to weth10', async () => {
        const weth9Before = await weth9.balanceOf(user2)
        const weth10Before = await weth10.balanceOf(user2)
        await weth9.approve(weth10.address, 1, { from: user2 })
        await weth10.weth9ToWeth10(weth9.address, user2, user2, 1, { from: user2 })
        const weth9After = await weth9.balanceOf(user2)
        const weth10After = await weth10.balanceOf(user2)
        weth9After.toString().should.equal(weth9Before.sub(new BN('1')).toString())
        weth10After.toString().should.equal(weth10Before.add(new BN('1')).toString())
      })

      it('converts weth10 to weth9 into another account', async () => {
        const fromBalanceBefore = await weth10.balanceOf(user1)
        const toBalanceBefore = await weth9.balanceOf(user2)

        await weth10.weth10ToWeth9(weth9.address, user1, user2, 1, { from: user1 })

        const fromBalanceAfter = await weth10.balanceOf(user1)
        const toBalanceAfter = await weth9.balanceOf(user2)

        fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
        toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
      })

      it('should not convert weth10 to weth9 into the contract address', async () => {
        await expectRevert(weth10.weth10ToWeth9(weth9.address, user1, weth10.address, 1, { from: user1 }), 'WETH::weth10ToWeth9: invalid recipient')
      })

      it('should not convert beyond balance', async () => {
        await expectRevert(weth10.weth10ToWeth9(weth9.address, user1, user2, 100, { from: user1 }), 'WETH::weth10ToWeth9: convert amount exceeds balance')
      })

      it('transfers ether', async () => {
        const balanceBefore = await weth10.balanceOf(user2)
        await weth10.transfer(user2, 1, { from: user1 })
        const balanceAfter = await weth10.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('transfers ether using transferFrom', async () => {
        const balanceBefore = await weth10.balanceOf(user2)
        await weth10.transferFrom(user1, user2, 1, { from: user1 })
        const balanceAfter = await weth10.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('transfers with transferAndCall', async () => {
        const receiver = await TestERC677Receiver.new()
        await weth10.transferAndCall(receiver.address, 1, '0x11', { from: user1 })

        const events = await receiver.getPastEvents()
        events.length.should.equal(1)
        events[0].event.should.equal('TransferReceived')
        events[0].returnValues.token.should.equal(weth10.address)
        events[0].returnValues.sender.should.equal(user1)
        events[0].returnValues.value.should.equal('1')
        events[0].returnValues.data.should.equal('0x11')
      })

      it('should not transfer to the contract address', async () => {
        await expectRevert(weth10.transfer(weth10.address, 1, { from: user1 }), 'WETH::transfer: invalid recipient')
        await expectRevert(weth10.transferFrom(user1, weth10.address, 1, { from: user1 }), 'WETH::transferFrom: invalid recipient')
        await expectRevert(weth10.transferAndCall(weth10.address, 1, '0x11', { from: user1 }), 'WETH::transferAndCall: invalid recipient')
      })

      it('should not transfer beyond balance', async () => {
        await expectRevert(weth10.transfer(user2, 100, { from: user1 }), 'WETH::transfer: transfer amount exceeds balance')
        await expectRevert(weth10.transferFrom(user1, user2, 100, { from: user1 }), 'WETH::transferFrom: transfer amount exceeds balance')
        const receiver = await TestERC677Receiver.new()
        await expectRevert(weth10.transferAndCall(receiver.address, 100, '0x11', { from: user1 }), 'WETH::transferAndCall: transfer amount exceeds balance')
      })

      it('approves to increase allowance', async () => {
        const allowanceBefore = await weth10.allowance(user1, user2)
        await weth10.approve(user2, 1, { from: user1 })
        const allowanceAfter = await weth10.allowance(user1, user2)
        allowanceAfter.toString().should.equal(allowanceBefore.add(new BN('1')).toString())
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
          'WETH::permit: Expired permit'
        )
      })

      it('does not approve with invalid permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth10.address, user1, user2, '1')
        await expectRevert(
          weth10.permit(user1, user2, '2', permitResult.deadline, permitResult.v, permitResult.r, permitResult.s),
          'WETH::permit: invalid permit'
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
          await expectRevert(weth10.transferFrom(user1, user2, 2, { from: user2 }), 'WETH::transferFrom: transfer amount exceeds allowance')
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
  
        it('converts weth10 to weth9 using allowance', async () => {
          const fromBalanceBefore = await weth10.balanceOf(user1)
          const toBalanceBefore = await weth9.balanceOf(user3)

          await weth10.weth10ToWeth9(weth9.address, user1, user3, 1, { from: user2 })

          const fromBalanceAfter = await weth10.balanceOf(user1)
          const toBalanceAfter = await weth9.balanceOf(user3)

          fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
          toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
        })

        it('should not withdraw beyond allowance', async () => {
          await expectRevert(weth10.withdrawFrom(user1, user3, 2, { from: user2 }), 'WETH::withdrawFrom: withdraw amount exceeds allowance')
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

        it('does not decrease allowance using weth10ToWeth9', async () => {
          await weth10.weth10ToWeth9(weth9.address, user1, user2, 1, { from: user2 })
          const allowanceAfter = await weth10.allowance(user1, user2)
          allowanceAfter.toString().should.equal(MAX)
        })
      })
    })
  })
})
