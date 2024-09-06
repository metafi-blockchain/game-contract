const HDWalletProvider = require("@truffle/hdwallet-provider");

const fs = require("fs");
const privateKeys = fs.readFileSync(".secret").toString().split("\n");

module.exports = {
  networks: {
    bsc_testnet: {
      provider: () =>
        new HDWalletProvider(
          privateKeys,
          `https://data-seed-prebsc-1-s1.binance.org:8545/`,
          0,
          1
        ),
      network_id: 97,
      confirmations: 1,
      gas: 5500000,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    aval_testnet: {
      provider: () =>
        new HDWalletProvider(
          privateKeys,
          `https://api.avax-test.network/ext/bc/C/rpc`,
          0,
          1
        ),
      network_id: "*",
      confirmations: 2,
      gas: 5500000,
      timeoutBlocks: 200,
      skipDryRun: true,
    },

    aval_mainnet: {
      provider: () =>
        new HDWalletProvider(
          privateKeys,
          `https://api.avax.network/ext/bc/C/rpc`,
          0,
          1
        ),
      network_id: 43114,
      confirmations: 2,
      gas: 2000000,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    bscscan: "4F91FHBBB5XICNI9HX5UMTTN19G3N7X4N2",
    snowtrace: "GIZ1V79NH9J1E659CXFWHNNSKYGAFK8Q3W",
  },
  compilers: {
    solc: {
      version: "0.8.20", // Fetch exact version from solc-bin (default: truffle's version)
      docker: false, // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
};
