

const path = require('path');

module.exports = {
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    develop: {
      gas: 10000000000,
      gasLimit: 8000000,
      host: "localhost",
      port: 9545,
      network_id: "*" // Match any network id
    }
  },
  compilers: {
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      version: "0.6.3",    // Fetch exact version from solc-bin (default: truffle's version)
    },
  },

  
};
