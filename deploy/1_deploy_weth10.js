module.exports = async function ({deployments, getNamedAccounts}) {
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();
  await deploy("WETH10", {
    from: deployer,
    deterministicDeployment: true,
    log: true
  });
}
module.exports.tags = ["WETH10"]
