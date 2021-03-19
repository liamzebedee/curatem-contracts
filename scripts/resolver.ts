

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
        // TODO: throw more descriptive errors.
        // 1. If artifactpath isn't found.
        // 2. If contract was not deployed for networkId
        const artifact = require(artifactPath)
        address = artifact.networks[this.networkId].address
      } catch(ex) {
        throw new Error(`Could not resolve contract ${contract} from Ganache artifact at ${artifactPath}`)
      }
      return address
    }
  }
  
  export class DeploymentsJsonResolver {
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
        data = this.deployments[this.networkId][contract].address
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
  
  function resolveWithResolver(contracts: string[], resolver: ContractResolver) {
    return contracts
      .reduce((addresses: ContractAddresses, contract: string) => {
        addresses[contract] = resolver.resolve(contract)
        return addresses
      }, {})
  }

  export async function resolveContracts(provider: ethers.providers.Provider): Promise<ContractAddresses> {
    let networkId: number
    let network = await provider.getNetwork()
    networkId = network.chainId
    console.log(`Resolving for network ID ${networkId}`)
  
    let resolvedContracts
    
    const omenContracts = [
      'Realitio',
      'WETH9'
    ]
    const deployments = [
      'UniswapV2Factory',
      'UniswapV2Router02'
    ]

    if(networkId == 31337 || networkId == 42) {
      // This is a development network.
      // Load the addresses from the build artifacts.
      const resolver = new GanacheArtifactResolver(networkId, join(__dirname, '../../omen-subgraph/build/contracts'))
      const resolver2 = new GanacheArtifactResolver(networkId, join(__dirname, '../../balancer-core/build/contracts'))
      const resolver3 = new DeploymentsJsonResolver(networkId, '../deployments.json')
      
      resolvedContracts = {
        ...resolveWithResolver(omenContracts, resolver),
        // ...resolveWithResolver(balancerContracts, resolver2),
        ...resolveWithResolver(deployments, resolver3)
      }
    } else {
      const resolver = new DeploymentsJsonResolver(networkId, '../deployments.json')
      resolvedContracts = {
        ...resolveWithResolver(omenContracts, resolver),
        ...resolveWithResolver(deployments, resolver)
      }
    }
    
    const contractsToSanityCheck = Object.keys(resolvedContracts)
    await Promise.allSettled(
      contractsToSanityCheck.map(async contractName => {
        // Call getCode.
        const addr = resolvedContracts[contractName]
        const code = await provider.getCode(addr)
        if(code == '0x') {
          console.error(`Contract ${contractName} at ${addr} has no deployed code. Did you forget to deploy it?`)
        }
      })
    )
    
    return resolvedContracts
}


