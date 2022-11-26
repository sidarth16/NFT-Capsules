require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

const { ADMIN_PRIVATE_KEY, ALCHEMY_API_KEY, POLYGONSCAN_API_KEY } = process.env;

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
// const ALCHEMY_API_KEY = "Hq62Xzx-iE-sYugUEpk2Auaz3qUHiGz9";

// Replace this private key with your Goerli account private key.
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key.
// Beware: NEVER put real Ether into testing accounts
// const GOERLI_PRIVATE_KEY = "YOUR GOERLI PRIVATE KEY";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  
  networks: {
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [ADMIN_PRIVATE_KEY]
    }
  },

  etherscan: {
    apiKey: POLYGONSCAN_API_KEY,
 }
};
