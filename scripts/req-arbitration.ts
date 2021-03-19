// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat")
import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { Wallet } from "ethers"

import { resolveContracts } from './resolver'

const {
    QUESTION_ID
} = process.env


async function main() {
  const provider = new ethers.providers.JsonRpcProvider()
  const signer = provider.getSigner()

  const {
    RedditCommunity1: RedditCommunity1
  } = await resolveContracts(provider)
  
  let network = await provider.getNetwork()
  let networkId = network.chainId
  let resolver = new DeploymentsJsonResolver(networkId, '../deployments.json')


  // Get the subreddit community.
  const communityAddress = resolver.resolve('RedditCommunity1').address
  const community = await hre.ethers.getContractAt('CuratemCommunity', communityAddress)

  

  const moderatorArbitrator = await hre.ethers.getContractAt(
    "ModeratorArbitratorV1",
    await community.moderatorArbitrator(),
  )
  
  await moderatorArbitrator.requestArbitration(QUESTION_ID, '0')
  console.log('Arbitration requested successfully!')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });




const {
  ETH_RPC_URL,
  ETH_ACCOUNT_PRIVKEY,
} = process.env






const realitioAbi = [
  'function askQuestion(uint256 template_id, string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) public payable returns (bytes32)',
  'event LogNewQuestion(bytes32 indexed question_id, address indexed user, uint256 template_id, string question, bytes32 indexed content_hash, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 created)',
  'function isFinalized(bytes32 question_id) view public returns (bool)',
  'function resultFor(bytes32 question_id) external view returns (bytes32)',
  'function submitAnswer(bytes32 question_id, bytes32 answer, uint256 max_previous)',
]
const realitioCallAbi = [
  'function askQuestion(uint256 template_id, string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) public view returns (bytes32)',
]

const conditionalTokensAbi = [
  'function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external',
  'function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint)',
]

const erc20Abi = [
  'function allowance(address owner, address spender) external view returns (uint256)',
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function balanceOf(address marketMaker) external view returns (uint256)',
  'function symbol() external view returns (string)',
  'function name() external view returns (string)',
  'function decimals() external view returns (uint8)',
  'function transferFrom(address sender, address recipient, uint256 amount) public returns (bool)',
  'function transfer(address to, uint256 value) public returns (bool)',
]

const wethAbi = [
  ...erc20Abi,
  'function deposit() public payable'
]

const marketMakerAbi = [
  // 'function createLMSRMarketMaker(address pmSystem, address collateralToken, bytes32[] calldata conditionIds, uint64 fee, address whitelist, uint funding) external returns (address lmsrMarketMaker)',
  'function createFixedProductMarketMaker(address conditionalTokens, address collateralToken, bytes32[] calldata conditionIds, uint fee)'
]

const getConditionId = (questionId: string, oracleAddress: string, outcomeSlotCount: number): string => {
  const conditionId = ethers.utils.solidityKeccak256(
    ['address', 'bytes32', 'uint256'],
    [oracleAddress, questionId, outcomeSlotCount],
  )

  return conditionId
}

const doesConditionExist = async (conditionalTokens, conditionId: string): Promise<boolean> => {
  const outcomeSlotCount = await conditionalTokens.getOutcomeSlotCount(conditionId)
  return !outcomeSlotCount.isZero()
}



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
