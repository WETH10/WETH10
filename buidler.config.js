usePlugin("@nomiclabs/buidler-truffle5");
usePlugin("solidity-coverage");
usePlugin("buidler-gas-reporter");

module.exports = {
    defaultNetwork: "buidlerevm",
    networks: {
      buidlerevm: {
      },
      coverage: {
        url: "http://127.0.0.1:8555",
      }
    },
    solc: {
      version: "0.7.0",
      optimizer: {
        enabled: true,
        runs: 200
      }
    },
    gasReporter: {
        enabled: true
    },
    paths: {
      sources: "./contracts",
      tests: "./test",
      cache: "./cache",
      coverage: "./coverage",
      coverageJson: "./coverage.json",
      artifacts: "./artifacts"
    }
  }