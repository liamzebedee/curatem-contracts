import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import 'hardhat-abi-exporter'


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

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  solidity: {
    compilers: [
      {
        version: "0.5.5"
      },
      {
        version: "0.6.2"
      },
      {
        version: "0.7.0",
        settings: { } 
      }
    ],
    // overrides: {
    //   "contracts/CuratemCommunity.sol": {
    //     version: "0.5.5",
    //     settings: { }
    //   }
    // }
  },
  defaultNetwork: "development",
  networks: {
    hardhat: {
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

