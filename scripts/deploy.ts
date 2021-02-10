
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
    

    // 1. Deploy Resolver.
    // const AddressResolver = await hre.ethers.getContractFactory("AddressResolver");
    // const addressResolver = await AddressResolver.deploy()
    // contracts['AddressResolver'] = addressResolver
    
    // // 1a. Import vendor addresses.
    const {
      Realitio,
      RealitioProxy,
      ConditionalTokens,
      FPMMDeterministicFactory,
      WETH9
    } = vendoredContracts

    // const names = [
    //   'Realitio',
    //   'RealitioProxy',
    //   'ConditionalTokens',
    //   'FPMMDeterministicFactory',
    //   'WETH9'
    // ]
    // const destinations = [
    //   Realitio,
    //   RealitioProxy,
    //   ConditionalTokens,
    //   FPMMDeterministicFactory,
    //   WETH9
    // ]
    // await addressResolver.importAddresses(names, destinations)



    // 1. Deploy the Curatem contract.
    const Curatem = await hre.ethers.getContractFactory("Curatem");
    
    const curatem = await Curatem.deploy(
      Realitio,
      RealitioProxy,
      ConditionalTokens,
      FPMMDeterministicFactory
    )
    contracts['Curatem'] = curatem
    
    // 2. Deploy an example community.
    const communities = [
      {
        id: 'RedditCommunity1',
        moderator: MODERATOR_MULTISIG_ADDRESS,
        token: WETH9
      }
    ]
    
    const CuratemCommunity = await hre.ethers.getContractFactory("CuratemCommunity")
    for(let community of communities) {
      const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32))
      const txResponse = await curatem.createCommunity(
        salt,
        community.token, 
        community.moderator
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
      throw new Error(`No deployment configuration defined for network ID ${networkId}.`)

    for(let [contract, instance] of Object.entries(contracts)) {
      const { hash, blockHash, blockNumber } = instance.deployTransaction
      deployments[networkId][contract] = {
        address: instance.address,
        hash,
        blockHash,
        blockNumber
      }
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