const WETH10 = artifacts.require("WETH10");

module.exports = async function(deployer, network) {
    await deployer.deploy(WETH10);
    weth = await WETH10.deployed()
}
