

const path = require('path');

module.exports = {
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    develop: {
        host: "localhost",
        port: 9545,
        network_id: "*" // Match any network id
    }
},
  compilers: {
    solc: {
      version: "0.6.3",    // Fetch exact version from solc-bin (default: truffle's version)
    },
  },
};
