
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


function toWei(amount: string) {
    return ethers.utils.parseUnits(amount, 'ether')
  }

  const { 
    METAMASK_DEV_ACCOUNT
  } = process.env
async function main() {
const provider = new ethers.providers.JsonRpcProvider()
const signer = provider.getSigner()

const vendoredContracts = await resolveContracts(provider)

if(METAMASK_DEV_ACCOUNT) {
    const signer = provider.getSigner()
    const address = await signer.getAddress()
    const weth9 = new ethers.Contract(vendoredContracts.WETH9, require("../abis/WETH9.json"), signer)
    const amount = toWei('1000')
    await weth9.deposit({
      value: amount
    })
    await weth9.transferFrom(address, METAMASK_DEV_ACCOUNT, amount)

    await signer.sendTransaction({
        value: amount,
        to: METAMASK_DEV_ACCOUNT
    })
    console.log(`Done`)
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });



