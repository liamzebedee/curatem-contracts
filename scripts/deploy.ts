
import * as hre from 'hardhat'
import '@nomiclabs/hardhat-ethers'

const {
  REALITYIO_ADDRESS
} = process.env

import { writeFileSync } from 'fs'
import { join } from 'path'
import { resolveContracts } from './resolver'
import { utils, Contract, ethers } from 'ethers'

const DEPLOYMENTS_PATH = join(__dirname, '../deployments.json')


async function main() {
  let network = await hre.ethers.provider.getNetwork()
  let networkId = network.chainId
  let provider = hre.ethers.provider

  const vendoredContracts = await resolveContracts(provider)
  let deployments = require(DEPLOYMENTS_PATH)
  let contracts: {
    [key: string]: Contract
  } = {}
    
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile 
    // manually to make sure everything is compiled
    // await hre.run('compile');
  
    // Deploy contracts.
    const ModeratorArbitrator = await hre.ethers.getContractFactory("ModeratorArbitrator");
    // TODO
    const metadata = {
        tos: "https://twitter.com/liamzebedee",
        template_hashes: []
    }
    const moderatorArbitrator = await ModeratorArbitrator.deploy(REALITYIO_ADDRESS, JSON.stringify(metadata));
    contracts['ModeratorArbitrator'] = moderatorArbitrator
    const MODERATOR_MULTISIG_ADDRESS = moderatorArbitrator.address
    
    
    // 1a. Import vendor addresses.
    const {
      Realitio,
      RealitioProxy,
      ConditionalTokens,
      FPMMDeterministicFactory,
      WETH9,
      BFactory
    } = vendoredContracts

    console.log(`Vendored addresses:`)
    Object.entries(vendoredContracts).map(([name, address]) => {
      console.log(`${name},${address}`)
    })
    console.log()


    // 1a. Deploy libraries.
    const CTHelpers = await hre.ethers.getContractFactory("CTHelpers");
    const ctHelpers = await CTHelpers.deploy()

    const Scripts = await hre.ethers.getContractFactory("Scripts");
    const scripts = await Scripts.deploy()
    contracts['Scripts'] = scripts
    
    const libraries = {
      "CTHelpers": ctHelpers.address,
    }

    // Deploy the factories.
    const Factory = await hre.ethers.getContractFactory(
      "Factory",
      {
        libraries: {
        },
      }
    );
    const factory = await Factory.deploy()
    await factory.initialize()
    contracts['Factory'] = factory



    // 1. Deploy the Curatem contract.
    const Curatem = await hre.ethers.getContractFactory(
      "Curatem",
      {
        libraries,
      }
    );
    
    const curatem = await Curatem.deploy(
      Realitio,
      RealitioProxy,
      ConditionalTokens,
      FPMMDeterministicFactory
    )
    contracts['Curatem'] = curatem
    

    // 2. Deploy an example community.

    // Deposit some WETH at the user's address.
    const communities = [
      {
        id: 'RedditCommunity1',
        moderator: MODERATOR_MULTISIG_ADDRESS,
        token: WETH9
      }
    ]
    
    const CuratemCommunity = await hre.ethers.getContractFactory(
      "CuratemCommunity",
      {
        libraries,
      }
    )
    for(let community of communities) {
      const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32))
      const txResponse = await curatem.createCommunity(
        salt,
        community.token, 
        community.moderator,
        BFactory,
        factory.address
      )
      const receipt = await txResponse.wait()
      const event = receipt.events.find(log => log.event === 'NewCommunity');
      
      contracts[community.id] = {
        deployTransaction: txResponse,
        address: event.args.community
      } as Contract // TODO: hack
    }
    
    
    
    // ---------------------
    // Save deployments.
    // ---------------------

    if(!deployments[networkId]) 
      deployments[networkId] = {}

    for(let [contract, instance] of Object.entries(contracts)) {
      const { hash, blockHash, blockNumber } = instance.deployTransaction
      deployments[networkId][contract] = {
        address: instance.address,
        hash,
        blockHash,
        blockNumber
      }
    }
    
    if(process.env.DRY_DEPLOY) {
      console.log(`DRY_DEPLOY is enabled. Deployments have not been saved.`)
      return
    }
    writeFileSync(DEPLOYMENTS_PATH, JSON.stringify(deployments, null, 4))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
