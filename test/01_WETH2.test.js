const WETH2 = artifacts.require('WETH2')

require('chai').use(require('chai-as-promised')).should()

contract('TestOracle', (accounts) => {
  const [deployer] = accounts
  let weth

  beforeEach(async () => {
    weth = await WETH2.new({ from: deployer })
  })

  describe('deployment', async () => {
    it('returns the name', async () => {
      let name = await weth.name()
      name.should.equal('Wrapped Ether')
    })
  })
})
