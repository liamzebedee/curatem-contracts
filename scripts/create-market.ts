// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat")
import { ethers, Wallet } from "ethers"

import * as RealitioQuestionLib from '@realitio/realitio-lib/formatters/question'
import RealitioTemplateLib from '@realitio/realitio-lib/formatters/template'

const CHAIN_ID = {
  'rinkeby': 4
}

// https://github.com/realitio/realitio-contracts/blob/master/truffle/contracts/IRealitio.sol



const {
  ETH_RPC_URL,
  ETH_ACCOUNT_PRIVKEY,
  REALITYIO_ADDRESS,
  REALITYIO_GNOSIS_PROXY_ADDRESS,
  CONDITIONAL_TOKENS_ADDRESS
} = process.env

console.log(  ETH_RPC_URL,
  ETH_ACCOUNT_PRIVKEY,
  REALITYIO_ADDRESS,
  REALITYIO_GNOSIS_PROXY_ADDRESS,
  CONDITIONAL_TOKENS_ADDRESS)

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
  'function createLMSRMarketMaker(address pmSystem, address collateralToken, bytes32[] calldata conditionIds, uint64 fee, address whitelist, uint funding) external returns (address lmsrMarketMaker)'
]

async function createMarket() {
  // 1. Ask question to Reality.eth.
  // 2. Prepare Gnosis conditional token, with oracle set to the Reality.eth proxy.
  // 3. Approve collateral for Gnosis market maker factory.
  // 4. Transfer market funding.
  // 5. Create Gnosis market maker.
}

async function trade() {
  // 1. Get the market.
  // 2. Purchase YES/NO token.
}

async function resolve() {
  // 1. Get market.
  // 2. Compute questionId.
  // 3. 
}

// function getQuestionArgs(
//   question: string,
//   outcomes: Outcome[],
//   category: string,
//   arbitratorAddress: string,
//   openingDateMoment: Moment,
//   networkId: number,
// ) {
//   // const openingTimestamp = openingDateMoment.unix()
//   // const outcomeNames = outcomes.map((outcome: Outcome) => outcome.name)
//   // const questionText = RealitioQuestionLib.encodeText('single-select', question, outcomeNames, category)

//   // const timeoutResolution = getRealitioTimeout(networkId) || REALITIO_TIMEOUT
//   // const timeoutResolution = 180

//   return [SINGLE_SELECT_TEMPLATE_ID, questionText, arbitratorAddress, timeoutResolution, openingTimestamp, 0]
// }


// https://reality.eth.link/app/#!/question/0x5000bf4b74955044fc6673624dc6d1d935490373a6abada38781c8369de67425


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

  // await greeter.deployed();

  // console.log("Greeter deployed to:", greeter.address);

  const provider = new ethers.providers.JsonRpcProvider(ETH_RPC_URL)
  const signer = new Wallet(ETH_ACCOUNT_PRIVKEY, provider)


  const ModeratorArbitrator = await hre.ethers.getContractFactory("ModeratorArbitrator");
  // TODO
  const metadata = {
      tos: "https://twitter.com/liamzebedee",
      template_hashes: []
  }
  const moderatorArbitrator = await ModeratorArbitrator.deploy(REALITYIO_ADDRESS, JSON.stringify(metadata));
  const MODERATOR_MULTISIG_ADDRESS = moderatorArbitrator.address


  const realityio = new ethers.Contract(REALITYIO_ADDRESS, realitioAbi, signer);
  const realitioConstantContract = new ethers.Contract(REALITYIO_ADDRESS, realitioCallAbi, signer)
  
  // uint256 template_id, string question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce
  // https://reality.eth.link/app/docs/html/contracts.html#single-select
  const TEMPLATE_SINGLE_SELECT = 2
  const questionText = `Is this spam? https://www.reddit.com/r/ethereum/comments/hbjx25/the_great_reddit_scaling_bakeoff/`
  const outcomes = ['Spam','Not spam']
  const question = RealitioQuestionLib.encodeText('single-select', questionText, outcomes, 'Spam Classification')
  console.log(question)

  const arbitrator = MODERATOR_MULTISIG_ADDRESS
  // TODO: adjust for network.
  const timeoutResolution = 180
  const openingTimestamp = Math.floor((new Date).getTime() / 1000)
  const nonce = ethers.BigNumber.from(ethers.utils.randomBytes(32));
  
  let args = [
    TEMPLATE_SINGLE_SELECT,
    question,
    arbitrator,
    timeoutResolution,
    openingTimestamp,
    nonce
  ]
  let res = await realityio.askQuestion(...args)
  const questionId = await realitioConstantContract.askQuestion(...args) 
  console.log(`https://rinkeby.etherscan.io/tx/${res.hash}`)
  console.log(`https://reality.eth.link/app/#!/question/${questionId}`)


  
  // We've asked the question, now we create a conditional token for the outcome.

  // const conditionalTokensAddress = conditionalTokens.address
  // const realitioAddress = realitio.address
  // const openingDateMoment = moment(resolution)


  // // Reality.eth.
  // const arbitrator = MODERATOR_MULTISIG_ADDRESS


  // // https://reality.eth.link/app/docs/html/contracts.html#asking-questions
  // //   function askQuestion(
  // //     uint256 template_id,
  // //     string question,
  // //     address arbitrator,
  // //     uint32 timeout,
  // //     uint32 opening_ts,
  // //     uint256 nonce
  // //  )
  // //  returns (bytes32 question_id);


  // const oracleAddress = getContractAddress(networkId, 'oracle')

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
  // LMSRMarketMakerFactory
  const lsmrMarketMakerFactoryAddress = "0x03Ce050DAEB28021086Bf8e9B7843d6212c05F7B"
  const lsmrMarketMakerFactory = new ethers.Contract(lsmrMarketMakerFactoryAddress, marketMakerAbi, signer)


  const collateralTokenAddress = '0xc778417e063141139fce010982780140aa0cd5ab'
  const collateralToken = new ethers.Contract(collateralTokenAddress, wethAbi, signer)
  console.log(`collateralToken.approve()`)
  const ammFunding = 10000
  await collateralToken.deposit({ value: ammFunding }); // mint WETH
  await collateralToken.approve(lsmrMarketMakerFactoryAddress, ethers.constants.MaxUint256, {
    value: '0x0',
  })


  // Create the market.
  res = await lsmrMarketMakerFactory.createLMSRMarketMaker(
    conditionalTokens.address,
    collateralToken.address,
    [conditionId],
    0, // fee
    '0x0000000000000000000000000000000000000000', // whitelist
    ammFunding,
    {
      value: '0x0',
    }
  )

  console.log(`Market created!`)
  console.log(`https://rinkeby.etherscan.io/tx/${res.hash}`)

  // const creationLogEntry = lmsrFactoryTx.logs.find(
  //   ({ event }) => event === "LMSRMarketMakerCreation"
  // );
  
  // if (!creationLogEntry) {
  //   // eslint-disable-next-line
  //   console.error(JSON.stringify(lmsrFactoryTx, null, 2));
  //   throw new Error(
  //     "No LMSRMarketMakerCreation Event fired. Please check the TX above.\nPossible causes for failure:\n- ABIs outdated. Delete the build/ folder\n- Transaction failure\n- Unfunded LMSR"
  //   );
  // }

  // const lmsrAddress = creationLogEntry.args.lmsrMarketMaker;
  // console.log(`LSMR Address: ${lmsrAddress}`)

  
  // transactions.push({
  //   to: collateral.address,
  //   data: ERC20Service.encodeApproveUnlimited(marketMakerFactory.address),
  // })

  // // Step 4: Transfer funding from user
  // // If we are funding with native ether we can skip this step
  // // If we are signed in as a safe we don't need to transfer
  // if (!this.cpk.isSafeApp() && marketData.collateral.address !== pseudoNativeAssetAddress) {
  //   transactions.push({
  //     to: collateral.address,
  //     data: ERC20Service.encodeTransferFrom(account, this.cpk.address, marketData.funding),
  //   })
  // }

  // Step 5: Create market maker

  // const saltNonce = Math.round(Math.random() * 1000000)
  // const predictedMarketMakerAddress = await marketMakerFactory.predictMarketMakerAddress(
  //   saltNonce,
  //   conditionalTokens.address,
  //   collateral.address,
  //   conditionId,
  //   this.cpk.address,
  //   spread,  
  // )
  // logger.log(`Predicted market maker address: ${predictedMarketMakerAddress}`)
  // const distributionHint = calcDistributionHint(marketData.outcomes.map(o => o.probability))
  // transactions.push({
  //   to: marketMakerFactory.address,
  //   data: MarketMakerFactoryService.encodeCreateMarketMaker(
  //     saltNonce,
  //     conditionalTokens.address,
  //     collateral.address,
  //     conditionId,
  //     spread,
  //     marketData.funding,
  //     distributionHint,
  //   ),
  // })

  // const txObject = await this.cpk.execTransactions(transactions, txOptions)

  // const txHash = await this.getTransactionHash(txObject)
  // logger.log(`Transaction hash: ${txHash}`)

  // const transaction = await this.provider.waitForTransaction(txObject.hash)
  //   return {
  //     transaction,
  //     marketMakerAddress: predictedMarketMakerAddress,
  //   }
  // } catch (err) {
  //   logger.error(`There was an error creating the market maker`, err.message)
  //   throw err
  // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
