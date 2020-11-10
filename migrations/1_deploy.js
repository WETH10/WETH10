const WETH10 = artifacts.require('WETH10')

module.exports = async function (deployer, network) {
  if (network === 'kovan') {
    await deployer.deploy(WETH10, '0xd0A1E359811322d97991E03f863a0C30C2cF029C')  
  }
}
