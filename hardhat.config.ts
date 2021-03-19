
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-waffle";
import 'hardhat-abi-exporter'
import 'hardhat-contract-sizer'
import '@typechain/hardhat'
import { task, HardhatUserConfig } from "hardhat/config";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

// const GAS_PRICE = 20e9; // 20 GWEI
const config: HardhatUserConfig = {
  solidity: {
    // settings: {
    //   optimizer: {
    //     enabled: true,
    //     runs: 200
    //   }
    // },

    compilers: [
      {
        version: "0.5.5"
      },
      {
        version: "0.6.6"
      },
      {
        version: "0.7.0"
      }
    ],
  },
  
  // Default network is set to development.
  // Development will connect to the forked Hardhat node.
  defaultNetwork: "development",

  networks: {
    hardhat: {
      chainId: 42,
      forking: {
        url: process.env.FORKING_URL,
        enabled: true
      }
    },

    development: {
      url: "http://localhost:8545",
    },
    
    rinkeby: {
      url: process.env.ETH_RPC_URL,
      accounts: [process.env.ETH_ACCOUNT_PRIVKEY]
    }
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  abiExporter: {
    path: './abis',
    clear: true,
    flat: true
  },  
  mocha: {
    timeout: 20000
  }
};

export default config