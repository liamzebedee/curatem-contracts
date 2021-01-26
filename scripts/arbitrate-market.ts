// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat")
import { ethers } from 'hardhat'
import { Wallet } from "ethers"

import * as RealitioQuestionLib from '@realitio/realitio-lib/formatters/question'

const {
  ETH_RPC_URL,
  ETH_ACCOUNT_PRIVKEY,
  REALITYIO_ADDRESS,
  REALITYIO_GNOSIS_PROXY_ADDRESS,
  CONDITIONAL_TOKENS_ADDRESS,
  MODERATOR_ARBITRATOR,
  QUESTION_ID
} = process.env


async function main() {
  const provider = new ethers.providers.JsonRpcProvider(ETH_RPC_URL)
  const signer = new Wallet(ETH_ACCOUNT_PRIVKEY, provider)

  const ModeratorArbitrator = await ethers.getContractFactory("ModeratorArbitrator", signer)
  const moderatorArbitrator = await ModeratorArbitrator.attach(MODERATOR_ARBITRATOR)
  
  // await moderatorArbitrator.requestArbitration(QUESTION_ID)
  const outcomes = ['Spam','Not spam']
  const finalAnswer = outcomes.indexOf('Spam')
  await moderatorArbitrator.submitAnswer(
    QUESTION_ID, 
    ethers.utils.zeroPad(ethers.BigNumber.from(finalAnswer).toHexString(), 32)
  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
