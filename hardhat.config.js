require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-contract-sizer");

/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.9",
  settings: {
    optimizer: {
      enabled: true,
      runs: 900,
    },
  },
  networks: {
    testnet_moonbeam: {
      url: "https://rpc.ankr.com/moonbeam	",
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 1284,
      gasPrice: 30 * 1000000000,
    },
    testnet_aurora: {
      url: "https://testnet.aurora.dev",
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 1313161555,
      gasPrice: 100 * 1000000000,
    },
    local_aurora: {
      url: "http://localhost:8545",
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 1313161555,
      gasPrice: 120 * 1000000000,
    },
    rinkeby: {
      url: "https://rpc.ankr.com/eth_rinkeby",
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 4,
      gasPrice: 30 * 1000000000,
      blockGasLimit: 100000000429720, // whatever you want here
    },
  },
};
