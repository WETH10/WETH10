const WETH10 = artifacts.require('WETH10')
const WethConverter = artifacts.require('WethConverter')

module.exports = async function (deployer, network) {
  await deployer.deploy(WETH10)
  await deployer.deploy(WethConverter)
}
