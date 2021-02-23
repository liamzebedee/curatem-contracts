


// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat")
import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'
import { BigNumber, Wallet } from "ethers"

import { resolveContracts } from './resolver'


function toWei(amount: string) {
    return ethers.utils.parseUnits(amount, 'ether')
  }

  const { 
      MARKET
  } = process.env

async function main() {
    const provider = new ethers.providers.JsonRpcProvider()
    const signer = provider.getSigner()

    const vendoredContracts = await resolveContracts(provider)
    const address = await signer.getAddress()
    const market = new ethers.Contract(MARKET, require("../abis/PredictionMarket.json"), signer)
    const poolAddress = await market.pool()
    console.log(`Pool: ${poolAddress}`)
    const spamToken = await market.spamToken()
    const notSpamToken = await market.notSpamToken()
    const collateralToken = await market.collateralToken()

    const pool = new ethers.Contract(poolAddress, require("../abis/IBPool.json"), signer)


    const tokenIn = spamToken.address
    const tokenAmountIn = BigNumber.from('10').pow(18)
    const tokenOut = collateralToken.address

    // address tokenOut,
    // uint minAmountOut,
    // uint maxPrice

    // pool.swapExactAmountIn(
    //     WETH,
    //     toWei('2.5'),
    //     DAI,
    //     toWei('475'),
    //     toWei('200'),
    //     { from: user2 },
    // );
    
    

    // simply

    // type Swap {
    //     tokens[]
    //     amountsIn[]
    //     amountsOut[]
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
