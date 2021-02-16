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

const vendoredContracts = await resolveContracts(provider)

  const realitio = new ethers.Contract(vendoredContracts.Realitio, require("../abis/IRealitio.json"), signer)
  
  const outcomes = ['Spam','Not spam']
  const finalAnswer = outcomes.indexOf('Spam')
  let etherBondAmount = await realitio.getBond(QUESTION_ID)
  console.log(`Highest submitted answer bond so far is: ${etherBondAmount.toString()}`)
  if(etherBondAmount.toString() == '0') {
      etherBondAmount = '1'
  } else {
      etherBondAmount = etherBondAmount.mul(2).toString()
  }

  console.log(`Submitting answer...`)
  await realitio.submitAnswer(
    QUESTION_ID, 
    ethers.utils.zeroPad(ethers.BigNumber.from(finalAnswer).toHexString(), 32),
    '0',
    { value: ethers.BigNumber.from(etherBondAmount) }
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

