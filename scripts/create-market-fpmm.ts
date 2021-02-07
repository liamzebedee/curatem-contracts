// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

import * as hre from 'hardhat'
import '@nomiclabs/hardhat-ethers'
// import { hre } from 'hardhat'
// import { ethers, Wallet } from "ethers"

import * as RealitioQuestionLib from '@realitio/realitio-lib/formatters/question'
import RealitioTemplateLib from '@realitio/realitio-lib/formatters/template'
import { MarketMakerFactoryService } from "./market_maker_factory"
import * as IPFS from 'ipfs-core'
import * as ipfsClient from 'ipfs-http-client'


const CHAIN_ID = {
  'rinkeby': 4
}

// https://github.com/realitio/realitio-contracts/blob/master/truffle/contracts/IRealitio.sol



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

import { join } from 'path'
import { ethers } from 'ethers'

async function resolveContracts(provider: ethers.providers.Provider): Promise<ContractAddresses> {
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

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // Deploy contracts.
  // const ModeratorArbitrator = await hre.ethers.getContractFactory("ModeratorArbitrator");
  // const moderatorArbitrator = await ModeratorArbitrator.deploy(REALITYIO_ADDRESS);

  // const provider = new ethers.providers.JsonRpcProvider(ETH_RPC_URL)
  
  // const signers = await hre.ethers.getSigners()
  // const provider = await hre.ethers.provider
  // const signer = provider.getSigner()
  // const signer = new Wallet(ETH_ACCOUNT_PRIVKEY, provider)
  
  const provider = new ethers.providers.JsonRpcProvider()
  const signer = provider.getSigner()

  const {
    Realitio: REALITYIO_ADDRESS,
    RealitioProxy: REALITYIO_GNOSIS_PROXY_ADDRESS,
    ConditionalTokens: CONDITIONAL_TOKENS_ADDRESS,
    FPMMDeterministicFactory: FP_MARKET_MAKER_FACTORY_ADDRESS,
    WETH9: COLLATERAL_TOKEN_ADDRESS,
    RedditCommunity1: RedditCommunity1
  } = await resolveContracts(provider)
  
  console.log(  ETH_RPC_URL,
    ETH_ACCOUNT_PRIVKEY,
    REALITYIO_ADDRESS,
    REALITYIO_GNOSIS_PROXY_ADDRESS,
    CONDITIONAL_TOKENS_ADDRESS)


  const ModeratorArbitrator = await hre.ethers.getContractFactory("ModeratorArbitrator");
  // TODO
  const metadata = {
      tos: "https://twitter.com/liamzebedee",
      template_hashes: []
  }
  const moderatorArbitrator = await ModeratorArbitrator.deploy(REALITYIO_ADDRESS, JSON.stringify(metadata));
  const MODERATOR_MULTISIG_ADDRESS = moderatorArbitrator.address


  let network = await provider.getNetwork()
  let networkId = network.chainId
  let resolver = new DeploymentsJsonResolver(networkId, '../deployments.json')
  
  // Create the market metadata JSON.
  const communityId = resolver.resolve('RedditCommunity1').address
  const marketMetadata = {
    url: "https://www.reddit.com/r/ethereum/comments/hbjx25/the_great_reddit_scaling_bakeoff/",
    type: 'post'
  }


  // const ipfs = await IPFS.create({
  //   config: {
  //     Bootstrap: [
  //       '/ip4/tcp/127.0.0.1/5001'
  //     ],
  //     Addresses: null,
  //     Discovery: null
  //   }
  // })
  // TODO: `as any` is a workaround.
  const ipfs = ipfsClient('/ip4/127.0.0.1/tcp/5001' as any)
  const { cid } = await ipfs.add(JSON.stringify(marketMetadata), {
    pin: true,
  })
  console.info(`Market metadata uploaded to IPFS - ipfs:${cid}`)


  // Get the subreddit community.
  

  const curatem = await hre.ethers.getContractAt('Curatem', resolver.resolve('Curatem').address)
  
  await curatem.createMarket(communityId, cid.multihash.slice(2))
  console.info(`Created market on Curatem`)
  return


  const realityio = new ethers.Contract(REALITYIO_ADDRESS, realitioAbi, signer)
  const realitioConstantContract = new ethers.Contract(REALITYIO_ADDRESS, realitioCallAbi, signer)
  
  // uint256 template_id, string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce
  // https://reality.eth.link/app/docs/html/contracts.html#single-select
  const TEMPLATE_SINGLE_SELECT = 2
  const questionText = `Is this spam? ${marketMetadata.url}`
  const outcomes = ['Spam','Not spam']
  const question = RealitioQuestionLib.encodeText('single-select', questionText, outcomes, 'Spam Classification')
  console.log(question)

  const arbitrator = MODERATOR_MULTISIG_ADDRESS
  // TODO: adjust for network.
  const timeoutResolution = 180
  const TRADING_PERIOD = 5 * 60 // 5mins

  const openingTimestamp = TRADING_PERIOD + Math.floor((new Date).getTime() / 1000)
  const nonce = ethers.BigNumber.from(ethers.utils.randomBytes(32));
  
  let args = [
    TEMPLATE_SINGLE_SELECT,
    question,
    arbitrator,
    timeoutResolution,
    openingTimestamp,
    nonce
  ]
  const questionId = await realitioConstantContract.askQuestion(...args) 
  let res = await realityio.askQuestion(...args)
  console.log(`https://rinkeby.etherscan.io/tx/${res.hash}`)
  console.log(`https://reality.eth.link/app/#!/question/${questionId}`)
  // const questionId = '0x0000000000000000000000000000000000000000000000000000000000000000'


  const oracleAddress = REALITYIO_GNOSIS_PROXY_ADDRESS
  const conditionalTokens = new ethers.Contract(CONDITIONAL_TOKENS_ADDRESS, conditionalTokensAbi, signer)
  const outcomeSlotCount = 2

  const conditionId = getConditionId(questionId, oracleAddress, outcomeSlotCount)
  
  // Upsert condition.
  const conditionExists = await doesConditionExist(conditionalTokens, conditionId)

  // Step 2: Prepare condition
  if (!conditionExists) {
    const outcomeSlotCount = 2
    const args = [oracleAddress, questionId, outcomeSlotCount]
    const res = await conditionalTokens.prepareCondition(...args)
  } else {
    console.log(`Condition ${conditionId} already exists`)
    return
  }

  console.log(`ConditionID: ${conditionId}`)

  // Step 3: Approve collateral for factory
  // Rinkeby WETH
  
  // aka FPMMDeterministicFactory
  const marketMakerFactoryAddress = FP_MARKET_MAKER_FACTORY_ADDRESS


  const collateralTokenAddress = COLLATERAL_TOKEN_ADDRESS
  const collateralToken = new ethers.Contract(collateralTokenAddress, wethAbi, signer)
  console.log(`collateralToken.approve()`)
  const ammFunding = 10000
  await collateralToken.deposit({ value: ammFunding }); // mint WETH
  await collateralToken.approve(marketMakerFactoryAddress, ethers.constants.MaxUint256, {
    value: '0x0',
  })

  // Step 5: Create market maker
  const signerAddress = await signer.getAddress()
  let marketMakerFactory = new MarketMakerFactoryService(marketMakerFactoryAddress, provider, signer, signerAddress)

  const saltNonce = Math.round(Math.random() * 1000000)
  const predictedMarketMakerAddress = await marketMakerFactory.predictMarketMakerAddress(
    saltNonce,
    conditionalTokens.address,
    collateralToken.address,
    conditionId,
    signerAddress,
    // spread,
  )
  console.log(`Predicted market maker address: ${predictedMarketMakerAddress}`)
  
  await marketMakerFactory.createMarketMaker(saltNonce, conditionalTokens.address, collateralToken.address, conditionId)
  console.log('Market created!')
  console.log(`https://omen.eth.link/#/${predictedMarketMakerAddress}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
