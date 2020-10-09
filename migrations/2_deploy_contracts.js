const WETH2 = artifacts.require("WETH2");

module.exports = async function(deployer, network) {
    await deployer.deploy(WETH2);
    weth = await WETH2.deployed()
}
