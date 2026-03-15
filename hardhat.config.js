require("@nomicfoundation/hardhat-toolbox");
require("fhevm-hardhat-plugin");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    hardhat: {
      // Local FHEVM mock for testing
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "https://rpc.ankr.com/eth_sepolia",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111,
    },
  },

  fhevm: {
    // Use Zama's Sepolia gateway
    gatewayUrl: "https://gateway.sepolia.zama.ai",
  },

  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY || "",
    },
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
