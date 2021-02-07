

// Resolve from a networks.json file.
abstract class ContractResolver {
    abstract resolve(contract: string): string
  }
  
  
  class GanacheArtifactResolver implements ContractResolver {
    path: string
    networkId: number
  
    constructor(networkId, path) {
      this.networkId = networkId
      this.path = path
    }
  
    resolve(contract: string) {
      let address: string
      let artifactPath = `${this.path}/${contract}.json`
      try {
        const artifact = require(artifactPath)
        address = artifact.networks[this.networkId].address
      } catch(ex) {
        throw new Error(`Could not resolve contract ${contract} from Ganache artifact at ${artifactPath}`)
      }
      return address
    }
  }
  
  class DeploymentsJsonResolver {
    deployments: any
    networkId: number
  
    constructor(networkId, path) {
      try {
        this.networkId = networkId
        this.deployments = require(path)
      } catch(ex) {
        throw new Error(`Could not find deployments.json at ${path}`)
      }
    }
  
    resolve(contract) {
      let data: any
      try {
        data = this.deployments[this.networkId][contract]
      } catch(ex) {
        throw new Error(`Could not resolve contract ${contract} from deployments: ${ex.toString()}`)
      }
      return data
    }
  }
  
  interface ContractAddresses {
    [key: string]: string
  }
  
  import { join } from 'path'
  import { ethers } from 'ethers'
  
  export async function resolveContracts(provider: ethers.providers.Provider): Promise<ContractAddresses> {
    let networkId: number
    let network = await provider.getNetwork()
    networkId = network.chainId
    console.log(networkId)
  
    let resolver: ContractResolver
    
    if(networkId == 31337) {
      // This is a development network.
      // Load the addresses from the build artifacts.
      resolver = new GanacheArtifactResolver(networkId, join(__dirname, '../../omen-subgraph/build/contracts/'))
    }
  
    const contracts = [
      'Realitio',
      'RealitioProxy',
      'ConditionalTokens',
      'FPMMDeterministicFactory',
      'WETH9'
    ]
    
    return contracts
      .reduce((addresses: ContractAddresses, contract: string) => {
        addresses[contract] = resolver.resolve(contract)
        return addresses
      }, {})
  }