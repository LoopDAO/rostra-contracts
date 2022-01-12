require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-waffle");
const fs = require("fs");
require('dotenv').config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

function mnemonic() {

  return process.env.PRIVATE_KEY

}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.4',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      outputSelection: {
        "*": {
          "": [
            "ast"
          ],
          "*": [
            "evm.bytecode.object",
            "evm.deployedBytecode.object",
            "abi",
            "evm.bytecode.sourceMap",
            "evm.deployedBytecode.sourceMap",
            "metadata"
          ]
        }
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true
    },
    local: {
      url: "http://localhost:7545",
      //gas: 125000000000, // i cannot assign more gas above gas limit of ganache... is it possible to increase this limit.... ?
      //gasPrice: 125000000000
    },
    localhost: {
      url: "http://localhost:8545",
      //gasPrice: 125000000000,//you can adjust gasPrice locally to see how much it will cost on production
      /*
        notice no mnemonic here? it will just use account 0 of the hardhat node to deploy
        (you can put in a mnemonic here to set the deployer locally)
      */
    },
    polygontestnet: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/" + process.env.ALCHEMY_ID_PLOYGON_TESTNET,
      // url: "https://matic-testnet-archive-rpc.bwarelabs.com",
      accounts: [
        mnemonic()
      ]
    },
    polygon: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/" + process.env.ALCHEMY_ID_PLOYGON_MAINNET,
      // url: "https://polygon-mainnet.infura.io/v3/" + process.env.ALCHEMY_ID_PLOYGON_MAINNET,
      // url: "https://polygon-rpc.com/",
      accounts: [
        mnemonic()
      ]
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/" + process.env.INFURA_ID,
      accounts: [
        mnemonic()
      ],
    },
    kovan: {
      url: "https://kovan.infura.io/v3/" + process.env.INFURA_ID,
      accounts: [
        mnemonic()
      ],
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/" + process.env.INFURA_ID,
      accounts: [
        mnemonic()
      ],
    },
    ropsten: {
      url: "https://ropsten.infura.io/v3/" + process.env.INFURA_ID,
      accounts: [
        mnemonic()
      ],
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
      accounts: [
        mnemonic()
      ],
    },
  }
};
