const WETH10 = artifacts.require('WETH10')
const { signERC2612Permit } = require('eth-permit')
const TestERC677Receiver = artifacts.require('TestERC677Receiver')

const { BN, expectRevert } = require('@openzeppelin/test-helpers')
const { web3 } = require('@openzeppelin/test-helpers/src/setup')
require('chai').use(require('chai-as-promised')).should()

contract('WETH10', (accounts) => {
  const [deployer, user1, user2, user3] = accounts
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
      const balanceBefore = await weth.balanceOf(user1)
      await weth.deposit({ from: user1, value: 1 })
      const balanceAfter = await weth.balanceOf(user1)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('deposits ether using the legacy method', async () => {
      const balanceBefore = await weth.balanceOf(user1)
      await weth.sendTransaction({ from: user1, value: 1 })
      const balanceAfter = await weth.balanceOf(user1)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('deposits ether to another account', async () => {
      const balanceBefore = await weth.balanceOf(user2)
      await weth.depositTo(user2, { from: user1, value: 1 })
      const balanceAfter = await weth.balanceOf(user2)
      balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
    })

    it('should not depositTo to the contract address', async () => {
      await expectRevert(weth.depositTo(weth.address, { value: 1, from: user1 }), '!recipient')
    })

    it('should not depositToAndCall to the contract address', async () => {
      await expectRevert(weth.depositToAndCall(weth.address, '0x11', { from: user1, value: 1 }), '!recipient')
    })

    it('deposits with depositToAndCall', async () => {
      const receiver = await TestERC677Receiver.new()
      await weth.depositToAndCall(receiver.address, '0x11', { from: user1, value: 1 })

      const events = await receiver.getPastEvents()
      events.length.should.equal(1)
      events[0].event.should.equal('TransferReceived')
      events[0].returnValues.token.should.equal(weth.address)
      events[0].returnValues.sender.should.equal(user1)
      events[0].returnValues.value.should.equal('1')
      events[0].returnValues.data.should.equal('0x11')
    })

    describe('with a positive balance', async () => {
      beforeEach(async () => {
        await weth.deposit({ from: user1, value: 10 })
      })

      it('reads the supply', async () => {
        const supply = await weth.totalSupply()
        supply.toString().should.equal(new BN('10').toString())
      })

      it('withdraws ether', async () => {
        const balanceBefore = await weth.balanceOf(user1)
        await weth.withdraw(1, { from: user1 })
        const balanceAfter = await weth.balanceOf(user1)
        balanceAfter.toString().should.equal(balanceBefore.sub(new BN('1')).toString())
      })

      it('withdraws ether to another account', async () => {
        const fromBalanceBefore = await weth.balanceOf(user1)
        const toBalanceBefore = new BN(await web3.eth.getBalance(user2))

        await weth.withdrawTo(user2, 1, { from: user1 })

        const fromBalanceAfter = await weth.balanceOf(user1)
        const toBalanceAfter = new BN(await web3.eth.getBalance(user2))

        fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
        toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
      })

      it('should not withdraw to the contract address', async () => {
        await expectRevert(weth.withdrawTo(weth.address, 1, { from: user1 }), '!withdraw')
        await expectRevert(weth.withdrawFrom(user1, weth.address, 1, { from: user1 }), '!withdraw')
      })

      it('transfers ether', async () => {
        const balanceBefore = await weth.balanceOf(user2)
        await weth.transfer(user2, 1, { from: user1 })
        const balanceAfter = await weth.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('transfers ether using transferFrom', async () => {
        const balanceBefore = await weth.balanceOf(user2)
        await weth.transferFrom(user1, user2, 1, { from: user1 })
        const balanceAfter = await weth.balanceOf(user2)
        balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
      })

      it('transfers with transferAndCall', async () => {
        const receiver = await TestERC677Receiver.new()
        await weth.transferAndCall(receiver.address, 1, '0x11', { from: user1 })

        const events = await receiver.getPastEvents()
        events.length.should.equal(1)
        events[0].event.should.equal('TransferReceived')
        events[0].returnValues.token.should.equal(weth.address)
        events[0].returnValues.sender.should.equal(user1)
        events[0].returnValues.value.should.equal('1')
        events[0].returnValues.data.should.equal('0x11')
      })

      it('should not transfer to the contract address', async () => {
        await expectRevert(weth.transfer(weth.address, 1, { from: user1 }), 'overflow')
        await expectRevert(weth.transferFrom(user1, weth.address, 1, { from: user1 }), 'overflow')
      })

      it('should not deposit to the contract address', async () => {
        await expectRevert(weth.depositTo(weth.address, { value: 1, from: user1 }), '!recipient')
      })

      it('should not withdraw to the contract address', async () => {
        await expectRevert(weth.withdrawTo(weth.address, 1, { from: user1 }), '!withdraw')
        await expectRevert(weth.withdrawFrom(user1, weth.address, 1, { from: user1 }), '!withdraw')
      })

      it('approves to increase allowance', async () => {
        const allowanceBefore = await weth.allowance(user1, user2)
        await weth.approve(user2, 1, { from: user1 })
        const allowanceAfter = await weth.allowance(user1, user2)
        allowanceAfter.toString().should.equal(allowanceBefore.add(new BN('1')).toString())
      })

      it('approves to increase allowance with permit', async () => {
        const permitResult = await signERC2612Permit(web3.currentProvider, weth.address, user1, user2, '1')
        await weth.permit(user1, user2, '1', permitResult.deadline, permitResult.v, permitResult.r, permitResult.s)
        const allowanceAfter = await weth.allowance(user1, user2)
        allowanceAfter.toString().should.equal('1')
      })

      describe('with a positive allowance', async () => {
        beforeEach(async () => {
          await weth.approve(user2, 1, { from: user1 })
        })

        it('transfers ether using transferFrom and allowance', async () => {
          const balanceBefore = await weth.balanceOf(user2)
          await weth.transferFrom(user1, user2, 1, { from: user2 })
          const balanceAfter = await weth.balanceOf(user2)
          balanceAfter.toString().should.equal(balanceBefore.add(new BN('1')).toString())
        })

        it('withdraws ether using withdrawFrom and allowance', async () => {
          const fromBalanceBefore = await weth.balanceOf(user1)
          const toBalanceBefore = new BN(await web3.eth.getBalance(user3))

          await weth.withdrawFrom(user1, user3, 1, { from: user2 })

          const fromBalanceAfter = await weth.balanceOf(user1)
          const toBalanceAfter = new BN(await web3.eth.getBalance(user3))

          fromBalanceAfter.toString().should.equal(fromBalanceBefore.sub(new BN('1')).toString())
          toBalanceAfter.toString().should.equal(toBalanceBefore.add(new BN('1')).toString())
        })
      })
    })
  })
})
