const fs = require('fs')
const path = require('path')
require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-truffle5')
require('solidity-coverage')
require('hardhat-gas-reporter')
require('hardhat-deploy')


// REQUIRED TO ENSURE METADATA IS SAVED IN DEPLOYMENTS (because solidity-coverage disable it otherwise)
const {
  TASK_COMPILE_GET_COMPILER_INPUT
} = require("hardhat/builtin-tasks/task-names");
task(TASK_COMPILE_GET_COMPILER_INPUT).setAction(async (_, bre, runSuper) => {
  const input = await runSuper();
  input.settings.metadata.useLiteralContent = bre.network.name !== "coverage";
  return input;
})


function nodeUrl(network) {
  let infuraKey
  try {
    infuraKey = fs.readFileSync(path.resolve(__dirname, '.infuraKey')).toString().trim()
  } catch(e) {
    infuraKey = ''
  }
  return `https://${network}.infura.io/v3/${infuraKey}`
}

let mnemonic = process.env.MNEMONIC;
if (!mnemonic) {
  try {
    mnemonic = fs.readFileSync(path.resolve(__dirname, '.secret')).toString().trim()
  } catch(e){}
}
const accounts = mnemonic ? {
  mnemonic,
}: undefined;

let etherscanKey = process.env.ETHERSCANKEY;
if (!etherscanKey) {
  try {
    etherscanKey = fs.readFileSync(path.resolve(__dirname, '.etherscanKey')).toString().trim()
  } catch(e){}
}

module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    kovan: {
      accounts,
      url: nodeUrl('kovan'),
      gasPrice: 100000000000
    },
    goerli: {
      accounts,
      url: nodeUrl('goerli'),
    },
    rinkeby: {
      accounts,
      url: nodeUrl('rinkeby')
    },
    ropsten: {
      accounts,
      url: nodeUrl('ropsten')
    },
    mainnet: {
      accounts,
      url: nodeUrl('mainnet'),
      gasPrice: 80000000000,
      gasLimit: 2500000000,
    },
    coverage: {
      url: 'http://127.0.0.1:8555',
    },
  },
  solidity: {
    version: '0.7.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 20000,
      }
    }
  },
  gasReporter: {
    enabled: true,
  },
  etherscan: {
    apiKey: etherscanKey
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    coverage: './coverage',
    coverageJson: './coverage.json',
    artifacts: './artifacts',
  },
  namedAccounts: {
    deployer: 0
  }
}
