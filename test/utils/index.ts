
import "@nomiclabs/hardhat-waffle";
import '@nomiclabs/hardhat-ethers'
import * as hre from 'hardhat'
import { waffle } from 'hardhat'
import { basename } from 'path'

export function getHardhatArtifact(path: string) {
    const name = basename(path, '.sol')
    const artifact = require(`../../artifacts/${path}/${name}.json`)
    return artifact
  }
  
import { MockContract } from 'ethereum-waffle'

  export async function deployWaffleMock<T = MockContract>(signer, path) {
    const artifact = getHardhatArtifact(path)
    const contract = await waffle.deployMockContract(
      signer, 
      artifact.abi
    )
    return contract
  }
  
  
  export async function deployWaffle<T>(signer, path, args) {
    const artifact = getHardhatArtifact(path)
    const contract = await waffle.deployContract(
      signer, 
      artifact,
      args
    ) as unknown as T
    return contract
  }
  

